# 📊 Adaptación Completada: Single Cluster con Namespaces

## ✅ Resumen de Cambios

Tu repositorio GitOps ha sido adaptado exitosamente para usar **un solo cluster Kubernetes** con **dos namespaces** (dev y prod) en lugar de dos clusters separados.

### Archivos Creados

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

## 🎯 Estructura Final

```
single-cluster (UN SOLO CLUSTER)
├── namespace: dev
│   └── task-manager (1 replica, latest image)
│
└── namespace: prod
    └── task-manager (3 replicas, versionada)
```

## 🔄 Flujo GitOps

```
Git commit/push
       ↓
ArgoCD detecta cambio
       ↓
kubectl kustomize overlays/dev → manifiestos dev
kubectl kustomize overlays/prod → manifiestos prod
       ↓
Sincroniza en su namespace correspondiente
       ↓
Kubernetes aplica cambios (rollout, scaling, etc.)
```

## 🚀 Próximos Pasos

### ⚠️ PASO 0: Instalar ArgoCD (si no está ya instalado)

```bash
# Crear namespace
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que esté listo
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd
```

### 1. Crear Namespaces
```bash
kubectl apply -f clusters/single-cluster/namespace-{dev,prod}.yaml
```

### 2. Crear Applications en ArgoCD
```bash
kubectl apply -k clusters/single-cluster/
```

### 3. Verificar
```bash
kubectl get applications -n argocd -o wide
kubectl get pods -n dev
kubectl get pods -n prod
```

## 📝 Cambios en Git

Para actualizar una imagen (ArgoCD lo sincroniza automáticamente):

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

## 📚 Documentación

- **MIGRATION_SUMMARY.md** - Resumen completo de cambios
- **QUICKSTART.md** - Guía rápida de despliegue
- Archivos originales (`clusters/minikube/`, `overlays/minikube/`) se mantienen para referencia

## ✨ Beneficios

✅ **Un solo cluster** - Menos complejidad de infraestructura
✅ **Reducción de costos** - ~50% menos de recursos
✅ **Aislamiento lógico** - Namespaces para dev/prod
✅ **GitOps completo** - Todo versionado en Git
✅ **ArgoCD automático** - Sincronización automática
✅ **Escalable** - Fácil agregar más entornos

---

**Estado:** ✅ Listo para desplegar
**Rama:** `chore/update-repo-structure`
**Cambio realizado:** 13 de febrero de 2026
