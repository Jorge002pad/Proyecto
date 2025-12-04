#!/bin/bash
# SIM-RED EXTENDIDO - Script de Verificación de Dispositivos
# Función 1: Verificar dispositivos conectados contra lista autorizada y horarios

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/devices.log"

# Función principal
main() {
    print_header "Verificación de Dispositivos Conectados"
    
    # Verificar herramientas requeridas
    if ! check_required_tools arp-scan gawk; then
        return 1
    fi
    
    # Verificar si se ejecuta como root (necesario para arp-scan)
    if ! check_root; then
        return 1
    fi
    
    # Inicializar log
    init_log "$LOG_FILE"
    
    # Obtener información de red actual
    local subnet=$(get_local_subnet)
    print_info "Escaneando subred: $subnet"
    echo ""
    
    # Escanear red
    print_info "Escaneando red..."
    local arp_data=$(get_arp_table)
    
    if [[ -z "$arp_data" ]]; then
        print_error "No se pudieron obtener datos de la red"
        return 1
    fi
    
    # Cargar hosts autorizados
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    local schedule_file="${SCRIPT_DIR}/config/schedule.conf"
    
    if ! check_file "$hosts_file"; then
        return 1
    fi
    
    # Analizar dispositivos
    echo ""
    print_separator
    print_color "$CYAN" "DISPOSITIVOS ENCONTRADOS:"
    print_separator
    echo ""
    
    local authorized_count=0
    local unknown_count=0
    local unauthorized_count=0
    
    # Procesar cada dispositivo encontrado
    while IFS='|' read -r ip mac; do
        analyze_device "$ip" "$mac" "$hosts_file" "$schedule_file"
        local status=$?
        
        case $status in
            0) ((authorized_count++)) ;;
            1) ((unknown_count++)) ;;
            2) ((unauthorized_count++)) ;;
        esac
    done <<< "$arp_data"
    
    # Verificar dispositivos autorizados que NO están conectados
    echo ""
    print_separator
    print_color "$CYAN" "DISPOSITIVOS AUTORIZADOS NO CONECTADOS:"
    print_separator
    echo ""
    
    local disconnected_count=0
    while IFS='|' read -r auth_ip auth_mac auth_hostname auth_desc; do
        # Verificar si esta IP fue encontrada en el escaneo
        if ! echo "$arp_data" | grep -q "^${auth_ip}|"; then
            printf "  ${YELLOW}%-15s %-20s %-15s${NC} [DESCONECTADO]\n" \
                "$auth_ip" "$auth_mac" "$auth_hostname"
            ((disconnected_count++))
        fi
    done < <(load_authorized_hosts "$hosts_file")
    
    if [[ $disconnected_count -eq 0 ]]; then
        print_info "Todos los dispositivos autorizados están conectados"
    fi
    
    # Resumen
    echo ""
    print_separator
    print_color "$BOLD" "RESUMEN:"
    print_separator
    echo ""
    printf "  ${GREEN}✓ Autorizados y en horario:${NC}  %d\n" $authorized_count
    printf "  ${YELLOW}⚠ Desconocidos:${NC}              %d\n" $unknown_count
    printf "  ${RED}✗ No autorizados/fuera de horario:${NC} %d\n" $unauthorized_count
    printf "  ${BLUE}○ Autorizados desconectados:${NC} %d\n" $disconnected_count
    echo ""
    
    # Registrar resumen
    log_message "INFO" "Scan completed: $authorized_count authorized, $unknown_count unknown, $unauthorized_count unauthorized" "$LOG_FILE"
    
    press_any_key
}

# Analizar un dispositivo individual
analyze_device() {
    local ip="$1"
    local mac="$2"
    local hosts_file="$3"
    local schedule_file="$4"
    
    # Verificar si la IP está autorizada
    if is_authorized_ip "$ip" "$hosts_file"; then
        local auth_mac=$(get_authorized_mac "$ip" "$hosts_file")
        local hostname=$(get_hostname_for_ip "$ip" "$hosts_file")
        
        # Verificar si la MAC coincide
        if [[ "${mac,,}" != "${auth_mac,,}" ]]; then
            printf "  ${RED}%-15s %-20s %-15s${NC} [MAC NO COINCIDE: esperado %s]\n" \
                "$ip" "$mac" "$hostname" "$auth_mac"
            log_message "WARNING" "MAC mismatch for $ip: found $mac, expected $auth_mac" "$LOG_FILE"
            return 2
        fi
        
        # Verificar horario
        local schedule_status=$(check_schedule "$ip" "$schedule_file")
        
        case "$schedule_status" in
            "ALLOWED")
                printf "  ${GREEN}%-15s %-20s %-15s${NC} [✓ AUTORIZADO]\n" \
                    "$ip" "$mac" "$hostname"
                log_message "INFO" "Authorized device: $ip ($hostname)" "$LOG_FILE"
                return 0
                ;;
            "WRONG_DAY")
                printf "  ${YELLOW}%-15s %-20s %-15s${NC} [⚠ FUERA DE DÍA]\n" \
                    "$ip" "$mac" "$hostname"
                log_message "WARNING" "Device outside allowed days: $ip ($hostname)" "$LOG_FILE"
                return 2
                ;;
            "WRONG_TIME")
                printf "  ${YELLOW}%-15s %-20s %-15s${NC} [⚠ FUERA DE HORARIO]\n" \
                    "$ip" "$mac" "$hostname"
                log_message "WARNING" "Device outside allowed hours: $ip ($hostname)" "$LOG_FILE"
                return 2
                ;;
            "NO_SCHEDULE")
                printf "  ${YELLOW}%-15s %-20s %-15s${NC} [⚠ SIN HORARIO DEFINIDO]\n" \
                    "$ip" "$mac" "$hostname"
                log_message "WARNING" "No schedule defined for: $ip ($hostname)" "$LOG_FILE"
                return 2
                ;;
        esac
    else
        # Dispositivo desconocido
        printf "  ${RED}%-15s %-20s %-15s${NC} [✗ DESCONOCIDO]\n" \
            "$ip" "$mac" "???"
        log_message "ALERT" "Unknown device detected: $ip ($mac)" "$LOG_FILE"
        return 1
    fi
}

# Ejecutar función principal
main "$@"
