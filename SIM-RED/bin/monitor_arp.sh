#!/bin/bash
# SIM-RED EXTENDIDO - Real-time ARP Monitoring Script
# Feature 7: Monitor ARP table in real-time

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/arp.log"
ARP_FILE="/proc/net/arp"

# Main function
main() {
    print_header "Monitoreo ARP en Tiempo Real"
    
    # Check if ARP file exists
    if [[ ! -f "$ARP_FILE" ]]; then
        print_error "No se puede acceder a $ARP_FILE"
        return 1
    fi
    
    # Initialize log
    init_log "$LOG_FILE"
    
    print_info "Monitoreando tabla ARP en tiempo real..."
    print_warning "Presiona Ctrl+C para detener"
    echo ""
    
    # Load authorized hosts
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    
    # Store previous ARP state
    local prev_arp=$(cat "$ARP_FILE" 2>/dev/null)
    
    trap 'echo ""; print_info "Monitoreo detenido"; exit 0' INT
    
    local iteration=0
    
    while true; do
        sleep 5
        
        # Get current ARP table
        local curr_arp=$(cat "$ARP_FILE" 2>/dev/null)
        
        # Compare with previous
        if [[ "$curr_arp" != "$prev_arp" ]]; then
            echo ""
            print_color "$YELLOW" "[$(date '+%H:%M:%S')] Cambio detectado en tabla ARP"
            
            # Find new entries
            while read -r line; do
                if ! echo "$prev_arp" | grep -qF "$line"; then
                    local ip=$(echo "$line" | awk '{print $1}')
                    local mac=$(echo "$line" | awk '{print $4}')
                    
                    if [[ "$ip" != "IP" ]] && [[ "$mac" != "00:00:00:00:00:00" ]]; then
                        # Check if authorized
                        if is_authorized_mac "$mac" "$hosts_file"; then
                            print_success "Nueva entrada (autorizada): $ip -> $mac"
                            log_message "INFO" "New authorized ARP entry: $ip -> $mac" "$LOG_FILE"
                        else
                            print_warning "Nueva entrada (desconocida): $ip -> $mac"
                            log_message "ALERT" "New unknown ARP entry: $ip -> $mac" "$LOG_FILE"
                        fi
                    fi
                fi
            done <<< "$curr_arp"
            
            # Find removed entries
            while read -r line; do
                if ! echo "$curr_arp" | grep -qF "$line"; then
                    local ip=$(echo "$line" | awk '{print $1}')
                    local mac=$(echo "$line" | awk '{print $4}')
                    
                    if [[ "$ip" != "IP" ]] && [[ "$mac" != "00:00:00:00:00:00" ]]; then
                        print_info "Entrada eliminada: $ip -> $mac"
                        log_message "INFO" "ARP entry removed: $ip -> $mac" "$LOG_FILE"
                    fi
                fi
            done <<< "$prev_arp"
            
            prev_arp="$curr_arp"
        fi
        
        ((iteration++))
    done
}

# Run main function
main "$@"
