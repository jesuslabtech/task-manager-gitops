# Guía Rápida de Despliegue

## ⚠️ Prerequisito: Instalar ArgoCD

**ArgoCD debe estar instalado antes de crear las Applications.**

```bash
# Crear namespace de ArgoCD
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que esté listo (2-3 minutos)
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd

# Verificar
kubectl get pods -n argocd
```

## 1️⃣ Crear Namespaces

```bash
kubectl apply -f clusters/single-cluster/namespace-dev.yaml
kubectl apply -f clusters/single-cluster/namespace-prod.yaml

# Verificar
kubectl get namespaces -l app=task-manager
```

## 2️⃣ Crear Applications en ArgoCD

Los namespaces deben existir previamente.

**⚠️ Nota:** Si tu cluster no es `localhost` (en Minikube/local), actualiza el endpoint en:
- `clusters/single-cluster/task-manager-dev-application.yaml`
- `clusters/single-cluster/task-manager-prod-application.yaml`

Busca `destination.server` y reemplaza con tu Kubernetes API endpoint.

```bash
# Aplicar uno a uno
kubectl apply -f clusters/single-cluster/task-manager-dev-application.yaml
kubectl apply -f clusters/single-cluster/task-manager-prod-application.yaml

# O usar Kustomize para todo junto
kubectl apply -k clusters/single-cluster/

# Verificar
kubectl get applications -n argocd -o wide
```

## 3️⃣ Actualizar Imagen

**Development:**
```bash
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=my-registry/task-manager:v1.2.3
cd -
```

**Production:**
```bash
cd apps/task-manager/overlays/prod
kustomize edit set image task-manager=my-registry/task-manager:v1.0.1
cd -
```

**Commit y Push:**
```bash
git add apps/task-manager/overlays/*/kustomization.yaml
git commit -m "chore: update image tags"
git push
```

ArgoCD sincronizará automáticamente.

## 4️⃣ (Opcional) Despliegue Manual Una Sola Vez

Si deseas aplicar manualmente los manifiestos (sin esperar a que ArgoCD sincronice):

```bash
# Compilar y aplicar dev
kubectl kustomize apps/task-manager/overlays/dev | kubectl apply -f -

# Compilar y aplicar prod
kubectl kustomize apps/task-manager/overlays/prod | kubectl apply -f -

# Verificar que se crearon
kubectl get pods -n dev -n prod
```

Ver detalles en: **`MANUAL_DEPLOYMENT.md`**

## 5️⃣ Acceder a ArgoCD Dashboard

### Exponer el servicio (elegir una opción):

**Opción A: Port Forward (recomendado para desarrollo)**
```bash
# Terminal 1: Exponer ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Obtener contraseña
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo ""

# Acceder a: https://localhost:8080
# Usuario: admin
# Contraseña: (copiar del comando anterior)
```

**Opción B: LoadBalancer (para producción)**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n argocd  # Ver IP externa
```

## 6️⃣ Monitoreo

```bash
# Ver estado de Applications en ArgoCD
kubectl get applications -n argocd -o wide

# Ver deployments en dev
kubectl get deployments -n dev -o wide
kubectl get pods -n dev

# Ver deployments en prod
kubectl get deployments -n prod -o wide
kubectl get pods -n prod

# Ver logs
kubectl logs -f -l app=task-manager -n dev
kubectl logs -f -l app=task-manager -n prod
```

## 7️⃣ Validación Local (Sin Desplegar)

```bash
# Ver manifiestos que se generarían en dev
kubectl kustomize apps/task-manager/overlays/dev

# Ver manifiestos que se generarían en prod
kubectl kustomize apps/task-manager/overlays/prod

# Ver manifiestos del cluster
kubectl kustomize clusters/single-cluster/
```

## 3️⃣ Actualizar Imagen

**Development:**
```bash
cd apps/task-manager/overlays/dev
kustomize edit set image task-manager=my-registry/task-manager:v1.2.3
cd -
```

**Production:**
```bash
cd apps/task-manager/overlays/prod
kustomize edit set image task-manager=my-registry/task-manager:v1.0.1
cd -
```

**Commit y Push:**
```bash
git add apps/task-manager/overlays/*/kustomization.yaml
git commit -m "chore: update image tags"
git push
```

ArgoCD sincronizará automáticamente.

---

**Todos los cambios van en Git → ArgoCD los sincroniza automáticamente.**
