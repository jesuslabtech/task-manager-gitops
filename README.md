# Task Manager GitOps

A GitOps repository for deploying a Task Manager application on a Kubernetes cluster using Kustomize and ArgoCD.

**You can see the application repo following this link:** https://github.com/jesuslabtech/task-manager-app

## Repository Purpose

This repository contains Kubernetes manifests that define the desired state of the Task Manager application. It follows the GitOps philosophy where the repository serves as the single source of truth for infrastructure and application configuration.

## Repository Structure

```
task-manager-gitops/
├── clusters/                           # Cluster-specific resources
│   └── single-cluster/                 # Single cluster configuration
│       ├── namespace-dev.yaml          # Dev namespace definition
│       ├── namespace-prod.yaml         # Prod namespace definition
│       ├── kustomization.yaml          # Cluster kustomization
│       ├── task-manager-dev-application.yaml    # ArgoCD Application (dev)
│       └── task-manager-prod-application.yaml  # ArgoCD Application (prod)
│
├── apps/                               # Application manifests
│   └── task-manager/                   # Task Manager application
│       ├── base/                       # Base Kustomize configuration
│       │   ├── deployment.yaml         # Deployment manifest
│       │   ├── service.yaml            # Service manifest
│       │   ├── configmap.yaml          # ConfigMap with app settings
│       │   ├── secret.yaml             # Secret with sensitive data
│       │   └── kustomization.yaml      # Base kustomization
│       └── overlays/                   # Environment-specific overlays
│           ├── dev/                    # Development environment
│           │   ├── kustomization.yaml  # Overlay kustomization
│           │   └── patch-deployment.yaml  # Dev patches (1 replica)
│           └── prod/                   # Production environment
│               ├── kustomization.yaml  # Overlay kustomization
│               └── patch-deployment.yaml  # Prod patches (3 replicas)
│
└── README.md                           # This file
```

## Base vs Overlays

### Base (`apps/task-manager/base/`)

The base directory contains the core Kubernetes manifests that define the application:
- **deployment.yaml**: Application deployment with container configuration, health probes, and resource limits
- **service.yaml**: ClusterIP service exposing port 80 to port 3000
- **configmap.yaml**: Application environment variables (APP_NAME, LOG_LEVEL, etc.)
- **secret.yaml**: Sensitive data like JWT_SECRET

The base is environment-agnostic and should not be modified directly for environment-specific changes.

### Overlays (`apps/task-manager/overlays/`)

Overlays provide environment-specific customizations without modifying the base:

