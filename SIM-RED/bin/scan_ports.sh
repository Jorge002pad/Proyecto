#!/bin/bash
# SIM-RED EXTENDIDO - Port Scanning Script
# Feature 9: Scan important ports on authorized hosts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/ports.log"

# Main function
main() {
    print_header "Escaneo de Puertos Importantes"
    
    # Check required tools
    if ! check_required_tools nmap; then
        return 1
    fi
    
    # Initialize log
    init_log "$LOG_FILE"
    
    # Load authorized hosts
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    if ! check_file "$hosts_file"; then
        return 1
    fi
    
    # Get ports to scan from config
    local ports="${PORTS_TO_SCAN:-22,80,443,3306,5432,8080}"
    local nmap_speed="${NMAP_SPEED:--T4}"
    
    print_info "Escaneando puertos: $ports"
    print_info "Velocidad de escaneo: $nmap_speed"
    echo ""
    
    print_separator
    printf "${BOLD}%-15s %-15s %-10s %-20s %s${NC}\n" \
        "IP" "Hostname" "Puerto" "Servicio" "Estado"
    print_separator
    
    # Scan each authorized host
    while IFS='|' read -r ip mac hostname desc; do
        scan_host "$ip" "$hostname" "$ports" "$nmap_speed"
    done < <(load_authorized_hosts "$hosts_file")
    
    print_separator
    echo ""
    
    press_any_key
}

# Scan a single host
scan_host() {
    local ip="$1"
    local hostname="$2"
    local ports="$3"
    local speed="$4"
    
    # Run nmap
    local scan_result=$(nmap -p "$ports" $speed --open "$ip" 2>/dev/null | \
        grep -E "^[0-9]+/(tcp|udp)")
    
    if [[ -z "$scan_result" ]]; then
        printf "%-15s %-15s %-10s %-20s %s\n" \
            "$ip" "$hostname" "-" "-" "${GREEN}Sin puertos abiertos${NC}"
        log_message "INFO" "No open ports found on $ip ($hostname)" "$LOG_FILE"
    else
        local first=true
        
        while read -r line; do
            local port=$(echo "$line" | awk '{print $1}' | cut -d'/' -f1)
            local service=$(echo "$line" | awk '{print $3}')
            
            # Determine if port is expected
            local status="${GREEN}ESPERADO${NC}"
            
            # Flag unexpected services
            case "$service" in
                ssh|http|https|mysql|postgresql)
                    status="${GREEN}ESPERADO${NC}"
                    ;;
                *)
                    status="${YELLOW}REVISAR${NC}"
                    ;;
            esac
            
            if [[ "$first" == true ]]; then
                printf "%-15s %-15s %-10s %-20s %s\n" \
                    "$ip" "$hostname" "$port" "$service" "$status"
                first=false
            else
                printf "%-15s %-15s %-10s %-20s %s\n" \
                    "" "" "$port" "$service" "$status"
            fi
            
            log_message "INFO" "Open port on $ip ($hostname): $port/$service" "$LOG_FILE"
        done <<< "$scan_result"
    fi
}

# Run main function
main "$@"
