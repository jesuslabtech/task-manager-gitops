# 📋 Quick Guide - Manual Deployment and ArgoCD Dashboard

## 🎯 Current Situation

You have ArgoCD installed but Pods are not yet visible in the namespaces.
There are two reasons:
1. ArgoCD may take a while to sync automatically
2. You want to access the ArgoCD dashboard

---

## ✅ Solution: Manual Deployment + Dashboard

### Option 1️⃣: Automated Script (Recommended)

#### A. Manual Deployment

```bash
# Make executable
chmod +x deploy-manual.sh

# Execute
./deploy-manual.sh
```

**What it does:**
- Compiles manifests with Kustomize
- Applies dev and prod manually
- Verifies they were created
- Waits for Pods to be ready
- Shows instructions to access ArgoCD

#### B. Expose ArgoCD Dashboard

**Terminal 1: Open port-forward**
```bash
chmod +x argocd-expose.sh
./argocd-expose.sh port-forward
```

**Terminal 2: Get credentials**
```bash
./argocd-expose.sh credentials
```

**Then access at:**
```
https://localhost:8080
Username: admin
Password: (from previous command)
```

---

### Option 2️⃣: Manual Commands

#### Manual Deployment (without script)

```bash
# 1. Compile dev
kubectl kustomize apps/task-manager/overlays/dev | kubectl apply -f -

# 2. Compile prod
kubectl kustomize apps/task-manager/overlays/prod | kubectl apply -f -

# 3. Verify
kubectl get pods -n dev -n prod

# 4. Wait for them to be ready
kubectl rollout status deployment/task-manager -n dev
kubectl rollout status deployment/task-manager -n prod
```

#### Expose ArgoCD (without script)

**Terminal 1: Port Forward**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Terminal 2: Credentials**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo ""
```

**Access at:** `https://localhost:8080`

---

## 📊 Verification

### Verify everything is correct

```bash
# See Deployments
kubectl get deployments -n dev -n prod -o wide

# See Pods
kubectl get pods -n dev -n prod -o wide

# See Services
kubectl get svc -n dev -n prod -o wide

# See ArgoCD Applications
kubectl get applications -n argocd -o wide
```

---

## 🔄 In ArgoCD Dashboard

Once you access `https://localhost:8080`:

1. **You will see:**
   - Application: `task-manager-dev` 
   - Application: `task-manager-prod`

2. **Expected status:**
   - Name: Green
   - Status: Can be "Syncing" or "Synced"
   - Health: "Progressing" or "Healthy"

3. **If "OutOfSync":**
   - Click on the Application
   - Click on "Sync" button
   - Wait for it to finish

---

## 📁 Files Created

| File | Description |
|---------|-------------|
| `MANUAL_DEPLOYMENT.md` | Complete manual deployment guide |
| `deploy-manual.sh` | Automated deployment script |
| `argocd-expose.sh` | Script to expose ArgoCD |
| `QUICKSTART.md` | Updated with new options |

---

## 🎯 Recommended Flow

```
1. Execute: ./deploy-manual.sh
   ↓
2. Wait for it to finish
   ↓
3. In Terminal 1: ./argocd-expose.sh port-forward
   ↓
4. In Terminal 2: ./argocd-expose.sh credentials
   ↓
5. Access at: https://localhost:8080
   ↓
6. See Applications in green (Synced)
```

---

## ✅ Checklist

- [ ] Executed `./deploy-manual.sh`
- [ ] Saw Pods in `kubectl get pods -n dev -n prod`
- [ ] Executed `./argocd-expose.sh port-forward`
- [ ] Executed `./argocd-expose.sh credentials`
- [ ] Accessed `https://localhost:8080`
- [ ] Saw the 2 Applications (dev and prod)
- [ ] Saw they are "Synced" (green)

---

## 🚀 Next Step

After verifying everything works manually:

1. ArgoCD now keeps all changes synchronized
2. To update image, you only need to edit Git
3. ArgoCD will detect changes and sync automatically

---

**Note:** Manual deployment is only for verification.  
In production, ArgoCD handles everything automatically from Git.
