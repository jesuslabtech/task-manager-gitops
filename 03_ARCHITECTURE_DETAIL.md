# 📐 Final Architecture - Single Cluster

## Complete Flow

```
┌─────────────────────────────────────────────┐
│        Git Repository (GitOps)              │
│   task-manager-gitops (main branch)         │
└─────────────────────────────────────────────┘
              ↓ (push commits)
┌─────────────────────────────────────────────┐
│          ArgoCD (in cluster)                │
│      (argocd namespace)                    │
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
              ↓ (syncs)
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
│  │  ├─ Image: task-manager:latest                     │  │
│  │  ├─ Environment: LOG_LEVEL=debug                  │  │
│  │  └─ Labels: environment=dev                        │  │
│  │                                                     │  │
│  │  Service: task-manager (ClusterIP:80)               │  │
│  │  ConfigMap: task-manager-config                     │  │
│  │  Secret: task-manager-secret                       │  │
│  │                                                     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │           Namespace: prod                           │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │                                                     │  │
│  │  Deployment: task-manager                          │  │
│  │  ├─ Replicas: 3 (prod)                              │  │
│  │  ├─ Image: task-manager:latest                      │  │
│  │  ├─ Environment: LOG_LEVEL=info                   │  │
│  │  └─ Labels: environment=prod                        │  │
│  │                                                     │  │
│  │  Service: task-manager (ClusterIP:80)              │  │
│  │  ConfigMap: task-manager-config                     │  │
│  │  Secret: task-manager-secret                        │  │
│  │                                                     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Detailed Directory Structure

```
task-manager-gitops/
│
├── apps/
│   └── task-manager/
│       │
│       ├── base/  (SHARED - unchanged)
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
│           └── minikube/  (REFERENCE - keep)
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
    └── minikube/  (REFERENCE - keep)
```

## Kustomize Build Flow

### Development
```
kubectl kustomize apps/task-manager/overlays/dev

1. Read overlays/dev/kustomization.yaml
2. Apply bases (../../base) → deployment, service, configmap, secret
3. Apply namespace: dev → adds to all resources
4. Apply patchesStrategicMerge (patch-deployment.yaml) → replicas: 1
5. Apply images (task-manager:latest)
6. Apply commonLabels (environment: dev)

RESULT:
- Deployment: task-manager with 1 replica in namespace dev
- Service: task-manager in namespace dev
- ConfigMap/Secret: in namespace dev
- Labels: environment=dev
```

### Production
```
kubectl kustomize apps/task-manager/overlays/prod

1. Read overlays/prod/kustomization.yaml
2. Apply bases (../../base) → deployment, service, configmap, secret
3. Apply namespace: prod → adds to all resources
4. Apply patchesStrategicMerge (patch-deployment.yaml) → replicas: 3
5. Apply images (task-manager:latest)
6. Apply commonLabels (environment: prod)

RESULT:
- Deployment: task-manager with 3 replicas in namespace prod
- Service: task-manager in namespace prod
- ConfigMap/Secret: in namespace prod
- Labels: environment=prod
```

## Change Lifecycle

```
1. Developer makes change
   └─ Edit overlays/dev/kustomization.yaml
   └─ Change: newTag: v1.2.3

2. Git push
   └─ Commit: "chore: update dev image to v1.2.3"
   └─ Push to main branch

3. ArgoCD detects
   └─ Polling (every 3 min) or webhook
   └─ Sees new commit

4. ArgoCD compiles
   └─ Executes: kubectl kustomize apps/task-manager/overlays/dev
   └─ Generates YAML manifests

5. ArgoCD syncs
   └─ Compares vs current cluster
   └─ Detects: image changed from latest to v1.2.3
   └─ Executes: kubectl set image deployment/task-manager ...

6. Kubernetes updates
   └─ Rolling update: terminates old Pod, creates new one
   └─ Keeps service available
   └─ Health check: readinessProbe

7. Convergence
   └─ All Pods with new image
   └─ ArgoCD marks as "Synced" ✓
```

## Key Commands

```bash
# Deployment
kubectl apply -f clusters/single-cluster/namespace-{dev,prod}.yaml
kubectl apply -k clusters/single-cluster/

# Verification
kubectl get namespaces -l app=task-manager
kubectl get applications -n argocd -o wide
kubectl get deployments -n dev -n prod

# Update (GitOps)
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=registry/image:v1.2.3

# Sync
git add apps/task-manager/overlays/dev/kustomization.yaml
git commit -m "chore: update dev image"
git push  # → ArgoCD detects and syncs automatically

# Monitoring
kubectl logs -f -l app=task-manager -n dev
kubectl rollout status deployment/task-manager -n prod
```

---
