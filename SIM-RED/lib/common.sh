#!/bin/bash
# SIM-RED EXTENDIDO - Common Functions Library
# This file contains shared utility functions used across all scripts

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load configuration
CONFIG_FILE="${SCRIPT_DIR}/config/config.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Color codes
if [[ "$USE_COLORS" == "yes" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''
    BOLD=''
    NC=''
fi

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local log_file="${3:-${SCRIPT_DIR}/logs/system.log}"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$log_file"
}

# Print colored message
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Print success message
print_success() {
    print_color "$GREEN" "✓ $1"
    log_message "INFO" "$1"
}

# Print error message
print_error() {
    print_color "$RED" "✗ $1"
    log_message "ERROR" "$1"
}

# Print warning message
print_warning() {
    print_color "$YELLOW" "⚠ $1"
    log_message "WARNING" "$1"
}

# Print info message
print_info() {
    print_color "$BLUE" "ℹ $1"
}

# Print header
print_header() {
    local title="$1"
    echo ""
    print_color "$CYAN" "═══════════════════════════════════════════════════════════════"
    print_color "$CYAN" "  $title"
    print_color "$CYAN" "═══════════════════════════════════════════════════════════════"
    echo ""
}

# Print separator
print_separator() {
    print_color "$CYAN" "───────────────────────────────────────────────────────────────"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root (sudo)"
        return 1
    fi
    return 0
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a file exists and is readable
check_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        print_error "Archivo no encontrado: $file"
        return 1
    fi
    if [[ ! -r "$file" ]]; then
        print_error "No se puede leer el archivo: $file"
        return 1
    fi
    return 0
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            print_error "No se pudo crear el directorio: $dir"
            return 1
        fi
    fi
    return 0
}

# Validate IP address
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if ((octet > 255)); then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Validate MAC address
validate_mac() {
    local mac="$1"
    if [[ $mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        return 0
    fi
    return 1
}

# Auto-detect active network interface
detect_network_interface() {
    # Try to find the default route interface
    local iface=$(ip route | grep default | awk '{print $5}' | head -n 1)
    
    # If no default route, try to find first active interface (excluding loopback)
    if [[ -z "$iface" ]]; then
        iface=$(ip link show | grep -E "^[0-9]+: (eth|enp|wlan|wlp)" | head -n 1 | awk -F': ' '{print $2}')
    fi
    
    echo "$iface"
}

# Auto-detect network subnet
detect_network_subnet() {
    local iface="${1:-$(detect_network_interface)}"
    
    if [[ -z "$iface" ]]; then
        return 1
    fi
    
    # Get IP and CIDR from interface
    local subnet=$(ip -4 addr show "$iface" 2>/dev/null | grep inet | awk '{print $2}' | head -n 1)
    
    if [[ -z "$subnet" ]]; then
        return 1
    fi
    
    # Extract network address from IP/CIDR
    local ip=$(echo "$subnet" | cut -d'/' -f1)
    local cidr=$(echo "$subnet" | cut -d'/' -f2)
    
    # Calculate network address
    local network=$(ipcalc -n "$ip/$cidr" 2>/dev/null | grep Network | awk '{print $2}')
    
    # Fallback if ipcalc is not available
    if [[ -z "$network" ]]; then
        # Simple calculation for /24 networks
        if [[ "$cidr" == "24" ]]; then
            network=$(echo "$ip" | awk -F. '{print $1"."$2"."$3".0/24"}')
        else
            # For other CIDR, just use the IP with CIDR
            network="$ip/$cidr"
        fi
    fi
    
    echo "$network"
}

# Get current network gateway
detect_network_gateway() {
    local gateway=$(ip route | grep default | awk '{print $3}' | head -n 1)
    echo "$gateway"
}

# Auto-detect and display network configuration
auto_detect_network() {
    local show_output="${1:-yes}"
    
    local iface=$(detect_network_interface)
    local subnet=$(detect_network_subnet "$iface")
    local gateway=$(detect_network_gateway)
    local my_ip=$(hostname -I | awk '{print $1}')
    
    if [[ "$show_output" == "yes" ]]; then
        print_header "Auto-Detección de Red"
        echo ""
        print_info "Interfaz de red detectada: ${CYAN}$iface${NC}"
        print_info "Tu dirección IP: ${CYAN}$my_ip${NC}"
        print_info "Gateway (Router): ${CYAN}$gateway${NC}"
        print_info "Rango de red (Subnet): ${CYAN}$subnet${NC}"
        echo ""
    fi
    
    # Export variables for use in scripts
    export DETECTED_INTERFACE="$iface"
    export DETECTED_SUBNET="$subnet"
    export DETECTED_GATEWAY="$gateway"
    export DETECTED_IP="$my_ip"
    
    # Update config if different from current
    if [[ -n "$subnet" && "$subnet" != "$SUBNET" ]]; then
        if [[ "$show_output" == "yes" ]]; then
            print_warning "La configuración actual ($SUBNET) difiere de la red detectada ($subnet)"
            
            if ask_yes_no "¿Deseas actualizar la configuración automáticamente?" "y"; then
                update_network_config "$iface" "$subnet"
            fi
        fi
    fi
    
    return 0
}

# Update network configuration in config.conf
update_network_config() {
    local new_iface="$1"
    local new_subnet="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Archivo de configuración no encontrado: $CONFIG_FILE"
        return 1
    fi
    
    # Backup config file
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    # Update SUBNET
    if grep -q "^SUBNET=" "$CONFIG_FILE"; then
        sed -i "s|^SUBNET=.*|SUBNET=\"$new_subnet\"|" "$CONFIG_FILE"
    else
        echo "SUBNET=\"$new_subnet\"" >> "$CONFIG_FILE"
    fi
    
    # Update NETWORK_INTERFACE
    if grep -q "^NETWORK_INTERFACE=" "$CONFIG_FILE"; then
        sed -i "s|^NETWORK_INTERFACE=.*|NETWORK_INTERFACE=\"$new_iface\"|" "$CONFIG_FILE"
    else
        echo "NETWORK_INTERFACE=\"$new_iface\"" >> "$CONFIG_FILE"
    fi
    
    print_success "Configuración actualizada correctamente"
    print_info "Backup guardado en: ${CONFIG_FILE}.bak"
    
    # Reload configuration
    source "$CONFIG_FILE"
    
    return 0
}

# Press any key to continue
press_any_key() {
    echo ""
    print_color "$YELLOW" "Presiona cualquier tecla para continuar..."
    read -n 1 -s
}

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        local prompt="[S/n]"
    else
        local prompt="[s/N]"
    fi
    
    while true; do
        echo -ne "${YELLOW}${question} ${prompt}: ${NC}"
        read -r response
        
        # Use default if empty
        if [[ -z "$response" ]]; then
            response="$default"
        fi
        
        case "${response,,}" in
            s|y|yes|si)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                print_warning "Por favor responde 's' o 'n'"
                ;;
        esac
    done
}

# Get current timestamp
get_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes}B"
    elif ((bytes < 1048576)); then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}")KB"
    elif ((bytes < 1073741824)); then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}")MB"
    else
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}")GB"
    fi
}

# Check required tools for a specific feature
check_required_tools() {
    local -a tools=("$@")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Herramientas faltantes: ${missing[*]}"
        print_warning "Ejecuta la opción 15 del menú para verificar e instalar herramientas"
        return 1
    fi
    
    return 0
}

# Initialize log file
init_log() {
    local log_file="$1"
    local log_dir=$(dirname "$log_file")
    
    ensure_dir "$log_dir"
    
    if [[ ! -f "$log_file" ]]; then
        touch "$log_file" 2>/dev/null
    fi
}

# Export functions for use in subshells
export -f log_message
export -f print_color
export -f print_success
export -f print_error
export -f print_warning
export -f print_info
export -f print_header
export -f print_separator
export -f command_exists
export -f validate_ip
export -f validate_mac
export -f detect_network_interface
export -f detect_network_subnet
export -f detect_network_gateway
export -f auto_detect_network
export -f update_network_config