- **dev/** - Development environment
  - `kustomization.yaml`: References the base and applies patches
  - `patch-deployment.yaml`: 1 replica, debug logging

- **prod/** - Production environment
  - `kustomization.yaml`: References the base and applies patches
  - `patch-deployment.yaml`: 3 replicas, info logging

This pattern allows the same base to be used across different environments (dev, prod) with minimal duplication.

## Architecture

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
│  Application: task-manager-dev              │
│  ├─ path: overlays/dev                     │
│  ├─ namespace: dev                         │
│  └─ syncPolicy: automated                  │
│                                             │
│  Application: task-manager-prod             │
│  ├─ path: overlays/prod                    │
│  ├─ namespace: prod                        │
│  └─ syncPolicy: automated                  │
└─────────────────────────────────────────────┘
              ↓ (syncs)
┌─────────────────────────────────────────────┐
│                  SINGLE CLUSTER             │
├─────────────────────────────────────────────┤
│  namespace: dev                            │
│  └─ task-manager (1 replica)              │
│                                             │
│  namespace: prod                           │
│  └─ task-manager (3 replicas)             │
└─────────────────────────────────────────────┘
```

## How ArgoCD Uses This Repository

### Deployment Flow

1. **Repository Sync**: ArgoCD monitors this repository for changes
2. **Change Detection**: When commits are pushed to the main branch, ArgoCD detects the changes
3. **Manifest Generation**: Kustomize builds the final manifests from base + overlay
4. **Diff Analysis**: ArgoCD compares the manifests against the cluster state
5. **Sync**: If automated sync is enabled, ArgoCD applies the manifests to the cluster

### ArgoCD Application Resources

The `task-manager-dev-application.yaml` and `task-manager-prod-application.yaml` define how ArgoCD manages the applications:

**task-manager-dev-application.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-manager-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jesuslabtech/task-manager-gitops
    targetRevision: main
    path: apps/task-manager/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**task-manager-prod-application.yaml:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-manager-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jesuslabtech/task-manager-gitops
    targetRevision: main
    path: apps/task-manager/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Key Parameters:**
- **source.repoURL**: Repository URL (change `jesuslabtech` to your GitHub username)
- **source.path**: Points to the overlay for environment-specific deployment
- **destination.namespace**: Deploys to `dev` or `prod` namespace
- **syncPolicy.automated**: Enables automatic syncing with pruning and self-healing

### Workflow

1. Developer commits changes to the repository
2. ArgoCD detects the commit on the main branch
3. ArgoCD generates manifests using Kustomize from the appropriate overlay
4. If differences exist between manifests and cluster state:
   - ArgoCD applies the new manifests
   - Any resources not in the manifests are pruned (if prune: true)
   - If the cluster drifts, selfHeal brings it back in sync

## Getting Started

### Prerequisites

- Kubernetes cluster running
- kubectl configured for your cluster
- ArgoCD installed on the cluster

### Quick Deployment (3 Steps)

**Step 1: Install ArgoCD (if not already installed)**
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argocd
```

**Step 2: Create Namespaces**
```bash
kubectl apply -f clusters/single-cluster/namespace-dev.yaml
kubectl apply -f clusters/single-cluster/namespace-prod.yaml
```

**Step 3: Create Applications**
```bash
kubectl apply -k clusters/single-cluster/
```

### Manual Deployment (without ArgoCD)

Deploy using kubectl and Kustomize:

```bash
# Build and apply dev manifests
kubectl apply -k apps/task-manager/overlays/dev/

# Build and apply prod manifests
kubectl apply -k apps/task-manager/overlays/prod/
```

## Configuration

### Image Configuration

Update the image using Kustomize:

```bash
# For dev
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=your-registry/task-manager:v1.0.0
cd -

# For prod
cd apps/task-manager/overlays/prod
kustomize edit set image task-manager=your-registry/task-manager:v1.0.0
cd -
```

Then commit and push:
```bash
git add apps/task-manager/overlays/*/kustomization.yaml
git commit -m "chore: update image tags"
git push
```

ArgoCD will automatically sync the changes.

### Environment Variables

Modify `apps/task-manager/base/configmap.yaml` to change application settings:

```yaml
data:
  APP_NAME: "task-manager"
  LOG_LEVEL: "debug"
  PORT: "3000"
  HOSTNAME: "0.0.0.0"
```

### Secrets

Update `apps/task-manager/base/secret.yaml` with production secrets (use external secret management in production):

```yaml
stringData:
  JWT_SECRET: "your-actual-secret"
```

### Resource Limits

Modify resource requests/limits in `apps/task-manager/base/deployment.yaml` for your environment.

## Monitoring

```bash
# See Application status in ArgoCD
kubectl get applications -n argocd -o wide

# See deployments in dev
kubectl get deployments -n dev -o wide
kubectl get pods -n dev

# See deployments in prod
kubectl get deployments -n prod -o wide
kubectl get pods -n prod

# See logs
kubectl logs -l app=task-manager -n dev
kubectl logs -l app=task-manager -n prod
```

## Validation

Validate Kustomize manifests:

```bash
# Validate dev overlay
kubectl kustomize apps/task-manager/overlays/dev

# Validate prod overlay
kubectl kustomize apps/task-manager/overlays/prod

# Validate cluster configuration
kubectl kustomize clusters/single-cluster/
```

## Documentation

See the detailed documentation files:

| File | Description |
|------|-------------|
| `00_START_HERE.md` | Quick start guide |
| `01_ARGOCD_SETUP.md` | ArgoCD installation |
| `02_QUICKSTART.md` | Quick deployment steps |
| `03_ARCHITECTURE_DETAIL.md` | Detailed architecture |
| `04_VALIDATION.md` | Validation commands |
| `05_STATUS.md` | Project status |

## Production Considerations

- Replace dummy secrets with production values using a secure secret management tool (e.g., Sealed Secrets, External Secrets Operator)
- Set appropriate resource requests and limits based on application requirements
- Configure proper logging and monitoring
- Use multiple replicas for high availability
- Implement proper ingress configuration for external access
- Use image pull secrets if using private registries
- Consider using networkPolicies for security
