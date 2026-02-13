# 📐 Arquitectura Final - Single Cluster

## Flujo Completo

```
┌─────────────────────────────────────────────┐
│        Git Repository (GitOps)              │
│   task-manager-gitops (rama main)           │
└─────────────────────────────────────────────┘
              ↓ (push commits)
┌─────────────────────────────────────────────┐
│          ArgoCD (en cluster)                │
│      (argocd namespace)                     │
├─────────────────────────────────────────────┤
│                                             │
│  Application: task-manager-dev              │
│  ├─ path: overlays/dev                     │
│  ├─ namespace: dev                         │
│  └─ syncPolicy: automated                  │
│                                             │
│  Application: task-manager-prod             │
│  ├─ path: overlays/prod                    │
│  ├─ namespace: prod                        │
│  └─ syncPolicy: automated                  │
│                                             │
└─────────────────────────────────────────────┘
              ↓ (sincroniza)
┌─────────────────────────────────────────────────────────────┐
│                  SINGLE CLUSTER                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │           Namespace: dev                            │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │                                                     │  │
│  │  Deployment: task-manager                           │  │
│  │  ├─ Replicas: 1 (dev)                              │  │
│  │  ├─ Image: task-manager:latest                      │  │
│  │  ├─ Environment: LOG_LEVEL=debug                    │  │
│  │  └─ Labels: environment=dev                         │  │
│  │                                                     │  │
│  │  Service: task-manager (ClusterIP:80)               │  │
│  │  ConfigMap: task-manager-config                     │  │
│  │  Secret: task-manager-secret                        │  │
│  │                                                     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │           Namespace: prod                           │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │                                                     │  │
│  │  Deployment: task-manager                           │  │
│  │  ├─ Replicas: 3 (prod)                              │  │
│  │  ├─ Image: task-manager:latest                      │  │
│  │  ├─ Environment: LOG_LEVEL=info                     │  │
│  │  └─ Labels: environment=prod                        │  │
│  │                                                     │  │
│  │  Service: task-manager (ClusterIP:80)               │  │
│  │  ConfigMap: task-manager-config                     │  │
│  │  Secret: task-manager-secret                        │  │
│  │                                                     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Estructura de Directorios Detallada

```
task-manager-gitops/
│
├── apps/
│   └── task-manager/
│       │
│       ├── base/  (COMPARTIDA - sin cambios)
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   ├── secret.yaml
│       │   └── kustomization.yaml
│       │       └── resources: [deployment, service, configmap, secret]
│       │
│       └── overlays/
│           │
│           ├── dev/
│           │   ├── kustomization.yaml
│           │   │   ├── namespace: dev
│           │   │   ├── bases: [../../base]
│           │   │   ├── patchesStrategicMerge: [patch-deployment.yaml]
│           │   │   ├── images: [task-manager:latest]
│           │   │   └── commonLabels: [environment: dev]
│           │   │
│           │   └── patch-deployment.yaml
│           │       └── replicas: 1
│           │
│           ├── prod/
│           │   ├── kustomization.yaml
│           │   │   ├── namespace: prod
│           │   │   ├── bases: [../../base]
│           │   │   ├── patchesStrategicMerge: [patch-deployment.yaml]
│           │   │   ├── images: [task-manager:latest]
│           │   │   └── commonLabels: [environment: prod]
│           │   │
│           │   └── patch-deployment.yaml
│           │       └── replicas: 3
│           │
│           └── minikube/  (REFERENCIA - mantener)
│
└── clusters/
    ├── single-cluster/
    │   ├── kustomization.yaml
    │   │   ├── resources:
    │   │   │   ├── namespace-dev.yaml
    │   │   │   ├── namespace-prod.yaml
    │   │   │   ├── task-manager-dev-application.yaml
    │   │   │   └── task-manager-prod-application.yaml
    │   │   └── commonLabels:
    │   │       ├── cluster: single-cluster
    │   │       └── managed-by: argocd
    │   │
    │   ├── namespace-dev.yaml
    │   │   └── apiVersion: v1
    │   │       kind: Namespace
    │   │       metadata:
    │   │         name: dev
    │   │
    │   ├── namespace-prod.yaml
    │   │   └── apiVersion: v1
    │   │       kind: Namespace
    │   │       metadata:
    │   │         name: prod
    │   │
    │   ├── task-manager-dev-application.yaml
    │   │   └── apiVersion: argoproj.io/v1alpha1
    │   │       kind: Application
    │   │       spec:
    │   │         source:
    │   │           path: apps/task-manager/overlays/dev
    │   │         destination:
    │   │           namespace: dev
    │   │
    │   └── task-manager-prod-application.yaml
    │       └── apiVersion: argoproj.io/v1alpha1
    │           kind: Application
    │           spec:
    │             source:
    │               path: apps/task-manager/overlays/prod
    │             destination:
    │               namespace: prod
    │
    └── minikube/  (REFERENCIA - mantener)
