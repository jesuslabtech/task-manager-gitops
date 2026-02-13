#!/bin/bash

# Script de despliegue manual rápido
# Uso: ./deploy-manual.sh

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🚀 DESPLIEGUE MANUAL - Task Manager (dev y prod)           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}1️⃣  Compilando manifiestos...${NC}"
echo ""

# Compilar dev
echo "   Compilando dev..."
kubectl kustomize apps/task-manager/overlays/dev > /tmp/dev-manifest.yaml
echo -e "   ${GREEN}✓ Dev compilado${NC}"

# Compilar prod
echo "   Compilando prod..."
kubectl kustomize apps/task-manager/overlays/prod > /tmp/prod-manifest.yaml
echo -e "   ${GREEN}✓ Prod compilado${NC}"

echo ""
echo -e "${BLUE}2️⃣  Aplicando manifiestos en cluster...${NC}"
echo ""

# Aplicar dev
echo "   Aplicando dev..."
kubectl apply -f /tmp/dev-manifest.yaml
echo -e "   ${GREEN}✓ Dev aplicado${NC}"

# Aplicar prod
echo "   Aplicando prod..."
kubectl apply -f /tmp/prod-manifest.yaml
echo -e "   ${GREEN}✓ Prod aplicado${NC}"

echo ""
echo -e "${BLUE}3️⃣  Verificando recursos...${NC}"
echo ""

# Pequeña pausa para que Kubernetes cree los recursos
sleep 2

echo "   Deployments:"
kubectl get deployments -A | grep task-manager || echo "   (esperando creación...)"

echo ""
echo "   Pods:"
kubectl get pods -A | grep task-manager || echo "   (esperando creación...)"

echo ""
echo -e "${YELLOW}⏳  Esperando a que los Pods estén Ready...${NC}"
echo ""

# Esperar a que los pods estén ready
echo "   Dev:"
kubectl rollout status deployment/task-manager -n dev --timeout=2m || true

echo ""
echo "   Prod:"
kubectl rollout status deployment/task-manager -n prod --timeout=2m || true

echo ""
echo -e "${GREEN}✅ DESPLIEGUE MANUAL COMPLETADO${NC}"
echo ""

echo "────────────────────────────────────────────────────────────────"
echo ""
echo "📊 ESTADO ACTUAL:"
echo ""
echo "Dev:"
kubectl get deployments -n dev -o wide | grep task-manager || echo "(no encontrado)"
kubectl get pods -n dev -o wide | grep task-manager || echo "(no encontrado)"

echo ""
echo "Prod:"
kubectl get deployments -n prod -o wide | grep task-manager || echo "(no encontrado)"
kubectl get pods -n prod -o wide | grep task-manager || echo "(no encontrado)"

echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""
echo -e "${YELLOW}🔐 SIGUIENTE PASO: Acceder a ArgoCD${NC}"
echo ""
echo "   Terminal 1 (exponer ArgoCD):"
echo "   $ kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "   Terminal 2 (obtener credenciales):"
echo "   $ kubectl -n argocd get secret argocd-initial-admin-secret \\"
echo "     -o jsonpath=\"{.data.password}\" | base64 -d && echo \"\""
echo ""
echo "   Acceder a: https://localhost:8080"
echo "   Usuario: admin"
echo ""
echo "────────────────────────────────────────────────────────────────"
