# Quick Deployment Guide

## ⚠️ Prerequisite: Install ArgoCD

**ArgoCD must be installed before creating the Applications.**

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for it to be ready (2-3 minutes)
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd

# Verify
kubectl get pods -n argocd
```

## 1️⃣ Create Namespaces

```bash
kubectl apply -f clusters/single-cluster/namespace-dev.yaml
kubectl apply -f clusters/single-cluster/namespace-prod.yaml

# Verify
kubectl get namespaces -l app=task-manager
```

## 2️⃣ Create Applications in ArgoCD

The namespaces must exist first.

**⚠️ Note:** If your cluster is not `localhost` (What this means is if your argocd app is in the same cluster of your app or not), update the endpoint in:
- `clusters/single-cluster/task-manager-dev-application.yaml`
- `clusters/single-cluster/task-manager-prod-application.yaml`

Find `destination.server` and replace with your Kubernetes API endpoint.

```bash
# Apply one by one
kubectl apply -f clusters/single-cluster/task-manager-dev-application.yaml
kubectl apply -f clusters/single-cluster/task-manager-prod-application.yaml

# Or use Kustomize for everything together
kubectl apply -k clusters/single-cluster/

# Verify
kubectl get applications -n argocd -o wide
```

## 3️⃣ Update Image

**Development:**
```bash
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=my-registry/task-manager:v1.2.3
cd -
```

**Production:**
```bash
cd apps/task-manager/overlays/prod
kustomize edit set image task-manager=my-registry/task-manager:v1.0.1
cd -
```

**Commit and Push:**
```bash
git add apps/task-manager/overlays/*/kustomization.yaml
git commit -m "chore: update image tags"
git push
```

ArgoCD will sync automatically.

## 4️⃣ (Optional) Manual Deployment One-Time Only

If you want to apply manifests manually (without waiting for ArgoCD to sync):

```bash
# Compile and apply dev
kubectl kustomize apps/task-manager/overlays/dev | kubectl apply -f -

# Compile and apply prod
kubectl kustomize apps/task-manager/overlays/prod | kubectl apply -f -

# Verify they were created
kubectl get pods -n dev -n prod
```

See details: **`MANUAL_DEPLOYMENT.md`**

## 5️⃣ Access ArgoCD Dashboard

### Expose the service (choose one option):

**Option A: Port Forward (recommended for development)**
```bash
# Terminal 1: Expose ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo ""

# Access at: https://localhost:8080
# Username: admin
# Password: (copy from previous command)
```

**Option B: LoadBalancer (for production)**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n argocd  # See external IP
```

## 6️⃣ Monitoring

```bash
# See Application status in ArgoCD
kubectl get applications -n argocd -o wide

# See deployments in dev
kubectl get deployments -n dev -o wide
kubectl get pods -n dev

# See deployments in prod
kubectl get deployments -n prod -o wide
kubectl get pods -n prod

# See logs
kubectl logs -f -l app=task-manager -n dev
kubectl logs -f -l app=task-manager -n prod
```

## 7️⃣ Local Validation (Without Deploying)

```bash
# See manifests that would be generated for dev
kubectl kustomize apps/task-manager/overlays/dev

# See manifests that would be generated for prod
kubectl kustomize apps/task-manager/overlays/prod

# See cluster manifests
kubectl kustomize clusters/single-cluster/
```

## 3️⃣ Update Image

**Development:**
```bash
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=my-registry/task-manager:v1.2.3
cd -
```

**Production:**
```bash
cd apps/task-manager/overlays/prod
kustomize edit set image task-manager=my-registry/task-manager:v1.0.1
cd -
```

**Commit and Push:**
```bash
git add apps/task-manager/overlays/*/kustomization.yaml
git commit -m "chore: update image tags"
git push
```

ArgoCD will sync automatically.

---

**All changes go in Git → ArgoCD syncs them automatically.**
