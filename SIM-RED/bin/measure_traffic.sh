#!/bin/bash
# SIM-RED EXTENDIDO - Script de Medición de Tráfico de Red
# Función 6: Medir tráfico de red por interfaz

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

LOG_FILE="${SCRIPT_DIR}/logs/traffic.log"

# Función principal
main() {
    print_header "Medición de Tráfico de Red"
    
    # Inicializar log
    init_log "$LOG_FILE"
    
    print_info "Selecciona el modo de medición:"
    echo ""
    echo "  1) Medición instantánea"
    echo "  2) Monitoreo continuo (cada minuto)"
    echo ""
    echo -n "Opción: "
    read -r option
    
    case "$option" in
        1)
            measure_instant
            ;;
        2)
            monitor_continuous
            ;;
        *)
            print_error "Opción inválida"
            return 1
            ;;
    esac
}

# Medición instantánea
measure_instant() {
    print_header "Medición Instantánea de Tráfico"
    
    # Obtener interfaces de red
    local interfaces=$(ls /sys/class/net/ 2>/dev/null | grep -v "^lo$")
    
    if [[ -z "$interfaces" ]]; then
        print_error "No se encontraron interfaces de red"
        return 1
    fi
    
    print_separator
    printf "${BOLD}%-15s %15s %15s %15s${NC}\n" \
        "Interfaz" "RX (Bytes)" "TX (Bytes)" "Total"
    print_separator
    
    for iface in $interfaces; do
        local rx_bytes=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo "0")
        local tx_bytes=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo "0")
        local total=$((rx_bytes + tx_bytes))
        
        printf "%-15s %15s %15s %15s\n" \
            "$iface" \
            "$(format_bytes $rx_bytes)" \
            "$(format_bytes $tx_bytes)" \
            "$(format_bytes $total)"
        
        log_message "INFO" "Traffic on $iface: RX=$rx_bytes TX=$tx_bytes" "$LOG_FILE"
    done
    
    print_separator
    echo ""
    
    press_any_key
}

# Monitoreo continuo
monitor_continuous() {
    print_header "Monitoreo Continuo de Tráfico"
    
    print_info "Monitoreando tráfico cada minuto..."
    print_warning "Presiona Ctrl+C para detener"
    echo ""
    
    # Obtener interfaces
    local interfaces=$(ls /sys/class/net/ 2>/dev/null | grep -v "^lo$")
    
    if [[ -z "$interfaces" ]]; then
        print_error "No se encontraron interfaces de red"
        return 1
    fi
    
    # Inicializar valores previos
    declare -A prev_rx
    declare -A prev_tx
    
    for iface in $interfaces; do
        prev_rx[$iface]=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo "0")
        prev_tx[$iface]=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo "0")
    done
    
    trap 'echo ""; print_info "Monitoreo detenido"; exit 0' INT
    
    local iteration=0
    
    while true; do
        sleep 60
        
        clear
        print_header "Monitoreo de Tráfico - Iteración $iteration"
        
        echo "Hora: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Intervalo: 60 segundos"
        echo ""
        
        print_separator
        printf "${BOLD}%-15s %15s %15s %15s${NC}\n" \
            "Interfaz" "RX/min" "TX/min" "Total/min"
        print_separator
        
        for iface in $interfaces; do
            local curr_rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo "0")
            local curr_tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo "0")
            
            local rx_rate=$((curr_rx - prev_rx[$iface]))
            local tx_rate=$((curr_tx - prev_tx[$iface]))
            local total_rate=$((rx_rate + tx_rate))
            
            printf "%-15s %15s %15s %15s\n" \
                "$iface" \
                "$(format_bytes $rx_rate)" \
                "$(format_bytes $tx_rate)" \
                "$(format_bytes $total_rate)"
            
            # Actualizar valores previos
            prev_rx[$iface]=$curr_rx
            prev_tx[$iface]=$curr_tx
            
            # Registrar
            log_message "INFO" "Traffic rate on $iface: RX=$rx_rate/min TX=$tx_rate/min" "$LOG_FILE"
            
            # Guardar en historial
            local history_file="${SCRIPT_DIR}/data/traffic_history.dat"
            ensure_dir "${SCRIPT_DIR}/data"
            echo "$(date +%s)|$iface|$rx_rate|$tx_rate" >> "$history_file"
        done
        
        print_separator
        
        ((iteration++))
    done
}

# Ejecutar función principal
main "$@"
