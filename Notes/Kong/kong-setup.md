# Kong Setup on GKE

This guide explains both ways to set up Kong on a GKE cluster:
1. **Kong Ingress Controller (Kubernetes-native)**
2. **Kong Konnect (Cloud Control Plane + Data Plane in your cluster)**

---

# 1️⃣ Setup Kong Ingress Controller on GKE

## Prerequisites
- GKE Cluster
- kubectl configured
- Helm installed

---

## Step 1: Add the Kong Helm Repository
```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

---

## Step 2: Install Kong Ingress Controller
```bash
helm install kong kong/kong   --namespace kong --create-namespace   --set ingressController.installCRDs=false
```

This deploys:
- Kong proxy (LoadBalancer)  
- Kong ingress controller  
- Required CRDs  

---

## Step 3: Get Kong LoadBalancer IP
```bash
kubectl get svc -n kong
```

Use the external IP to test routes.

---

## Step 4: Deploy an Example App
```yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-service
spec:
  selector:
    app: demo
  ports:
    - port: 80
      targetPort: 5000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
      - name: demo
        image: hashicorp/http-echo
        args:
          - "-text=Hello from demo"
```

Apply:
```bash
kubectl apply -f demo.yaml
```

---

## Step 5: Create Kong Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  annotations:
    konghq.com/plugins: rate-limit
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-service
            port:
              number: 80
```

Apply:
```bash
kubectl apply -f demo-ingress.yaml
```

Your app is now exposed through Kong.

---

# 2️⃣ Setup Kong Konnect + Connect Your GKE Cluster

## What is Konnect?
Konnect is Kong’s hosted **Control Plane**, while your GKE cluster runs the **Data Plane**.

You manage:
- Services  
- Routes  
- Plugins  
- API lifecycle  

…through the Konnect dashboard.

Your GKE cluster receives & enforces the config.

---

# Step 1: Create a Gateway Group in Konnect
1. Visit **https://cloud.konghq.com/**
2. Go to **Gateway Manager**
3. Click **Create Gateway Group**
4. Give it a name (ex: `gke-production`)

---

# Step 2: Add a Data Plane (your GKE cluster)
Inside the group → click **Add Data Plane Node**

Konnect gives you an installation command like:

```bash
curl -Ls https://install.konghq.com/konnect |   KONG_KONNECT_TOKEN=<your-konnect-token> bash -
```

Or Helm version:
```bash
helm repo add kong https://charts.konghq.com
helm upgrade --install kong-dp kong/kong   --set secretToken=<your-konnect-token>   --namespace kong --create-namespace
```

This installs:
- Kong data plane  
- Konnect agent  
- CRDs  

---

# Step 3: Verify Data Plane Connection
In Konnect UI → the Data Plane will show **Connected**.

---

# Step 4: Define Your API (Declarative Config YAML)
Konnect uses YAML to know:
- what API to expose  
- which Kubernetes service to route to  
- what plugins to apply  

Example:
```yaml
_format_version: "3.0"
services:
  - name: demo
    url: http://demo-service.default.svc.cluster.local:80
    routes:
      - name: demo-route
        paths:
          - /
plugins:
  - name: rate-limiting
    config:
      minute: 10
```

Upload this in **API > Declarative Config**.

---

# Step 5: Publish API
Click **Publish**.

Konnect will push config to your GKE data plane.

---

# Step 6: Test the API
Use the data plane LoadBalancer IP:
```bash
curl http://<kong_public_ip>/
```

---

# ✔️ Summary

| Feature | Kong Ingress Controller | Konnect |
|--------|---------------------------|---------|
| Installation | Helm in cluster | Cloud + agent in cluster |
| Management | YAML in Kubernetes | Konnect UI + YAML |
| Best for | K8s ingress | Multi-cluster, enterprise API mgmt |

---

If you want a Terraform or Helm version of the entire setup, I can generate it too.
