# 📊 Adaptation Completed: Single Cluster with Namespaces

## ✅ Change Summary

Your GitOps repository has been successfully adapted to use **a single Kubernetes cluster** with **two namespaces** (dev and prod) instead of two separate clusters.

### Files Created

```
✅ apps/task-manager/overlays/dev/
   ├── kustomization.yaml       (namespace: dev, 1 replica)
   └── patch-deployment.yaml

✅ apps/task-manager/overlays/prod/
   ├── kustomization.yaml       (namespace: prod, 3 replicas)
   └── patch-deployment.yaml

✅ clusters/single-cluster/
   ├── kustomization.yaml       (root kustomization)
   ├── namespace-dev.yaml       (namespace: dev)
   ├── namespace-prod.yaml      (namespace: prod)
   ├── task-manager-dev-application.yaml  (ArgoCD app)
   └── task-manager-prod-application.yaml (ArgoCD app)
```

## 🎯 Final Structure

```
single-cluster (ONE SINGLE CLUSTER)
├── namespace: dev
│   └── task-manager (1 replica, latest image)
│
└── namespace: prod
    └── task-manager (3 replicas, versioned)
```

## 🔄 GitOps Flow

```
Git commit/push
        ↓
ArgoCD detects change
        ↓
kubectl kustomize overlays/dev → dev manifests
kubectl kustomize overlays/prod → prod manifests
        ↓
Syncs in its corresponding namespace
        ↓
Kubernetes applies changes (rollout, scaling, etc.)
```

## 🚀 Next Steps

### ⚠️ STEP 0: Install ArgoCD (if not already installed)

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for it to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd
```

### 1. Create Namespaces
```bash
kubectl apply -f clusters/single-cluster/namespace-{dev,prod}.yaml
```

### 2. Create Applications in ArgoCD
```bash
kubectl apply -k clusters/single-cluster/
```

### 3. Verify
```bash
kubectl get applications -n argocd -o wide
kubectl get pods -n dev
kubectl get pods -n prod
```

## 📝 Changes in Git

To update an image (ArgoCD syncs automatically):

```bash
# Dev
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=registry/image:v1.2.3

# Prod
cd apps/task-manager/overlays/prod
kustomize edit set image task-manager=registry/image:v1.0.1

# Commit
git add apps/task-manager/overlays/*/kustomization.yaml
git commit -m "chore: update images"
git push
```

## 📚 Documentation

- **02_QUICKSTART.md** - Quick deployment guide
- Original files (`clusters/minikube/`, `overlays/minikube/`) are kept for reference

## ✨ Benefits

✅ **Single cluster** - Less infrastructure complexity
✅ **Cost reduction** - ~50% less resources
✅ **Logical isolation** - Namespaces for dev/prod
✅ **Complete GitOps** - Everything versioned in Git
✅ **Automatic ArgoCD** - Automatic synchronization
✅ **Scalable** - Easy to add more environments

---