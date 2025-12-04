#!/bin/bash
# SIM-RED EXTENDIDO - Script de Monitoreo ARP en Tiempo Real
# Función 7: Monitorear tabla ARP en tiempo real

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/arp.log"
ARP_FILE="/proc/net/arp"

# Función principal
main() {
    print_header "Monitoreo ARP en Tiempo Real"
    
    # Verificar si el archivo ARP existe
    if [[ ! -f "$ARP_FILE" ]]; then
        print_error "No se puede acceder a $ARP_FILE"
        return 1
    fi
    
    # Inicializar log
    init_log "$LOG_FILE"
    
    print_info "Monitoreando tabla ARP en tiempo real..."
    print_warning "Presiona Ctrl+C para detener"
    echo ""
    
    # Cargar hosts autorizados
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    
    # Almacenar estado ARP previo
    local prev_arp=$(cat "$ARP_FILE" 2>/dev/null)
    
    trap 'echo ""; print_info "Monitoreo detenido"; exit 0' INT
    
    local iteration=0
    
    while true; do
        sleep 5
        
        # Obtener tabla ARP actual
        local curr_arp=$(cat "$ARP_FILE" 2>/dev/null)
        
        # Comparar con la anterior
        if [[ "$curr_arp" != "$prev_arp" ]]; then
            echo ""
            print_color "$YELLOW" "[$(date '+%H:%M:%S')] Cambio detectado en tabla ARP"
            
            # Encontrar nuevas entradas
            while read -r line; do
                if ! echo "$prev_arp" | grep -qF "$line"; then
                    local ip=$(echo "$line" | awk '{print $1}')
                    local mac=$(echo "$line" | awk '{print $4}')
                    
                    if [[ "$ip" != "IP" ]] && [[ "$mac" != "00:00:00:00:00:00" ]]; then
                        # Verificar si está autorizada
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
            
            # Encontrar entradas eliminadas
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

# Ejecutar función principal
main "$@"
