# START HERE

## Code (Kubernetes Infrastructure)

**Overlays - Development**
- `apps/task-manager/overlays/dev/kustomization.yaml` - Namespace dev, 1 replica
- `apps/task-manager/overlays/dev/patch-deployment.yaml` - Dev config

**Overlays - Production**
- `apps/task-manager/overlays/prod/kustomization.yaml` - Namespace prod, 3 replicas
- `apps/task-manager/overlays/prod/patch-deployment.yaml` - Prod config

**Cluster - Single Cluster**
- `clusters/single-cluster/kustomization.yaml` - Root config
- `clusters/single-cluster/namespace-dev.yaml` - NS dev
- `clusters/single-cluster/namespace-prod.yaml` - NS prod
- `clusters/single-cluster/task-manager-dev-application.yaml` - ArgoCD app
- `clusters/single-cluster/task-manager-prod-application.yaml` - ArgoCD app

### 📖 Documentation (7 files)

- `02_QUICKSTART.md` - Quick guide (3 steps)
- `03_ARCHITECTURE_DETAIL.md` - Diagrams and explanation
- `04_VALIDATION.md` - How to validate
- `05_STATUS.md` - Project status
- `IMPLEMENTATION_COMPLETE.md` - This summary

---

## 🎯 Structure Achieved

```
(1 Cluster):
  single-cluster/
    ├── namespace: dev   (1 replica)
    └── namespace: prod  (3 replicas)
```

---

## 🚀 To Deploy (4 Steps)

### ⚠️ Step 0: Install ArgoCD FIRST

**ArgoCD must be installed before creating the Applications.**

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for it to be ready (2-3 minutes)
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd

# See full guide in: 01_ARGOCD_SETUP.md
```

### Step 1: Create Namespaces

```bash
kubectl apply -f clusters/single-cluster/namespace-{dev,prod}.yaml
```

### Step 2: Create Applications

```bash
kubectl apply -k clusters/single-cluster/
```

### Step 3: Verify

```bash
kubectl get applications -n argocd -o wide
```

---

## 📌 Features

✅ **Complete GitOps** - Everything in Git, ArgoCD syncs
✅ **Shared Base** - `base/` unchanged
✅ **Clean Overlays** - Dev and Prod logically separated
✅ **Namespaces** - Isolation in one cluster
✅ **Automatic Update** - Edit Git, ArgoCD syncs
✅ **Documentation** - 7 guide files

---

## 🔄 Update Image (GitOps)

**⚠️ Note:** This is a manual test to verify that ArgoCD sync the app. In production, this process is done by git commits to `your-app-gitops` repo.

### Prerequisites

You probably need the kustomize binary to exec some commands. Install it.

```bash
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=registry/image:v1.2.3
cd -
git add apps/task-manager/overlays/dev/kustomization.yaml
git commit -m "chore: update dev image"
git push
# → ArgoCD syncs automatically ✨
```

---

## ✅ Verification

```bash
# Validate syntax
kubectl kustomize apps/task-manager/overlays/dev > /dev/null && echo "✓"
kubectl kustomize apps/task-manager/overlays/prod > /dev/null && echo "✓"
kubectl kustomize clusters/single-cluster > /dev/null && echo "✓"
```

---

## 📚 Documentation

| File | Read this to... |
|---------|------------------|
| **QUICKSTART.md** | Deploy quickly |
| **ARCHITECTURE_DETAIL.md** | Understand the structure |
| **VALIDATION.md** | Validate changes |
| **README_IMPLEMENTATION.md** | Complete guide |

---

## 🎓 Key Concepts

1. **Base** = Shared files (deployment, service, etc.)
2. **Overlays** = Customizations per environment (dev/prod)
3. **Kustomize** = Combines base + overlay → final manifests
4. **Namespaces** = Logical isolation in ONE cluster
5. **ArgoCD** = Syncs Git → Cluster automatically

---

## ✅ Final Status

| Component | Status |
|-----------|--------|
| **Overlays dev/prod** | ✅ Created |
| **Cluster single** | ✅ Created |
| **Namespaces** | ✅ Defined |
| **ArgoCD Applications** | ✅ Ready |
| **Documentation** | ✅ Complete |
| **Base unchanged** | ✅ Intact |

---

## 🎉 READY TO DEPLOY

**Next step:** Follow `02_QUICKSTART.md`

```bash
# Quick command to deploy everything:
kubectl apply -f clusters/single-cluster/namespace-dev.yaml && \
kubectl apply -f clusters/single-cluster/namespace-prod.yaml && \
kubectl apply -k clusters/single-cluster/ && \
echo "✅ Done! Verify with: kubectl get applications -n argocd"
```
