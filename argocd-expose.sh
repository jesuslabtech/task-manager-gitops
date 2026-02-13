#!/bin/bash

# Script para exponer ArgoCD Dashboard
# Uso: ./argocd-expose.sh [option]
# Options: port-forward, loadbalancer, nodeport, credentials

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OPTION=${1:-"help"}

show_help() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════╗
║             🔐 Script de Exposición de ArgoCD                    ║
╚═══════════════════════════════════════════════════════════════════╝

Uso: ./argocd-expose.sh [opción]

Opciones:
  port-forward      Port forward a localhost:8080 (recomendado)
  loadbalancer      Cambiar a LoadBalancer (producción)
  nodeport          Cambiar a NodePort (desarrollo)
  credentials       Obtener credenciales de acceso
  status            Ver status actual del servicio
  help              Mostrar esta ayuda

Ejemplos:
  ./argocd-expose.sh port-forward
  ./argocd-expose.sh credentials
  ./argocd-expose.sh loadbalancer

EOF
}

port_forward() {
    echo -e "${BLUE}🔄 Activando Port Forward...${NC}"
    echo ""
    echo "   Servicio: argocd-server"
    echo "   Puerto local: 8080"
    echo "   Puerto remoto: 443"
    echo ""
    echo -e "${YELLOW}⏳ Port forward activo. Presiona Ctrl+C para detener.${NC}"
    echo ""
    kubectl port-forward svc/argocd-server -n argocd 8080:443
}

loadbalancer() {
    echo -e "${BLUE}🔄 Cambiando a LoadBalancer...${NC}"
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    echo -e "${GREEN}✓ Servicio cambiado a LoadBalancer${NC}"
    echo ""
    echo "   Esperando IP externa..."
    sleep 3
    show_status
}

nodeport() {
    echo -e "${BLUE}🔄 Cambiando a NodePort...${NC}"
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
    echo -e "${GREEN}✓ Servicio cambiado a NodePort${NC}"
    echo ""
    echo "   Puerto asignado:"
    kubectl get svc argocd-server -n argocd --no-headers | awk '{print $5}' | cut -d'/' -f1
    echo ""
    echo -e "${YELLOW}   Acceder a: http://<node-ip>:<puerto>${NC}"
}

credentials() {
    echo -e "${BLUE}🔑 Obteniendo credenciales...${NC}"
    echo ""
    
    echo -e "${GREEN}Usuario:${NC}"
    echo "  admin"
    echo ""
    
    echo -e "${GREEN}Contraseña:${NC}"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""
    echo ""
}

show_status() {
    echo -e "${BLUE}📊 Estado del Servicio ArgoCD:${NC}"
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
        echo -e "${RED}❌ Opción desconocida: $OPTION${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
