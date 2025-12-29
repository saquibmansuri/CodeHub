# Trivy – Practical Commands Cheat Sheet

> **Note:** Trivy can generate reports in multiple formats such as **HTML, JSON, SARIF, and table output**.
> Below examples focus on **full scans with HTML report generation**. You can switch `--format` to `json`, `sarif`, etc. as needed.

### If you want to integrate in github actions then checkout this official repository - https://github.com/aquasecurity/trivy-action
---

## Prerequisites

```bash
mkdir -p reports
```

All reports will be generated inside the `./reports` directory.

---

## 1. Scan Docker Image (Full Scan + HTML Report)

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest image \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/image-report.html \
  nginx:latest
```

---

## 2. Scan Local Project Folder (Source Code + Dependencies)

```bash
docker run --rm \
  -v $(pwd):/project \
  -v trivy-cache:/root/.cache \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest fs \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/fs-report.html \
  /project
```

---

## 3. Scan Folder for Vulnerabilities Only (Faster)

```bash
docker run --rm \
  -v $(pwd):/project \
  -v trivy-cache:/root/.cache \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest fs \
  --scanners vuln \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/fs-vuln-report.html \
  /project
```

---

## 4. Scan Dockerfile (Misconfiguration Scan)

```bash
docker run --rm \
  -v $(pwd):/project \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest config \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/dockerfile-report.html \
  /project/Dockerfile
```

---

## 5. Scan Kubernetes Manifests Directory

```bash
docker run --rm \
  -v $(pwd):/project \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest config \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/k8s-manifests-report.html \
  /project/k8s
```

---

## 6. Scan Terraform Directory

```bash
docker run --rm \
  -v $(pwd):/project \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest config \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/terraform-report.html \
  /project/terraform
```

---

## 7. Scan Git Repository (Remote)

```bash
docker run --rm \
  -v trivy-cache:/root/.cache \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest repo \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/repo-report.html \
  https://github.com/nginx/nginx
```

---

## 8. Scan Filesystem for Secrets

```bash
docker run --rm \
  -v $(pwd):/project \
  -v trivy-cache:/root/.cache \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest fs \
  --scanners secret \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/secrets-report.html \
  /project
```

---

## 9. Scan Running Kubernetes Cluster

```bash
docker run --rm \
  -v ~/.kube:/root/.kube \
  -v trivy-cache:/root/.cache \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest k8s cluster \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/k8s-cluster-report.html
```

---

## 10. Scan Specific Kubernetes Namespace

```bash
docker run --rm \
  -v ~/.kube:/root/.kube \
  -v trivy-cache:/root/.cache \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest k8s \
  --namespace default \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/k8s-namespace-report.html
```

---

## 11. Image Scan with Build Fail on HIGH & CRITICAL (CI-style)

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-cache:/root/.cache \
  -v $(pwd)/reports:/reports \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --format template \
  --template "@contrib/html.tpl" \
  --output /reports/ci-image-report.html \
  myapp:latest
```

---

## 12. Generate JSON Report (Alternative Format)

```bash
docker run --rm \
  -v $(pwd):/reports \
  -v trivy-cache:/root/.cache \
  aquasec/trivy:latest fs \
  --format json \
  --output /reports/trivy-report.json \
  .
```

---

## Output Location

All generated reports will be available in:

```bash
./reports/
```

You can download, archive, or upload these files as CI artifacts.
