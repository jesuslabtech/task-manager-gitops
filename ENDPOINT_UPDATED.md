# ✅ Actualización - Endpoint del Cluster Linode LKE

## 🔧 Problema Identificado

Las Applications de ArgoCD estaban configuradas con `server: https://kubernetes.default.svc` que apunta al cluster local. 

Tu cluster es Linode LKE con endpoint externo:
```
https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443
```

## ✅ Solución Aplicada

He actualizado automáticamente:

### Archivos Modificados

1. **`clusters/single-cluster/task-manager-dev-application.yaml`**
   ```yaml
   destination:
     server: https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443
   ```

2. **`clusters/single-cluster/task-manager-prod-application.yaml`**
   ```yaml
   destination:
     server: https://d9365f90-e8db-44da-ac54-175eac736387.eu-central-1-gw.linodelke.net:443
   ```

### Archivos de Documentación Creados

1. **`CLUSTER_ENDPOINT_CONFIG.md`** - Guía completa sobre endpoints
2. **`QUICKSTART.md`** - Actualizado con nota sobre endpoints

---

## 🚀 Ahora Puedes

```bash
# Aplicar las Applications actualizadas
kubectl apply -k clusters/single-cluster/

# Verificar que están sincronizadas
kubectl get applications -n argocd -o wide

# Ver el endpoint configurado
kubectl get application task-manager-dev -n argocd \
  -o jsonpath='{.spec.destination.server}'
```

---

## ✨ Qué Cambió

| Archivo | Cambio |
|---------|--------|
| `task-manager-dev-application.yaml` | ✏️ Endpoint actualizado a Linode LKE |
| `task-manager-prod-application.yaml` | ✏️ Endpoint actualizado a Linode LKE |
| `QUICKSTART.md` | ✏️ Agregada nota sobre endpoints |
| `CLUSTER_ENDPOINT_CONFIG.md` | 🆕 Nuevo - Guía de configuración |

---

## ✅ Estado Actual

```
Applications: ✅ Configuradas con endpoint correcto
Namespaces: ✅ Creados (dev, prod)
ArgoCD: ✅ Instalado y accesible
Endpoint: ✅ Apunta a Linode LKE
```

---

## 🎯 Próximos Pasos

```bash
# 1. Aplicar Applications
kubectl apply -k clusters/single-cluster/

# 2. Esperar a que sincronicen (1-2 minutos)
kubectl get applications -n argocd -o wide --watch

# 3. Verificar Pods
kubectl get pods -n dev -n prod

# 4. Acceder a ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080
```

---

## 📝 Para el Futuro

Si cambias de cluster, solo necesitas:

1. Obtener nuevo endpoint
2. Actualizar en `clusters/single-cluster/task-manager-*-application.yaml`
3. Aplicar cambios: `kubectl apply -k clusters/single-cluster/`

Ver: `CLUSTER_ENDPOINT_CONFIG.md` para más detalles.

---

**Cambio completado:** 13 de febrero de 2026
