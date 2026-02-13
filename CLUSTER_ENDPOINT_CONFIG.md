# 🔧 Configurar Endpoint del Cluster

## ⚠️ Importante

Las Applications de ArgoCD necesitan saber a qué cluster apuntar. 

**Endpoint del Cluster:** 
```
https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443
```

---

## 🔍 ¿Cómo Obtener tu Endpoint?

### En Linode LKE

1. Accede a tu panel de Linode
2. Kubernetes > tu cluster
3. Copia el endpoint bajo "Kubernetes API Endpoint"

Ejemplo:
```
https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443
```

### En otros proveedores

**AWS EKS:**
```bash
aws eks describe-cluster --name <cluster-name> --query 'cluster.endpoint'
```

**Google GKE:**
```bash
kubectl cluster-info | grep 'Kubernetes master'
```

**Azure AKS:**
```bash
az aks show --resource-group <rg> --name <cluster> --query 'fqdn'
```

**Minikube (local):**
```bash
minikube ip
# O usar: https://kubernetes.default.svc (si ArgoCD está en el mismo cluster)
```

---

## ✏️ Actualizar el Endpoint

### Opción 1: Editar manualmente

**Archivo:** `clusters/single-cluster/task-manager-dev-application.yaml`

Busca:
```yaml
destination:
  server: https://kubernetes.default.svc
```

Reemplaza con:
```yaml
destination:
  server: https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443
```

Haz lo mismo en `task-manager-prod-application.yaml`.

### Opción 2: Script automatizado

```bash
#!/bin/bash

ENDPOINT="https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443"

# Actualizar dev
sed -i "s|server: https://kubernetes.default.svc|server: $ENDPOINT|g" \
  clusters/single-cluster/task-manager-dev-application.yaml

# Actualizar prod
sed -i "s|server: https://kubernetes.default.svc|server: $ENDPOINT|g" \
  clusters/single-cluster/task-manager-prod-application.yaml

echo "✅ Endpoints actualizados"
```

### Opción 3: Con kubectl patch

```bash
ENDPOINT="https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443"

# Dev
kubectl patch application task-manager-dev -n argocd \
  --type merge \
  -p "{\"spec\":{\"destination\":{\"server\":\"$ENDPOINT\"}}}"

# Prod
kubectl patch application task-manager-prod -n argocd \
  --type merge \
  -p "{\"spec\":{\"destination\":{\"server\":\"$ENDPOINT\"}}}"
```

---

## ✅ Verificar que Está Correcto

```bash
# Ver los endpoints configurados
kubectl get application -n argocd -o jsonpath='{.items[*].spec.destination.server}'

# Esperado: Tu endpoint de Linode LKE

# Ver estado de las Applications
kubectl get applications -n argocd -o wide

# Busca: HealthStatus, SyncStatus
```

---

## 🎯 Flujo Completo

```
1. Obtener endpoint: https://d9365f90-...
2. Actualizar task-manager-dev-application.yaml
3. Actualizar task-manager-prod-application.yaml
4. Aplicar cambios: kubectl apply -k clusters/single-cluster/
5. Verificar: kubectl get applications -n argocd
6. Esperar a que sincronicen (verde)
```

---

## 📋 Ejemplo Completo

Tu endpoint es: `https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443`

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
    server: https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443
    namespace: dev

  syncPolicy:
    syncOptions:
      - CreateNamespace=false
    automated:
      prune: true
      selfHeal: true
```

---

## 🔐 Nota Importante

**El endpoint debe ser accesible desde donde ArgoCD está ejecutándose.**

Si ArgoCD está en el mismo cluster (lo cual es tu caso), debería funcionar con:
- `https://kubernetes.default.svc` (cuando está en el mismo cluster)
- O el endpoint externo (si está en otro cluster)

Para tu caso (ArgoCD en Linode LKE), ambos deberían funcionar:
- `https://kubernetes.default.svc` ✅
- `https://d9365f90-...` ✅ (endpoint externo)

---

## ✨ Ya Actualizado

✅ He actualizado automáticamente:
- `clusters/single-cluster/task-manager-dev-application.yaml`
- `clusters/single-cluster/task-manager-prod-application.yaml`

Con tu endpoint de Linode LKE. 

Ahora puedes aplicar:
```bash
kubectl apply -k clusters/single-cluster/
```

---

**Si en el futuro cambias de cluster, solo actualiza el endpoint.**
