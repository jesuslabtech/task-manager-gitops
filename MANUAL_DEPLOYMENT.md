# 🔧 Despliegue Manual - Una Sola Vez

## ¿Por qué aplicar manualmente?

Después de instalar ArgoCD y crear las Applications, a veces tarda en sincronizar automáticamente. 
Aplicar manualmente asegura que los recursos se creen inmediatamente.

---

## 📋 Pasos para Despliegue Manual

### Paso 1: Compilar manifiestos

```bash
# Generar manifiestos de desarrollo
kubectl kustomize apps/task-manager/overlays/dev > /tmp/dev-manifest.yaml

# Generar manifiestos de producción
kubectl kustomize apps/task-manager/overlays/prod > /tmp/prod-manifest.yaml

# Ver los manifiestos generados
cat /tmp/dev-manifest.yaml
cat /tmp/prod-manifest.yaml
```

### Paso 2: Aplicar manualmente

```bash
# Aplicar dev
kubectl apply -f /tmp/dev-manifest.yaml

# Aplicar prod
kubectl apply -f /tmp/prod-manifest.yaml

# Verificar que se crearon
kubectl get deployments -n dev -o wide
kubectl get deployments -n prod -o wide
kubectl get pods -n dev
kubectl get pods -n prod
```

### Paso 3: Verificar estado

```bash
# Ver Deployments
kubectl get deployments -A | grep task-manager

# Ver Pods
kubectl get pods -A | grep task-manager

# Ver Services
kubectl get svc -A | grep task-manager

# Ver ConfigMaps y Secrets
kubectl get configmap,secret -n dev
kubectl get configmap,secret -n prod
```

### Paso 4: Ver logs

```bash
# Dev logs
kubectl logs -f -l app=task-manager -n dev

# Prod logs
kubectl logs -f -l app=task-manager -n prod
```

---

## 🔐 Exponer Dashboard de ArgoCD

ArgoCD viene con un servicio ClusterIP (solo interno). Para acceder al dashboard, necesitas exponerlo.

### Opción A: Port Forward (Más fácil, temporal)

```bash
# Abrir acceso al dashboard en local
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Luego accede a:
# https://localhost:8080
```

**Usuario:** `admin`  
**Contraseña:** (obtén con el comando abajo)

### Opción B: LoadBalancer (Permanente)

```bash
# Cambiar servicio a LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Ver IP externa (espera a que se asigne)
kubectl get svc -n argocd
```

### Opción C: NodePort (Para desarrollo)

```bash
# Cambiar servicio a NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Ver puerto asignado
kubectl get svc -n argocd

# Acceder a: http://<node-ip>:<port>
```

---

## 🔑 Obtener Credenciales de ArgoCD

```bash
# Usuario: admin
# Contraseña (decodificar base64):
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""  # Salto de línea

# O con el CLI de ArgoCD (si está instalado):
argocd admin initial-password -n argocd
```

---

## 📊 Una Vez en ArgoCD Dashboard

1. **Accede a:** `https://localhost:8080` (con port-forward)
2. **Usuario:** `admin`
3. **Contraseña:** (obtenida arriba)
4. **Verás:**
   - Application: `task-manager-dev` 
   - Application: `task-manager-prod`
5. **Estado:** Deberían mostrar "Synced" después de un rato

---

## 🔄 Sincronización Manual desde ArgoCD

Si deseas sincronizar manualmente desde el dashboard:

1. Click en `task-manager-dev`
2. Click en botón **"Sync"** (esquina superior derecha)
3. Esperar a que termine (verde = OK)

O desde CLI:

```bash
argocd app sync task-manager-dev
argocd app sync task-manager-prod
```

---

## ✅ Checklist

- [ ] Compilaste manifiestos con `kubectl kustomize`
- [ ] Aplicaste manualmente con `kubectl apply -f`
- [ ] Verificaste que se crearon con `kubectl get pods -n dev`
- [ ] Expusiste ArgoCD (port-forward o LoadBalancer)
- [ ] Accediste al dashboard
- [ ] Viste ambas Applications en ArgoCD

---

## 🎯 Resumen de Comandos Rápidos

```bash
# Todo de una sola vez:

# 1. Compilar
kubectl kustomize apps/task-manager/overlays/dev > /tmp/dev.yaml
kubectl kustomize apps/task-manager/overlays/prod > /tmp/prod.yaml

# 2. Aplicar
kubectl apply -f /tmp/dev.yaml
kubectl apply -f /tmp/prod.yaml

# 3. Verificar
kubectl get pods -n dev -n prod

# 4. Exponer ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 5. En otra terminal - obtener credenciales
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 6. Acceder a: https://localhost:8080
```

---

**Nota:** Después de esto, ArgoCD debería mantener sincronizados los recursos automáticamente según los cambios en Git.
