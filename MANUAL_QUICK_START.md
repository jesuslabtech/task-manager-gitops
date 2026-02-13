# 📋 Guía Rápida - Despliegue Manual y ArgoCD Dashboard

## 🎯 Situación Actual

Tienes ArgoCD instalado pero los Pods aún no se ven en los namespaces.
Hay dos razones:
1. ArgoCD puede tardar en sincronizar automáticamente
2. Quieres acceder al dashboard de ArgoCD

---

## ✅ Solución: Despliegue Manual + Dashboard

### Opción 1️⃣: Script Automatizado (Recomendado)

#### A. Despliegue Manual

```bash
# Hacer ejecutable
chmod +x deploy-manual.sh

# Ejecutar
./deploy-manual.sh
```

**Qué hace:**
- Compila manifiestos con Kustomize
- Aplica dev y prod manualmente
- Verifica que se crearon
- Espera a que los Pods estén ready
- Muestra instrucciones para acceder a ArgoCD

#### B. Exponer ArgoCD Dashboard

**Terminal 1: Abrir port-forward**
```bash
chmod +x argocd-expose.sh
./argocd-expose.sh port-forward
```

**Terminal 2: Obtener credenciales**
```bash
./argocd-expose.sh credentials
```

**Luego acceder a:**
```
https://localhost:8080
Usuario: admin
Contraseña: (del comando anterior)
```

---

### Opción 2️⃣: Comandos Manuales

#### Despliegue Manual (sin script)

```bash
# 1. Compilar dev
kubectl kustomize apps/task-manager/overlays/dev | kubectl apply -f -

# 2. Compilar prod
kubectl kustomize apps/task-manager/overlays/prod | kubectl apply -f -

# 3. Verificar
kubectl get pods -n dev -n prod

# 4. Esperar a que estén ready
kubectl rollout status deployment/task-manager -n dev
kubectl rollout status deployment/task-manager -n prod
```

#### Exponer ArgoCD (sin script)

**Terminal 1: Port Forward**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Terminal 2: Credenciales**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo ""
```

**Acceder a:** `https://localhost:8080`

---

## 📊 Verificación

### Ver que todo está correcto

```bash
# Ver Deployments
kubectl get deployments -n dev -n prod -o wide

# Ver Pods
kubectl get pods -n dev -n prod -o wide

# Ver Services
kubectl get svc -n dev -n prod -o wide

# Ver ArgoCD Applications
kubectl get applications -n argocd -o wide
```

---

## 🔄 En ArgoCD Dashboard

Una vez accedas a `https://localhost:8080`:

1. **Verás:**
   - Application: `task-manager-dev` 
   - Application: `task-manager-prod`

2. **Estado esperado:**
   - Nombre: Verde
   - Estado: Puede ser "Syncing" o "Synced"
   - Health: "Progressing" o "Healthy"

3. **Si está "OutOfSync":**
   - Click en la Application
   - Click en botón "Sync"
   - Esperar a que termine

---

## 📁 Archivos Creados

| Archivo | Descripción |
|---------|-------------|
| `MANUAL_DEPLOYMENT.md` | Guía completa de despliegue manual |
| `deploy-manual.sh` | Script automático de despliegue |
| `argocd-expose.sh` | Script para exponer ArgoCD |
| `QUICKSTART.md` | Actualizado con nuevas opciones |

---

## 🎯 Flujo Recomendado

```
1. Ejecutar: ./deploy-manual.sh
   ↓
2. Esperar a que termine
   ↓
3. En Terminal 1: ./argocd-expose.sh port-forward
   ↓
4. En Terminal 2: ./argocd-expose.sh credentials
   ↓
5. Acceder a: https://localhost:8080
   ↓
6. Ver Applications en verde (Synced)
```

---

## ✅ Checklist

- [ ] Ejecutaste `./deploy-manual.sh`
- [ ] Viste los Pods en `kubectl get pods -n dev -n prod`
- [ ] Ejecutaste `./argocd-expose.sh port-forward`
- [ ] Ejecutaste `./argocd-expose.sh credentials`
- [ ] Accediste a `https://localhost:8080`
- [ ] Viste las 2 Applications (dev y prod)
- [ ] Viste que están "Synced" (verde)

---

## 🚀 Próximo Paso

Después de verificar que todo funciona manualmente:

1. ArgoCD ahora mantiene sincronizados todos los cambios
2. Para actualizar imagen, solo necesitas editar Git
3. ArgoCD detectará cambios y sincronizará automáticamente

---

**Nota:** El despliegue manual es solo para verificación.  
En producción, ArgoCD maneja todo automáticamente desde Git.