```

## Flujo de Compilación Kustomize

### Development
```
kubectl kustomize apps/task-manager/overlays/dev

1. Lee overlays/dev/kustomization.yaml
2. Aplica bases (../../base) → deployment, service, configmap, secret
3. Aplica namespace: dev → añade a todos los recursos
4. Aplica patchesStrategicMerge (patch-deployment.yaml) → replicas: 1
5. Aplica images (task-manager:latest)
6. Aplica commonLabels (environment: dev)

RESULTADO:
- Deployment: task-manager con 1 replica en namespace dev
- Service: task-manager en namespace dev
- ConfigMap/Secret: en namespace dev
- Etiquetas: environment=dev
```

### Production
```
kubectl kustomize apps/task-manager/overlays/prod

1. Lee overlays/prod/kustomization.yaml
2. Aplica bases (../../base) → deployment, service, configmap, secret
3. Aplica namespace: prod → añade a todos los recursos
4. Aplica patchesStrategicMerge (patch-deployment.yaml) → replicas: 3
5. Aplica images (task-manager:latest)
6. Aplica commonLabels (environment: prod)

RESULTADO:
- Deployment: task-manager con 3 replicas en namespace prod
- Service: task-manager en namespace prod
- ConfigMap/Secret: en namespace prod
- Etiquetas: environment=prod
```

## Ciclo de Vida de un Cambio

```
1. Developer hace cambio
   └─ Edita overlays/dev/kustomization.yaml
   └─ Cambia: newTag: v1.2.3

2. Git push
   └─ Commit: "chore: update dev image to v1.2.3"
   └─ Push a rama main

3. ArgoCD detecta
   └─ Polling (cada 3 min) o webhook
   └─ Ve nuevo commit

4. ArgoCD compila
   └─ Ejecuta: kubectl kustomize apps/task-manager/overlays/dev
   └─ Genera manifiestos YAML

5. ArgoCD sincroniza
   └─ Compara vs cluster actual
   └─ Detecta: imagen cambió de latest a v1.2.3
   └─ Ejecuta: kubectl set image deployment/task-manager ...

6. Kubernetes actualiza
   └─ Rolling update: termina Pod viejo, crea uno nuevo
   └─ Mantiene servicio disponible
   └─ Health check: readinessProbe

7. Convergencia
   └─ Todos los Pods con nueva imagen
   └─ ArgoCD marca como "Synced" ✓
```

## Comparación: Antes vs Después

### ANTES (Multi-Cluster)
```
Infrastructure:
  - cluster-dev  (AWS)
  - cluster-prod (AWS)
  
Cost:
  - $400 × 2 = $800/mes

Management:
  - 2 clusters
  - 2 ArgoCD instances
  
Git:
  - gitops-dev repo
  - gitops-prod repo
  
Deployment:
  Dev  → cluster-dev
  Prod → cluster-prod
```

### DESPUÉS (Single Cluster)
```
Infrastructure:
  - cluster-single (AWS)
  
Cost:
  - $400 × 1 = $400/mes (50% reduction)

Management:
  - 1 cluster
  - 1 ArgoCD instance
  
Git:
  - task-manager-gitops repo
  
Deployment:
  Dev  ─┐
       └─ cluster-single (namespace: dev)
  Prod ─┘
       └─ cluster-single (namespace: prod)
```

## Comandos Clave

```bash
# Despliegue
kubectl apply -f clusters/single-cluster/namespace-{dev,prod}.yaml
kubectl apply -k clusters/single-cluster/

# Verificación
kubectl get namespaces -l app=task-manager
kubectl get applications -n argocd -o wide
kubectl get deployments -n dev -n prod

# Actualización (GitOps)
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=registry/image:v1.2.3

# Sincronización
git add apps/task-manager/overlays/dev/kustomization.yaml
git commit -m "chore: update dev image"
git push  # → ArgoCD detecta y sincroniza automáticamente

# Monitoreo
kubectl logs -f -l app=task-manager -n dev
kubectl rollout status deployment/task-manager -n prod
```

---

**Estado:** ✅ Completado
**Cluster:** 1 (single)
**Namespaces:** 2 (dev, prod)
**Applications (ArgoCD):** 2 (task-manager-dev, task-manager-prod)
