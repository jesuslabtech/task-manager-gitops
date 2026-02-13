# GitOps Single Cluster - Task Manager

## 📁 Estructura Final

```
task-manager-gitops/
├── apps/
│   └── task-manager/
│       ├── base/                 # Base compartida (sin cambios)
│       │   ├── configmap.yaml
│       │   ├── deployment.yaml
│       │   ├── kustomization.yaml
│       │   ├── secret.yaml
│       │   └── service.yaml
│       │
│       └── overlays/
│           ├── dev/              # ✅ NUEVO: Environment dev
│           │   ├── kustomization.yaml
│           │   └── patch-deployment.yaml
│           │
│           ├── prod/             # ✅ NUEVO: Environment prod
│           │   ├── kustomization.yaml
│           │   └── patch-deployment.yaml
│           │
│           └── minikube/         # (Mantener por ahora para referencia)
│
└── clusters/
    └── single-cluster/           # ✅ NUEVO: Reemplaza minikube/
        ├── kustomization.yaml
        ├── namespace-dev.yaml
        ├── namespace-prod.yaml
        ├── task-manager-dev-application.yaml
        └── task-manager-prod-application.yaml
```

## 🎯 Cambios Realizados

### 1. **Overlays Actualizados**
- ✅ `overlays/dev/` - Environment de desarrollo (1 replica)
- ✅ `overlays/prod/` - Environment de producción (3 replicas)
- Cada uno con su propio `kustomization.yaml` y namespace específico

### 2. **Cluster Reorganizado**
- ✅ `clusters/single-cluster/` - Reemplaza `clusters/minikube/`
- ✅ Dos namespaces: `dev` y `prod`
- ✅ Dos Applications de ArgoCD: una por environment

### 3. **Configuración ArgoCD**
- ✅ `task-manager-dev-application.yaml` - Apunta a `overlays/dev`
- ✅ `task-manager-prod-application.yaml` - Apunta a `overlays/prod`
- Sincronización automática habilitada (`prune: true`, `selfHeal: true`)

## 📋 Despliegue

### Crear Namespaces
```bash
kubectl apply -f clusters/single-cluster/namespace-dev.yaml
kubectl apply -f clusters/single-cluster/namespace-prod.yaml
```

### Crear Applications en ArgoCD
```bash
# Una por una
kubectl apply -f clusters/single-cluster/task-manager-dev-application.yaml
kubectl apply -f clusters/single-cluster/task-manager-prod-application.yaml

# O todo junto con Kustomize
kubectl apply -k clusters/single-cluster/
```

## 🔄 Actualizar Imagen

### Development
```bash
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=<registry>/task-manager:v1.2.3
```

### Production
```bash
cd apps/task-manager/overlays/prod
kustomize edit set image task-manager=<registry>/task-manager:v1.0.1
```

Luego:
```bash
git add apps/task-manager/overlays/*/kustomization.yaml
git commit -m "chore: update image tags"
git push
```

ArgoCD sincronizará automáticamente.

## ✅ Verificación

```bash
# Ver Applications
kubectl get applications -n argocd -o wide

# Ver namespaces
kubectl get namespaces -l app=task-manager

# Ver deployments
kubectl get deployments -n dev
kubectl get deployments -n prod

# Ver manifiestos generados
kubectl kustomize apps/task-manager/overlays/dev
kubectl kustomize apps/task-manager/overlays/prod
```

## 📌 Notas Importantes

- **Base sin cambios**: El directorio `apps/task-manager/base/` permanece intacto
- **Namespaces automáticos**: Los overlays definen su namespace (dev/prod)
- **ArgoCD gestiona todo**: No es necesario `kubectl apply` manual
- **Versionado en Git**: Todos los cambios se hacen en Git, ArgoCD los sincroniza

## 🔗 Flujo GitOps

```
Git commit → ArgoCD detecta cambios → 
kustomize build → Sincroniza con cluster →
Actualiza deployment en namespace correspondiente
```

## 📝 Próximos Pasos Opcionales

1. Eliminar `clusters/minikube/` si ya no es necesario
2. Eliminar `apps/task-manager/overlays/minikube/` si ya no es necesario
3. Agregar validación de Kustomize en CI/CD

---
**Cambio realizado:** 13 de febrero de 2026  
**Rama:** chore/update-repo-structure
