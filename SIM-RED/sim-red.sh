#!/bin/bash
# SIM-RED EXTENDIDO - Main Menu
# Network Analysis and Security System

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "${SCRIPT_DIR}/lib/common.sh"

# Main function
main() {
    # Check requirements on first run
    check_initial_requirements
    
    # Main menu loop
    while true; do
        show_menu
        read -r option
        
        case "$option" in
            1)  run_feature "Verificar dispositivos conectados" "${SCRIPT_DIR}/bin/check_devices.sh" ;;
            2)  run_feature "Verificar suplantación de IP" "${SCRIPT_DIR}/bin/check_spoofing.sh" ;;
            3)  run_feature "Detectar VPN/Proxy" "${SCRIPT_DIR}/bin/detect_vpn.sh" ;;
            4)  run_feature "Medir latencia promedio" "${SCRIPT_DIR}/bin/measure_latency.sh" ;;
            5)  run_feature "Monitoreo continuo de latencia" "${SCRIPT_DIR}/bin/monitor_latency.sh" ;;
            6)  run_feature "Medir tráfico de red" "${SCRIPT_DIR}/bin/measure_traffic.sh" ;;
            7)  run_feature "Monitoreo ARP en tiempo real" "${SCRIPT_DIR}/bin/monitor_arp.sh" ;;
            8)  run_feature "Verificar integridad de archivos" "${SCRIPT_DIR}/bin/check_integrity.sh" ;;
            9)  run_feature "Escanear puertos" "${SCRIPT_DIR}/bin/scan_ports.sh" ;;
            10) run_feature "Comprobar DNS" "${SCRIPT_DIR}/bin/check_dns.sh" ;;
            11) run_feature "Detectar anomalías" "${SCRIPT_DIR}/bin/detect_anomalies.sh" ;;
            12) run_feature "Generar informe completo" "${SCRIPT_DIR}/bin/generate_report.sh" ;;
            13) run_feature "Gestión de logs" "${SCRIPT_DIR}/bin/manage_logs.sh" ;;
            14) run_feature "Configuración" "${SCRIPT_DIR}/bin/configure.sh" ;;
            15) run_feature "Verificar herramientas" "${SCRIPT_DIR}/bin/check_requirements.sh" ;;
            0)  exit_program ;;
            *)  print_error "Opción inválida"; sleep 1 ;;
        esac
    done
}

# Show main menu
show_menu() {
    clear
    
    # ASCII Art Header
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║                                                                       ║"
    print_color "$CYAN" "║   ███████╗██╗███╗   ███╗      ██████╗ ███████╗██████╗                ║"
    print_color "$CYAN" "║   ██╔════╝██║████╗ ████║      ██╔══██╗██╔════╝██╔══██╗               ║"
    print_color "$CYAN" "║   ███████╗██║██╔████╔██║█████╗██████╔╝█████╗  ██║  ██║               ║"
    print_color "$CYAN" "║   ╚════██║██║██║╚██╔╝██║╚════╝██╔══██╗██╔══╝  ██║  ██║               ║"
    print_color "$CYAN" "║   ███████║██║██║ ╚═╝ ██║      ██║  ██║███████╗██████╔╝               ║"
    print_color "$CYAN" "║   ╚══════╝╚═╝╚═╝     ╚═╝      ╚═╝  ╚═╝╚══════╝╚═════╝                ║"
    print_color "$CYAN" "║                                                                       ║"
    print_color "$CYAN" "║              Sistema de Análisis y Seguridad de Red                  ║"
    print_color "$CYAN" "║                        EXTENDIDO v1.0                                 ║"
    print_color "$CYAN" "║                                                                       ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    print_color "$WHITE" "┌───────────────────────────────────────────────────────────────────────┐"
    print_color "$WHITE" "│                      MENÚ PRINCIPAL                                   │"
    print_color "$WHITE" "└───────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    print_color "$GREEN" "  MONITOREO DE DISPOSITIVOS"
    echo "    ${CYAN}1)${NC}  Verificar dispositivos conectados en la red"
    echo "    ${CYAN}2)${NC}  Verificar suplantación de IP (Anti-Spoofing)"
    echo "    ${CYAN}3)${NC}  Detectar si un usuario está usando VPN o Proxy"
    echo ""
    
    print_color "$GREEN" "  ANÁLISIS DE RENDIMIENTO"
    echo "    ${CYAN}4)${NC}  Medir latencia promedio de toda la red"
    echo "    ${CYAN}5)${NC}  Medición continua de latencia (modo monitor)"
    echo "    ${CYAN}6)${NC}  Medir tráfico de red por host (Up/Down)"
    echo ""
    
    print_color "$GREEN" "  SEGURIDAD Y MONITOREO"
    echo "    ${CYAN}7)${NC}  Monitoreo ARP en tiempo real"
    echo "    ${CYAN}8)${NC}  Verificar integridad del archivo de hosts autorizados"
    echo "    ${CYAN}9)${NC}  Escanear puertos importantes de cada host"
    echo "    ${CYAN}10)${NC} Comprobar disponibilidad del servidor DNS"
    echo "    ${CYAN}11)${NC} Detectar anomalías de red"
    echo ""
    
    print_color "$GREEN" "  INFORMES Y CONFIGURACIÓN"
    echo "    ${CYAN}12)${NC} Generar informe completo del estado de la red"
    echo "    ${CYAN}13)${NC} Gestión de logs"
    echo "    ${CYAN}14)${NC} Configuración del sistema"
    echo ""
    
    print_color "$GREEN" "  SISTEMA"
    echo "    ${CYAN}15)${NC} Verificación de herramientas"
    echo "    ${RED}0)${NC}  Salir"
    echo ""
    
    print_color "$WHITE" "───────────────────────────────────────────────────────────────────────"
    echo -n "  Selecciona una opción: "
}

# Check requirements on startup
check_initial_requirements() {
    local req_script="${SCRIPT_DIR}/bin/check_requirements.sh"
    
    if [[ -f "$req_script" ]]; then
        # Run requirements check
        bash "$req_script"
        
        local exit_code=$?
        
        if [[ $exit_code -ne 0 ]]; then
            echo ""
            print_warning "Algunas herramientas no están disponibles"
            print_info "Puedes ejecutar la opción 15 del menú en cualquier momento para verificar"
            echo ""
            press_any_key
        fi
    fi
}

# Run a feature script
run_feature() {
    local feature_name="$1"
    local script_path="$2"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script no encontrado: $script_path"
        press_any_key
        return 1
    fi
    
    # Make script executable
    chmod +x "$script_path" 2>/dev/null
    
    # Run the script
    bash "$script_path"
    
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        print_warning "La función finalizó con errores"
        press_any_key
    fi
}

# Exit program
exit_program() {
    clear
    print_header "SIM-RED EXTENDIDO"
    echo ""
    print_color "$CYAN" "  Gracias por usar SIM-RED EXTENDIDO"
    print_color "$CYAN" "  Sistema de Análisis y Seguridad de Red"
    echo ""
    print_color "$GREEN" "  ¡Hasta pronto!"
    echo ""
    exit 0
}

# Run main function
main "$@"
