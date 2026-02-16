# ✅ Validation and Verification

## 1. Validate Kustomize Syntax

```bash
# Dev
kubectl kustomize apps/task-manager/overlays/dev > /tmp/dev.yaml && echo "✓ Dev valid"

# Prod
kubectl kustomize apps/task-manager/overlays/prod > /tmp/prod.yaml && echo "✓ Prod valid"

# Cluster
kubectl kustomize clusters/single-cluster > /tmp/cluster.yaml && echo "✓ Cluster valid"
```

## 2. Validate Manifests against Kubernetes

```bash
# Dev (dry-run)
kubectl kustomize apps/task-manager/overlays/dev | kubectl apply --dry-run=client -f -

# Prod (dry-run)
kubectl kustomize apps/task-manager/overlays/prod | kubectl apply --dry-run=client -f -

# Cluster (dry-run)
kubectl kustomize clusters/single-cluster | kubectl apply --dry-run=client -f -
```

## 3. Verify File Structure

```bash
# Verify all overlays exist
ls -la apps/task-manager/overlays/{dev,prod}/

# Verify all cluster files exist
ls -la clusters/single-cluster/

# Verify kustomization.yaml content
cat apps/task-manager/overlays/dev/kustomization.yaml
cat apps/task-manager/overlays/prod/kustomization.yaml
cat clusters/single-cluster/kustomization.yaml
```

## 4. Compare Dev vs Prod Manifests

```bash
# See differences
diff -u \
  <(kubectl kustomize apps/task-manager/overlays/dev) \
  <(kubectl kustomize apps/task-manager/overlays/prod) | head -50
```

Expected differences:
- `namespace`: dev vs prod
- `replicas`: 1 vs 3
- Labels: `environment: dev` vs `environment: prod`

## 5. Validate Application References

```bash
# See Applications before creating
cat clusters/single-cluster/task-manager-dev-application.yaml
cat clusters/single-cluster/task-manager-prod-application.yaml

# Verify paths exist
ls -d apps/task-manager/overlays/{dev,prod}
```

## 6. Post-Deployment Validation (on Cluster)

Once deployed:

```bash
# 1. Verify Namespaces
kubectl get namespaces -l app=task-manager

# 2. Verify Applications
kubectl get applications -n argocd
kubectl describe application task-manager-dev -n argocd
kubectl describe application task-manager-prod -n argocd

# 3. Verify Deployments
kubectl get deployments -A | grep task-manager
kubectl get deployments -n dev
kubectl get deployments -n prod

# 4. Verify Pods
kubectl get pods -n dev
kubectl get pods -n prod

# 5. Verify Services
kubectl get svc -n dev
kubectl get svc -n prod

# 6. Verify ConfigMaps and Secrets
kubectl get configmap,secret -n dev
kubectl get configmap,secret -n prod

# 7. Verify Events
kubectl get events -n dev --sort-by='.lastTimestamp'
kubectl get events -n prod --sort-by='.lastTimestamp'

# 8. See Logs
kubectl logs -l app=task-manager -n dev --all-containers=true
kubectl logs -l app=task-manager -n prod --all-containers=true
```

## 7. Image Update Test

```bash
# 1. Change image in dev
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=task-manager:test-v1
cd -

# 2. Verify change in kustomization.yaml
grep "newTag" apps/task-manager/overlays/dev/kustomization.yaml

# 3. Build and verify
kubectl kustomize apps/task-manager/overlays/dev | grep -A 2 "image:"

# 4. Revert change
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=task-manager:latest
cd -
```

## 8. Verify ArgoCD Sync

```bash
# Verify Applications are synchronized
kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.sync.status}{"\n"}{end}'

# If not synced, force sync
argocd app sync task-manager-dev --prune
argocd app sync task-manager-prod --prune

# Or via kubectl
kubectl patch application task-manager-dev -n argocd \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/compare-result":"forced"}}}'
```

## 9. Label Validation

```bash
# Verify pods have correct labels
kubectl get pods -n dev -L environment
kubectl get pods -n prod -L environment

# Expected output:
# Dev:  environment=dev
# Prod: environment=prod
```

## 10. Validation Checklist

- [ ] `apps/task-manager/overlays/dev/kustomization.yaml` exists
- [ ] `apps/task-manager/overlays/prod/kustomization.yaml` exists
- [ ] `clusters/single-cluster/` directory exists
- [ ] `clusters/single-cluster/namespace-dev.yaml` exists
- [ ] `clusters/single-cluster/namespace-prod.yaml` exists
- [ ] `clusters/single-cluster/task-manager-dev-application.yaml` exists
- [ ] `clusters/single-cluster/task-manager-prod-application.yaml` exists
- [ ] `clusters/single-cluster/kustomization.yaml` exists
- [ ] `kubectl kustomize apps/task-manager/overlays/dev` works
- [ ] `kubectl kustomize apps/task-manager/overlays/prod` works
- [ ] `kubectl kustomize clusters/single-cluster` works
- [ ] Dev has `replicas: 1`
- [ ] Prod has `replicas: 3`
- [ ] Dev has `namespace: dev`
- [ ] Prod has `namespace: prod`
- [ ] Applications point to correct overlays
- [ ] Namespaces are created before Applications

## Quick Commands

```bash
# All in one (complete validation)
for env in dev prod; do
  echo "=== Validating $env ==="
  kubectl kustomize apps/task-manager/overlays/$env > /dev/null && echo "✓ Kustomize OK" || echo "✗ Kustomize Error"
done

echo "=== Validating cluster ==="
kubectl kustomize clusters/single-cluster > /dev/null && echo "✓ Cluster Kustomize OK" || echo "✗ Cluster Error"

echo "=== File structure ==="
ls -la apps/task-manager/overlays/{dev,prod,minikube}/ 2>/dev/null | wc -l
ls -la clusters/single-cluster/ | wc -l
```

---

**Note:** Run these validations after deploying to ensure everything is working correctly.
