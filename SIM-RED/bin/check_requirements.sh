#!/bin/bash
# SIM-RED EXTENDIDO - Tool Verification Script
# Feature 15: Check and install required tools

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

REQUIREMENTS_FILE="${SCRIPT_DIR}/config/requirements.txt"
MISSING_TOOLS=()
INSTALLED_TOOLS=()

# Main function
main() {
    print_header "Verificación de Herramientas Requeridas"
    
    if ! check_file "$REQUIREMENTS_FILE"; then
        print_error "No se encontró el archivo de requisitos: $REQUIREMENTS_FILE"
        return 1
    fi
    
    # Read required tools
    local tools=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        
        tools+=("$line")
    done < "$REQUIREMENTS_FILE"
    
    print_info "Verificando ${#tools[@]} herramientas..."
    echo ""
    
    # Check each tool
    for tool in "${tools[@]}"; do
        check_tool "$tool"
    done
    
    # Summary
    print_separator
    echo ""
    print_info "Herramientas instaladas: ${GREEN}${#INSTALLED_TOOLS[@]}${NC}"
    print_info "Herramientas faltantes: ${RED}${#MISSING_TOOLS[@]}${NC}"
    echo ""
    
    # If all tools are installed
    if [[ ${#MISSING_TOOLS[@]} -eq 0 ]]; then
        print_success "✓ Todo listo para iniciar"
        return 0
    fi
    
    # Offer to install missing tools
    print_warning "Faltan ${#MISSING_TOOLS[@]} herramientas:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    echo ""
    
    # Ask to install
    if ask_yes_no "¿Deseas instalar las herramientas faltantes?" "y"; then
        install_missing_tools
    else
        print_warning "Algunas funciones pueden no estar disponibles sin estas herramientas"
        return 1
    fi
}

# Check if a tool is installed
check_tool() {
    local tool="$1"
    
    printf "  %-20s ... " "$tool"
    
    if command_exists "$tool"; then
        print_color "$GREEN" "✓ Instalado"
        INSTALLED_TOOLS+=("$tool")
        return 0
    else
        print_color "$RED" "✗ No encontrado"
        MISSING_TOOLS+=("$tool")
        return 1
    fi
}

# Install missing tools
install_missing_tools() {
    print_header "Instalación de Herramientas"
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_warning "Se requieren permisos de root para instalar paquetes"
        print_info "Intentando usar sudo..."
    fi
    
    # Update package list
    print_info "Actualizando lista de paquetes..."
    if [[ $EUID -eq 0 ]]; then
        apt-get update -qq
    else
        sudo apt-get update -qq
    fi
    
    # Install each missing tool
    for tool in "${MISSING_TOOLS[@]}"; do
        install_tool "$tool"
    done
    
    # Re-verify
    echo ""
    print_info "Verificando instalación..."
    MISSING_TOOLS=()
    INSTALLED_TOOLS=()
    
    # Read tools again
    local tools=()
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        tools+=("$line")
    done < "$REQUIREMENTS_FILE"
    
    # Check again
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            INSTALLED_TOOLS+=("$tool")
        else
            MISSING_TOOLS+=("$tool")
        fi
    done
    
    echo ""
    if [[ ${#MISSING_TOOLS[@]} -eq 0 ]]; then
        print_success "✓ Todas las herramientas instaladas correctamente"
        print_success "✓ Todo listo para iniciar"
    else
        print_warning "Aún faltan algunas herramientas:"
        for tool in "${MISSING_TOOLS[@]}"; do
            echo "  - $tool"
        done
        print_info "Puede que necesites instalarlas manualmente"
    fi
}

# Install a specific tool
install_tool() {
    local tool="$1"
    local package=""
    
    # Map tool names to package names
    case "$tool" in
        arp-scan)
            package="arp-scan"
            ;;
        nmap)
            package="nmap"
            ;;
        ifstat)
            package="ifstat"
            ;;
        gawk)
            package="gawk"
            ;;
        bc)
            package="bc"
            ;;
        perl)
            package="perl"
            ;;
        netstat)
            package="net-tools"
            ;;
        ss)
            package="iproute2"
            ;;
        dig|host)
            package="dnsutils"
            ;;
        ip)
            package="iproute2"
            ;;
        ping|grep|sed|date|sha256sum)
            # These are usually pre-installed
            package="coreutils"
            ;;
        *)
            package="$tool"
            ;;
    esac
    
    print_info "Instalando $tool ($package)..."
    
    if [[ $EUID -eq 0 ]]; then
        apt-get install -y -qq "$package" 2>&1 | grep -v "^Reading\|^Building\|^The following"
    else
        sudo apt-get install -y -qq "$package" 2>&1 | grep -v "^Reading\|^Building\|^The following"
    fi
    
    if [[ $? -eq 0 ]]; then
        print_success "✓ $tool instalado"
    else
        print_error "✗ Error al instalar $tool"
    fi
}

# Run main function
main "$@"
exit $?
