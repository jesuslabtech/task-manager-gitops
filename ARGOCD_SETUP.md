# 🔧 Instalación de ArgoCD

## ⚠️ Requisito Previo

**ArgoCD debe estar instalado ANTES de crear las Applications.**

El error que recibiste:
```
resource mapping not found for name: "task-manager-dev" namespace: "argocd" 
no matches for kind "Application" in version "argoproj.io/v1alpha1"
```

Significa que los **CRDs (Custom Resource Definitions)** de ArgoCD no están instalados en el cluster.

---

## 🚀 Instalación Rápida

### Paso 1: Crear Namespace de ArgoCD

```bash
kubectl create namespace argocd
```

### Paso 2: Instalar ArgoCD

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Paso 3: Esperar a que esté listo

```bash
# Esperar a que el controller esté disponible (2-3 minutos)
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd

# Verificar pods
kubectl get pods -n argocd

# Esperado: ver pods de argocd-application-controller, argocd-server, etc.
```

### Paso 4: Verificar Instalación

```bash
# Ver versión de ArgoCD
kubectl exec -n argocd svc/argocd-server -- argocd version

# Ver servicios
kubectl get svc -n argocd

# Ver CRDs instalados (deberías ver Application, AppProject, etc.)
kubectl get crd | grep argoproj
```

---

## ✅ Verificación Completa

```bash
# 1. Namespace existe
kubectl get namespace argocd

# 2. Pods están running
kubectl get pods -n argocd

# 3. CRDs están disponibles
kubectl api-resources | grep argocd

# 4. Services están disponibles
kubectl get svc -n argocd
```

**Si todos pasan, ya puedes continuar con los pasos de despliegue.**

---

## 🔐 Acceder a ArgoCD UI (Opcional)

### Port Forward

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Luego accede a: `https://localhost:8080`

### Obtener Contraseña Inicial

```bash
# Usuario: admin
# Contraseña:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

---

## 📋 Despliegue Completo (Después de instalar ArgoCD)

Una vez ArgoCD esté instalado:

```bash
# 1. Crear namespaces
kubectl apply -f clusters/single-cluster/namespace-{dev,prod}.yaml

# 2. Crear Applications
kubectl apply -k clusters/single-cluster/

# 3. Verificar
kubectl get applications -n argocd -o wide
```

---

## ❌ Troubleshooting

### ArgoCD pods no inician

```bash
# Ver eventos
kubectl describe pod -n argocd

# Ver logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### CRDs no aparecen

```bash
# Reintentar instalación
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar de nuevo
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd
```

### Namespace argocd ya existe

```bash
# Si ya existe, solo aplicar el manifesto
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## 🎯 Orden Correcto de Instalación

```
1. Instalar ArgoCD
   ↓
2. Esperar a que esté ready
   ↓
3. Crear namespaces (dev, prod)
   ↓
4. Crear Applications (apuntan a overlays)
   ↓
5. ArgoCD sincroniza automáticamente
```

---

## 📝 Script de Instalación Automatizada

```bash
#!/bin/bash

echo "🔧 Instalando ArgoCD..."

# 1. Crear namespace
kubectl create namespace argocd

# 2. Instalar
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Esperar
echo "⏳ Esperando a que ArgoCD esté listo..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-application-controller -n argocd

# 4. Verificar
echo "✅ ArgoCD instalado!"
kubectl get pods -n argocd

echo ""
echo "Próximo paso: ejecutar QUICKSTART.md"
```

---

**Notas:**
- Version estable: `stable/` (usa latest)
- Version específica: `v2.10.0/` (replace `stable` con la versión)
- Este manifesto incluye todos los CRDs necesarios

---

**Una vez instalado ArgoCD, continúa con QUICKSTART.md**
