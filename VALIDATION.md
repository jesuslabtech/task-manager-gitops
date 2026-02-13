# ✅ Validación y Verificación

## 1. Validar Sintaxis Kustomize

```bash
# Dev
kubectl kustomize apps/task-manager/overlays/dev > /tmp/dev.yaml && echo "✓ Dev válido"

# Prod
kubectl kustomize apps/task-manager/overlays/prod > /tmp/prod.yaml && echo "✓ Prod válido"

# Cluster
kubectl kustomize clusters/single-cluster > /tmp/cluster.yaml && echo "✓ Cluster válido"
```

## 2. Validar Manifiestos contra Kubernetes

```bash
# Dev (dry-run)
kubectl kustomize apps/task-manager/overlays/dev | kubectl apply --dry-run=client -f -

# Prod (dry-run)
kubectl kustomize apps/task-manager/overlays/prod | kubectl apply --dry-run=client -f -

# Cluster (dry-run)
kubectl kustomize clusters/single-cluster | kubectl apply --dry-run=client -f -
```

## 3. Verificar Estructura de Archivos

```bash
# Verificar que existen todos los overlays
ls -la apps/task-manager/overlays/{dev,prod}/

# Verificar que existen todos los archivos de cluster
ls -la clusters/single-cluster/

# Verificar contenido de kustomization.yaml
cat apps/task-manager/overlays/dev/kustomization.yaml
cat apps/task-manager/overlays/prod/kustomization.yaml
cat clusters/single-cluster/kustomization.yaml
```

## 4. Comparar Manifiestos Dev vs Prod

```bash
# Ver diferencias
diff -u \
  <(kubectl kustomize apps/task-manager/overlays/dev) \
  <(kubectl kustomize apps/task-manager/overlays/prod) | head -50
```

Diferencias esperadas:
- `namespace`: dev vs prod
- `replicas`: 1 vs 3
- Labels: `environment: dev` vs `environment: prod`

## 5. Validar References en Applications

```bash
# Ver Applications antes de crear
cat clusters/single-cluster/task-manager-dev-application.yaml
cat clusters/single-cluster/task-manager-prod-application.yaml

# Verificar que paths existen
ls -d apps/task-manager/overlays/{dev,prod}
```

## 6. Validación Post-Despliegue (en Cluster)

Una vez desplegado:

```bash
# 1. Verificar Namespaces
kubectl get namespaces -l app=task-manager

# 2. Verificar Applications
kubectl get applications -n argocd
kubectl describe application task-manager-dev -n argocd
kubectl describe application task-manager-prod -n argocd

# 3. Verificar Deployments
kubectl get deployments -A | grep task-manager
kubectl get deployments -n dev
kubectl get deployments -n prod

# 4. Verificar Pods
kubectl get pods -n dev
kubectl get pods -n prod

# 5. Verificar Servicios
kubectl get svc -n dev
kubectl get svc -n prod

# 6. Verificar ConfigMaps y Secrets
kubectl get configmap,secret -n dev
kubectl get configmap,secret -n prod

# 7. Ver Eventos
kubectl get events -n dev --sort-by='.lastTimestamp'
kubectl get events -n prod --sort-by='.lastTimestamp'

# 8. Ver Logs
kubectl logs -l app=task-manager -n dev --all-containers=true
kubectl logs -l app=task-manager -n prod --all-containers=true
```

## 7. Test de Actualización de Imagen

```bash
# 1. Cambiar imagen en dev
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=task-manager:test-v1
cd -

# 2. Verificar cambio en kustomization.yaml
grep "newTag" apps/task-manager/overlays/dev/kustomization.yaml

# 3. Compilar y verificar
kubectl kustomize apps/task-manager/overlays/dev | grep -A 2 "image:"

# 4. Revertir cambio
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=task-manager:latest
cd -
```

## 8. Verificar ArgoCD Sync

```bash
# Verificar que Applications están sincronizadas
kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.sync.status}{"\n"}{end}'

# Si no está sincronizado, forzar sync
argocd app sync task-manager-dev --prune
argocd app sync task-manager-prod --prune

# O via kubectl
kubectl patch application task-manager-dev -n argocd \
  --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/compare-result":"forced"}}}'
```

## 9. Validación de Labels

```bash
# Verificar que los pods tienen los labels correctos
kubectl get pods -n dev -L environment
kubectl get pods -n prod -L environment

# Salida esperada:
# Dev:  environment=dev
# Prod: environment=prod
```

## 10. Checklist de Validación

- [ ] `apps/task-manager/overlays/dev/kustomization.yaml` existe
- [ ] `apps/task-manager/overlays/prod/kustomization.yaml` existe
- [ ] `clusters/single-cluster/` directorio existe
- [ ] `clusters/single-cluster/namespace-dev.yaml` existe
- [ ] `clusters/single-cluster/namespace-prod.yaml` existe
- [ ] `clusters/single-cluster/task-manager-dev-application.yaml` existe
- [ ] `clusters/single-cluster/task-manager-prod-application.yaml` existe
- [ ] `clusters/single-cluster/kustomization.yaml` existe
- [ ] `kubectl kustomize apps/task-manager/overlays/dev` funciona
- [ ] `kubectl kustomize apps/task-manager/overlays/prod` funciona
- [ ] `kubectl kustomize clusters/single-cluster` funciona
- [ ] Dev tiene `replicas: 1`
- [ ] Prod tiene `replicas: 3`
- [ ] Dev tiene `namespace: dev`
- [ ] Prod tiene `namespace: prod`
- [ ] Applications apuntan a los overlays correctos
- [ ] Namespaces se crean antes que Applications

## Comandos Rápidos

```bash
# Todo en uno (validación completa)
for env in dev prod; do
  echo "=== Validando $env ==="
  kubectl kustomize apps/task-manager/overlays/$env > /dev/null && echo "✓ Kustomize OK" || echo "✗ Error en Kustomize"
done

echo "=== Validando cluster ==="
kubectl kustomize clusters/single-cluster > /dev/null && echo "✓ Cluster Kustomize OK" || echo "✗ Error en Cluster"

echo "=== Estructura de archivos ==="
ls -la apps/task-manager/overlays/{dev,prod,minikube}/ 2>/dev/null | wc -l
ls -la clusters/single-cluster/ | wc -l
```

---

**Nota:** Ejecuta estas validaciones después de desplegar para asegurar que todo está funcionando correctamente.
