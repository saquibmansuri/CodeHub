# GKE Multi-Cluster Internal Gateway API POC

> **Note**: The architecture diagram for this POC is attached in the ZIP folder accompanying this document.

---

## 1. Objective

This document describes the end-to-end setup of a **cross-regional internal Application Load Balancer** using **GKE Gateway API (multi-cluster)** on **GKE Autopilot clusters**, backed by **Multi-Cluster Services (MCS)**.

The POC demonstrates:

* Two GKE Autopilot clusters in different regions
* A shared internal L7 load balancer
* Traffic routing based on hostname
* Load balancing across clusters
* Private DNS-based access from within the VPC

---

## 2. High-Level Architecture

* **Clusters**:

  * `poc-cluster-1` – us-central1 (Config Cluster)
  * `poc-cluster-2` – us-east1

* **Gateway Type**:

  * Cross-regional internal Application Load Balancer
  * GatewayClass: `gke-l7-cross-regional-internal-managed-mc`

* **Service Exposure**:

  * Kubernetes ServiceExport / ServiceImport (Multi-Cluster Services)

* **DNS**:

  * Cloud DNS Private Zone
  * Single hostname resolving to multiple regional VIPs

---

## 3. Services and APIs Enabled

The following Google Cloud services must be enabled:

```bash
gcloud services enable \
  trafficdirector.googleapis.com \
  multiclusteringress.googleapis.com \
  multiclusterservicediscovery.googleapis.com
```

---

## 4. Fleet and Multi-Cluster Configuration

### 4.1 Register Clusters to Fleet

Both clusters must be registered to the same fleet.

```bash
gcloud container fleet memberships list
```

### 4.2 Enable Multi-Cluster Ingress

```bash
gcloud container fleet ingress enable \
  --config-membership=projects/PROJECT_ID/locations/us-central1/memberships/poc-cluster-1
```

### 4.3 IAM Permissions for Multi-Cluster Ingress

```bash
PROJECT_NUMBER=$(gcloud projects describe PROJECT_ID --format='value(projectNumber)')

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-multiclusteringress.iam.gserviceaccount.com" \
  --role="roles/container.admin"
```

---

## 5. Networking Prerequisites

### 5.1 VPC

* Both clusters use the **same VPC network**.

### 5.2 Proxy-Only Subnets (Critical Requirement)

For **cross-regional internal Gateway**, a **GLOBAL_MANAGED_PROXY** subnet must exist **in every region specified in the Gateway manifest**.

Example:

```bash
# us-central1
gcloud compute networks subnets create proxy-only-global-us-central1 \
  --network=default \
  --region=us-central1 \
  --range=172.16.10.0/23 \
  --purpose=GLOBAL_MANAGED_PROXY \
  --role=ACTIVE

# us-east1
gcloud compute networks subnets create proxy-only-global-us-east1 \
  --network=default \
  --region=us-east1 \
  --range=172.16.12.0/23 \
  --purpose=GLOBAL_MANAGED_PROXY \
  --role=ACTIVE
```

---

## 6. Firewall Rules

Allow traffic from proxy-only subnets and internal ranges to backend services.

```bash
gcloud compute firewall-rules create allow-mc-gateway-proxy \
  --network=default \
  --direction=INGRESS \
  --priority=1000 \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=172.16.10.0/23,172.16.12.0/23

# Broad internal access for POC
gcloud compute firewall-rules create allow-internal-all \
  --network=default \
  --direction=INGRESS \
  --priority=900 \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=10.0.0.0/8
```

---

## 7. Kubernetes Workloads

### 7.1 US-CENTRAL Cluster Workload

Apply **only in us-central1 cluster**:

```bash
kubectl apply -f central-nginx.yml
```

File: `central-nginx.yml`

(As provided in the final manifest section)

---

### 7.2 US-EAST Cluster Workload

Apply **only in us-east1 cluster**:

```bash
kubectl apply -f east-nginx.yml
```

File: `east-nginx.yml`

---

## 8. Multi-Cluster Service Export

Export the service from **both clusters**.

```bash
kubectl apply -f service-export.yml
```

This creates a `ServiceImport` automatically in the config cluster.

---

## 9. Gateway and Routing (Config Cluster)

The **us-central1 cluster** acts as the **config cluster**.

### 9.1 Gateway

```bash
kubectl apply -f gateway-mc.yml
```

Key points:

* Uses `gke-l7-cross-regional-internal-managed-mc`
* Explicitly lists all regions
* Requires proxy-only subnets in each region

---

### 9.2 HTTPRoute

```bash
kubectl apply -f httproute-mc.yml
```

Key points:

* Hostname-based routing
* Backend uses `ServiceImport`
* Route is attached to the multi-cluster Gateway

---

## 10. Private Cloud DNS

### 10.1 Private Zone

* Zone: `gcp.saquib.com`
* Type: Private
* Attached to the same VPC as the clusters and VM

### 10.2 A Record

Example:

```
nginx.gcp.saquib.com
  A → 10.128.0.13
  A → 10.142.15.196
```

Multiple A records are expected and required for cross-regional internal load balancing.

---

## 11. Validation

### 11.1 Gateway Health

```bash
kubectl describe gateway multi-cluster-internal-gw
```

Expected:

* `Programmed=True`
* `GatewayHealthy=True`

### 11.2 Route Status

```bash
kubectl describe httproute nginx-mc-route
```

Expected:

* `Accepted=True`
* `ResolvedRefs=True`

### 11.3 End-to-End Test

From a VM in the same VPC:

```bash
curl http://nginx.gcp.saquib.com
```

Repeated requests should return responses from both clusters.

---

## 12. Key Learnings

* Cross-regional internal Gateway requires **GLOBAL_MANAGED_PROXY** subnets in every region.
* Multi-cluster Gateway API works with **Autopilot** when fleet ingress and MCS are enabled.
* Internal ALB exposes **multiple regional VIPs**, not a single global IP.
* Hostname matching in `HTTPRoute` is mandatory for routing.
* ServiceExport / ServiceImport abstracts backend services across clusters.

---

## 13. Summary

This POC successfully demonstrates a production-grade, cross-regional, internal load balancing architecture using GKE Gateway API and Multi-Cluster Services, fully managed by Google Cloud and suitable for enterprise internal platforms.
