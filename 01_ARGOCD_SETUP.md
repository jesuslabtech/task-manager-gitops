# 🔧 ArgoCD Installation

## ⚠️ Prerequisite

**ArgoCD must be installed BEFORE creating the Applications.**

The error you may have received:
```
resource mapping not found for name: "task-manager-dev" namespace: "argocd" 
no matches for kind "Application" in version "argoproj.io/v1alpha1"
```

This means the **CRDs (Custom Resource Definitions)** of ArgoCD are not installed in the cluster.

---

## 🚀 Quick Installation

### Step 1: Create ArgoCD Namespace

```bash
kubectl create namespace argocd
```

### Step 2: Install ArgoCD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 3: Wait for it to be ready

```bash
# Wait for the controller to be available (2-3 minutes)
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd

# Verify pods
kubectl get pods -n argocd

# Expected: see argocd-application-controller, argocd-server pods, etc.
```

### Step 4: Verify Installation

```bash
# See ArgoCD version
kubectl exec -n argocd svc/argocd-server -- argocd version

# See services
kubectl get svc -n argocd

# See installed CRDs (you should see Application, AppProject, etc.)
kubectl get crd | grep argoproj
```

---

## ✅ Complete Verification

```bash
# 1. Namespace exists
kubectl get namespace argocd

# 2. Pods are running
kubectl get pods -n argocd

# 3. CRDs are available
kubectl api-resources | grep argocd

# 4. Services are available
kubectl get svc -n argocd
```

**If all pass, you can continue with the deployment steps.**

---

## 🔐 Access ArgoCD UI (Optional)

### Port Forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then access at: `https://localhost:8080`

### Get Initial Password

```bash
# Username: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 📋 Complete Deployment (After installing ArgoCD)

Once ArgoCD is installed:

```bash
# 1. Create namespaces
kubectl apply -f clusters/single-cluster/namespace-{dev,prod}.yaml

# 2. Create Applications
kubectl apply -k clusters/single-cluster/

# 3. Verify
kubectl get applications -n argocd -o wide
```

---

## ❌ Troubleshooting

### ArgoCD pods not starting

```bash
# See events
kubectl describe pod -n argocd

# See logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### CRDs not appearing

```bash
# Retry installation
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait again
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd
```

### ArgoCD namespace already exists

```bash
# If it already exists, just apply the manifest
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## 🎯 Correct Installation Order

```
1. Install ArgoCD
   ↓
2. Wait for it to be ready
   ↓
3. Create namespaces (dev, prod)
   ↓
4. Create Applications (point to overlays)
   ↓
5. ArgoCD syncs automatically
```

---

## 📝 Automated Installation Script

```bash
#!/bin/bash

echo "🔧 Installing ArgoCD..."

# 1. Create namespace
kubectl create namespace argocd

# 2. Install
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd

# 4. Verify
echo "✅ ArgoCD installed!"
kubectl get pods -n argocd

echo ""
echo "Next step: run QUICKSTART.md"
```

---

**Notes:**
- Stable version: `stable/` (uses latest)
- Specific version: `v2.10.0/` (replace `stable` with the version)
- This manifest includes all necessary CRDs

---

**Once ArgoCD is installed, continue with 02_QUICKSTART.md**
