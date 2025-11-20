# Workload Identity Binding — Quick Gist

**Workload Identity Binding allows a Kubernetes service account to impersonate a Google service account so Pods can securely access GCP services without service account keys.**

---

## Key points (short)

* Creating a GKE cluster **auto-creates one node-level Google service account** (usually `PROJECT_NUMBER-compute@developer.gserviceaccount.com`).
* That node SA can be given permissions (for example, to pull images from GAR). **But** giving node SA broad permissions means **every Pod on that node inherits those permissions** — bad for least-privilege.
* **Workload Identity** is a cluster *feature* you enable. After enabling it you can create **Kubernetes Service Accounts (KSAs)** and map each KSA → **Google Service Account (GSA)** so each workload gets a narrow identity.
* KSAs are created inside the cluster (kubectl / YAML). GSAs are created in GCP (gcloud / Console). The IAM binding (Workload Identity binding) is configured via `gcloud` / IAM API / Terraform.

---

## Typical workflow (commands + example)

### 1) Create a GKE cluster with Workload Identity enabled

```bash
# recommended: enable Workload Identity by setting the workload-pool
gcloud container clusters create CLUSTER_NAME \
  --zone=ZONE \
  --workload-pool=PROJECT_ID.svc.id.goog
```

**Check if workload identity is enabled**

```bash
gcloud container clusters describe CLUSTER_NAME --zone=ZONE --format="value(workloadIdentityConfig.workloadPool)"
# returns: PROJECT_ID.svc.id.goog  (if enabled)
```

### 2) Create a Kubernetes Service Account (KSA)

```bash
kubectl create serviceaccount backend-ksa -n default
# or YAML
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-ksa
  namespace: default
EOF
```

### 3) Create a Google Service Account (GSA)

```bash
gcloud iam service-accounts create backend-gsa \
  --display-name="backend workload gsa"

# get the GSA email
GSA_EMAIL=backend-gsa@PROJECT_ID.iam.gserviceaccount.com
```

### 4) Grant the GSA the required IAM roles (example: Secret Manager accessor)

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:${GSA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor"
```

### 5) Bind the KSA → GSA (Workload Identity binding)

This is an IAM policy binding that allows the KSA principal to impersonate the GSA.

```bash
gcloud iam service-accounts add-iam-policy-binding ${GSA_EMAIL} \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:PROJECT_ID.svc.id.goog[default/backend-ksa]"
```

> Note: IAM accepts the KSA-style principal string even if the KSA does not yet exist in the cluster. IAM does **not** validate KSA existence.

### 6) (Optional but recommended) Annotate the KSA with the GSA email

Annotating the KSA is a common pattern so it’s obvious which GSA the KSA is intended to use. The annotation itself is *not* the IAM grant — the IAM binding above is required.

```bash
kubectl annotate serviceaccount \
  --namespace default backend-ksa \
  iam.gke.io/gcp-service-account=${GSA_EMAIL}
```

### 7) Use the KSA in a Pod spec

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
  namespace: default
spec:
  serviceAccountName: backend-ksa
  containers:
  - name: app
    image: gcr.io/PROJECT_ID/my-backend:latest
```

When the Pod requests credentials, GKE's metadata server issues short-lived tokens that allow the KSA to impersonate the bound GSA.

### 8) Verify (from inside Pod)

Inside the Pod you can test access to GCP (for example, call Metadata or use google-cloud SDK). To verify the identity token provided, one common check is to query the metadata server token endpoint or use client libraries which will show the bound service account email.

## Security & best practices (short)

* **Do not** give node-level SA broad permissions. Use Workload Identity + distinct KSA→GSA mappings for least-privilege.
* Prefer short-lived tokens (Workload Identity) over static JSON keys. No key files to manage or rotate.
* Use separate GSAs per application/component and grant only required roles.
* Annotate KSAs for clarity and documentation.
* Use Terraform / IaC to manage GSAs and IAM bindings for reproducibility.

---

## Quick checklist (copy/paste)

1. Create cluster with `--workload-pool=PROJECT_ID.svc.id.goog`.
2. `kubectl create serviceaccount <ksa> -n <ns>`.
3. `gcloud iam service-accounts create <gsa>`.
4. `gcloud projects add-iam-policy-binding PROJECT_ID --member "serviceAccount:${GSA}" --role roles/...` (grant roles to GSA).
5. `gcloud iam service-accounts add-iam-policy-binding ${GSA} --role roles/iam.workloadIdentityUser --member "serviceAccount:PROJECT_ID.svc.id.goog[<ns>/<ksa>]"`.
6. `kubectl annotate serviceaccount <ksa> iam.gke.io/gcp-service-account=${GSA}`.
7. Use `serviceAccountName: <ksa>` in Pod specs.

---

If you want, I can also:

* produce a one-file Terraform example to create GSA + binding + roles;
* add commands to enable necessary APIs (e.g., IAM, IAM Credentials) if you want those included;
* add a diagram or a full Pod-to-secret access example.
