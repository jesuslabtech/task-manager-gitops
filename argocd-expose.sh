#!/bin/bash

# Script to expose ArgoCD Dashboard
# Usage: ./argocd-expose.sh [option]
# Options: port-forward, loadbalancer, nodeport, credentials

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OPTION=${1:-"help"}

show_help() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║             🔐 ArgoCD Exposure Script                            ║
╚═══════════════════════════════════════════════════════════════════╝

Usage: ./argocd-expose.sh [option]

Options:
  port-forward      Port forward to localhost:8080 (recommended)
  loadbalancer      Change to LoadBalancer (production)
  nodeport          Change to NodePort (development)
  credentials       Get access credentials
  status            See current service status
  help              Show this help

Examples:
  ./argocd-expose.sh port-forward
  ./argocd-expose.sh credentials
  ./argocd-expose.sh loadbalancer

EOF
}

port_forward() {
    echo -e "${BLUE}🔄 Activating Port Forward...${NC}"
    echo ""
    echo "   Service: argocd-server"
    echo "   Local port: 8080"
    echo "   Remote port: 443"
    echo ""
    echo -e "${YELLOW}⏳ Port forward active. Press Ctrl+C to stop.${NC}"
    echo ""
    kubectl port-forward svc/argocd-server -n argocd 8080:443
}

loadbalancer() {
    echo -e "${BLUE}🔄 Changing to LoadBalancer...${NC}"
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    echo -e "${GREEN}✓ Service changed to LoadBalancer${NC}"
    echo ""
    echo "   Waiting for external IP..."
    sleep 3
    show_status
}

nodeport() {
    echo -e "${BLUE}🔄 Changing to NodePort...${NC}"
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
    echo -e "${GREEN}✓ Service changed to NodePort${NC}"
    echo ""
    echo "   Assigned port:"
    kubectl get svc argocd-server -n argocd --no-headers | awk '{print $5}' | cut -d'/' -f1
    echo ""
    echo -e "${YELLOW}   Access at: http://<node-ip>:<port>${NC}"
}

credentials() {
    echo -e "${BLUE}🔑 Getting credentials...${NC}"
    echo ""
    
    echo -e "${GREEN}Username:${NC}"
    echo "  admin"
    echo ""
    
    echo -e "${GREEN}Password:${NC}"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""
    echo ""
}

show_status() {
    echo -e "${BLUE}📊 ArgoCD Service Status:${NC}"
    echo ""
    kubectl get svc argocd-server -n argocd -o wide
    echo ""
}

case $OPTION in
    port-forward)
        port_forward
        ;;
    loadbalancer)
        loadbalancer
        ;;
    nodeport)
        nodeport
        ;;
    credentials)
        credentials
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown option: $OPTION${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
