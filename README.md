# Task Manager GitOps

A GitOps repository for deploying a Next.js Task Manager application on a minikube Kubernetes cluster using Kustomize and Argo CD.

## Repository Purpose

This repository contains Kubernetes manifests that define the desired state of the Task Manager application. It follows the GitOps philosophy where the repository serves as the single source of truth for infrastructure and application configuration.

## Repository Structure

```
task-manager-gitops/
├── clusters/                           # Cluster-specific resources
│   └── minikube/                       # Minikube cluster configuration
│       ├── namespace.yaml              # Kubernetes namespace definition
│       ├── kustomization.yaml          # Cluster kustomization
│       └── task-manager-application.yaml  # Argo CD Application resource
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
│           └── minikube/               # Minikube environment
│               ├── kustomization.yaml  # Overlay kustomization
│               └── patch-deployment.yaml  # Deployment patches
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

### Overlays (`apps/task-manager/overlays/minikube/`)

Overlays provide environment-specific customizations without modifying the base:
- **kustomization.yaml**: References the base and applies patches
- **patch-deployment.yaml**: Applies minikube-specific changes (e.g., replica count, labels)

This pattern allows the same base to be used across different environments (dev, staging, prod) with minimal duplication.

## How Argo CD Uses This Repository

### Deployment Flow

1. **Repository Sync**: Argo CD monitors this repository for changes
2. **Change Detection**: When commits are pushed to the main branch, Argo CD detects the changes
3. **Manifest Generation**: Kustomize builds the final manifests from base + overlay
4. **Diff Analysis**: Argo CD compares the manifests against the cluster state
5. **Sync**: If automated sync is enabled, Argo CD applies the manifests to the cluster

### Argo CD Application Resource

The `task-manager-application.yaml` defines how Argo CD manages the application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: task-manager
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jesuslabtech/task-manager-gitops
    targetRevision: main
    path: apps/task-manager/overlays/minikube
  destination:
    server: https://kubernetes.default.svc
    namespace: learning
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Key Parameters:**
- **source.repoURL**: Repository URL (change `jesuslabtech` to your GitHub username)
- **source.path**: Points to the minikube overlay for environment-specific deployment
- **destination.namespace**: Deploys to the `learning` namespace
- **syncPolicy.automated**: Enables automatic syncing with pruning and self-healing

### Workflow

1. Developer commits changes to the repository
2. Argo CD detects the commit on the main branch
3. Argo CD generates manifests using Kustomize from `apps/task-manager/overlays/minikube`
4. If differences exist between manifests and cluster state:
   - Argo CD applies the new manifests
   - Any resources not in the manifests are pruned (if prune: true)
   - If the cluster drifts, selfHeal brings it back in sync

## Getting Started

### Prerequisites

- minikube cluster running
- kubectl configured for minikube
- Argo CD installed on the cluster
- Traefik ingress controller installed

### Manual Deployment (without Argo CD)

Deploy using kubectl and Kustomize:

```bash
# Build and apply manifests
kubectl apply -k clusters/minikube/

# Or just the application
kubectl apply -k apps/task-manager/overlays/minikube/
```

### Deployment with Argo CD

1. Ensure Argo CD is installed and running
2. Apply the Application resource:
   ```bash
   kubectl apply -f clusters/minikube/task-manager-application.yaml
   ```
3. View application status:
   ```bash
   argocd app get task-manager
   ```

## Configuration

### Image Configuration

Update the image in `apps/task-manager/base/deployment.yaml`:

```yaml
image: your-dockerhub-user/task-manager:0.1.0
```

Replace `your-dockerhub-user` with your Docker Hub username.

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

## Production Considerations

- Replace dummy secrets with production values using a secure secret management tool (e.g., Sealed Secrets, External Secrets Operator)
- Set appropriate resource requests and limits based on application requirements
- Configure proper logging and monitoring
- Use multiple replicas for high availability
- Implement proper ingress configuration for external access
- Use image pull secrets if using private registries
- Consider using networkPolicies for security
