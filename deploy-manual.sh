#!/bin/bash

# Quick manual deployment script
# Usage: ./deploy-manual.sh

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     🚀 MANUAL DEPLOYMENT - Task Manager (dev and prod)      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}1️⃣  Compiling manifests...${NC}"
echo ""

# Compile dev
echo "   Compiling dev..."
kubectl kustomize apps/task-manager/overlays/dev > /tmp/dev-manifest.yaml
echo -e "   ${GREEN}✓ Dev compiled${NC}"

# Compile prod
echo "   Compiling prod..."
kubectl kustomize apps/task-manager/overlays/prod > /tmp/prod-manifest.yaml
echo -e "   ${GREEN}✓ Prod compiled${NC}"

echo ""
echo -e "${BLUE}2️⃣  Applying manifests to cluster...${NC}"
echo ""

# Apply dev
echo "   Applying dev..."
kubectl apply -f /tmp/dev-manifest.yaml
echo -e "   ${GREEN}✓ Dev applied${NC}"

# Apply prod
echo "   Applying prod..."
kubectl apply -f /tmp/prod-manifest.yaml
echo -e "   ${GREEN}✓ Prod applied${NC}"

echo ""
echo -e "${BLUE}3️⃣  Verifying resources...${NC}"
echo ""

# Small pause for Kubernetes to create resources
sleep 2

echo "   Deployments:"
kubectl get deployments -A | grep task-manager || echo "   (waiting for creation...)"

echo ""
echo "   Pods:"
kubectl get pods -A | grep task-manager || echo "   (waiting for creation...)"

echo ""
echo -e "${YELLOW}⏳  Waiting for Pods to be Ready...${NC}"
echo ""

# Wait for pods to be ready
echo "   Dev:"
kubectl rollout status deployment/task-manager -n dev --timeout=2m || true

echo ""
echo "   Prod:"
kubectl rollout status deployment/task-manager -n prod --timeout=2m || true

echo ""
echo -e "${GREEN}✅ MANUAL DEPLOYMENT COMPLETED${NC}"
echo ""

echo "────────────────────────────────────────────────────────────────"
echo ""
echo "📊 CURRENT STATUS:"
echo ""
echo "Dev:"
kubectl get deployments -n dev -o wide | grep task-manager || echo "(not found)"
kubectl get pods -n dev -o wide | grep task-manager || echo "(not found)"

echo ""
echo "Prod:"
kubectl get deployments -n prod -o wide | grep task-manager || echo "(not found)"
kubectl get pods -n prod -o wide | grep task-manager || echo "(not found)"

echo ""
echo "────────────────────────────────────────────────────────────────"
echo ""
echo -e "${YELLOW}🔐 NEXT STEP: Access ArgoCD${NC}"
echo ""
echo "   Terminal 1 (expose ArgoCD):"
echo "   $ kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "   Terminal 2 (get credentials):"
echo "   $ kubectl -n argocd get secret argocd-initial-admin-secret \\"
echo "     -o jsonpath=\"{.data.password}\" | base64 -d && echo \"\""
echo ""
echo "   Access at: https://localhost:8080"
echo "   Username: admin"
echo ""
echo "────────────────────────────────────────────────────────────────"
