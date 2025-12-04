#!/bin/bash
# SIM-RED EXTENDIDO - Script de Monitoreo Continuo de Latencia
# Función 5: Monitoreo de latencia en tiempo real con gráficas ASCII

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/latency.log"
GRAPH_AWK="${SCRIPT_DIR}/lib/graph_ascii.awk"

# Función principal
main() {
    print_header "Monitoreo Continuo de Latencia"
    
    # Verificar herramientas requeridas
    if ! check_required_tools ping gawk; then
        return 1
    fi
    
    # Inicializar log
    init_log "$LOG_FILE"
    
    # Cargar hosts autorizados
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    if ! check_file "$hosts_file"; then
        return 1
    fi
    
    # Obtener umbral de alerta
    local threshold=${LATENCY_ALERT_MS:-200}
    
    print_info "Monitoreando latencia en tiempo real..."
    print_info "Umbral de alerta: ${threshold} ms"
    print_warning "Presiona Ctrl+C para detener"
    echo ""
    
    # Seleccionar hosts a monitorear (limitar a los primeros 5 para visualización)
    local -a monitor_ips=()
    local -a monitor_names=()
    local count=0
    
    while IFS='|' read -r ip mac hostname desc && [[ $count -lt 5 ]]; do
        monitor_ips+=("$ip")
        monitor_names+=("$hostname")
        ((count++))
    done < <(load_authorized_hosts "$hosts_file")
    
    if [[ ${#monitor_ips[@]} -eq 0 ]]; then
        print_error "No hay hosts para monitorear"
        return 1
    fi
    
    # Inicializar arrays de datos
    local -A latency_history
    local max_history=60  # Mantener últimas 60 mediciones
    
    for ip in "${monitor_ips[@]}"; do
        latency_history[$ip]=""
    done
    
    # Bucle de monitoreo
    local iteration=0
    
    trap 'echo ""; print_info "Monitoreo detenido"; exit 0' INT
    
    while true; do
        clear
        print_header "Monitoreo Continuo de Latencia - Iteración $iteration"
        
        echo "Hora: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Umbral de alerta: ${threshold} ms"
        echo ""
        
        # Medir latencia para cada host
        for i in "${!monitor_ips[@]}"; do
            local ip="${monitor_ips[$i]}"
            local hostname="${monitor_names[$i]}"
            
            # Hacer ping una vez
            local latency=$(ping -c 1 -W 2 "$ip" 2>/dev/null | \
                grep -oP 'time=\K[0-9.]+' | head -1)
            
            if [[ -n "$latency" ]]; then
                # Agregar al historial
                latency_history[$ip]="${latency_history[$ip]} $latency"
                
                # Mantener solo los últimos max_history valores
                local -a values=(${latency_history[$ip]})
                if [[ ${#values[@]} -gt $max_history ]]; then
                    latency_history[$ip]="${values[@]: -$max_history}"
                fi
                
                # Mostrar valor actual
                local color="$GREEN"
                local status="OK"
                
                local lat_int=$(echo "$latency" | cut -d'.' -f1)
                if [[ $lat_int -gt $threshold ]]; then
                    color="$RED"
                    status="⚠ ALERT"
                    log_message "ALERT" "High latency detected on $ip ($hostname): $latency ms" "$LOG_FILE"
                elif [[ $lat_int -gt $((threshold / 2)) ]]; then
                    color="$YELLOW"
                    status="WARNING"
                fi
                
                printf "${color}%-15s %-15s %8.2f ms  %s${NC}\n" \
                    "$ip" "$hostname" "$latency" "$status"
            else
                printf "${RED}%-15s %-15s %8s     %s${NC}\n" \
                    "$ip" "$hostname" "N/A" "UNREACHABLE"
            fi
        done
        
        echo ""
        print_separator
        
        # Mostrar gráfica ASCII para el primer host
        if [[ ${#monitor_ips[@]} -gt 0 ]]; then
            local first_ip="${monitor_ips[0]}"
            local first_name="${monitor_names[0]}"
            
            echo ""
            print_color "$CYAN" "Gráfica de latencia: $first_name ($first_ip)"
            echo ""
            
            # Preparar datos para graficar
            local values="${latency_history[$first_ip]}"
            
            if [[ -n "$values" ]]; then
                # Usar AWK para generar gráfica
                echo "$values" | tr ' ' '\n' | grep -v '^$' | \
                    gawk -v type=line -v width=60 -v height=10 -f "$GRAPH_AWK" 2>/dev/null || \
                    {
                        # Gráfica simple de respaldo
                        echo "$values" | tr ' ' '\n' | tail -20 | while read val; do
                            local bars=$(echo "$val / 5" | bc 2>/dev/null || echo "1")
                            printf "%6.1f ms |" "$val"
                            for ((b=0; b<bars && b<40; b++)); do
                                printf "█"
                            done
                            echo ""
                        done
                    }
            fi
        fi
        
        ((iteration++))
        sleep 1
    done
}

# Ejecutar función principal
main "$@"
