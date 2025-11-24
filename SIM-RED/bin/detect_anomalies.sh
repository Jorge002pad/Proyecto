#!/bin/bash
# SIM-RED EXTENDIDO - Network Anomaly Detection Script
# Feature 11: Detect network anomalies using statistical analysis

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

LOG_FILE="${SCRIPT_DIR}/logs/anomalies.log"

# Main function
main() {
    print_header "Detección de Anomalías de Red"
    
    # Check required tools
    if ! check_required_tools gawk bc; then
        return 1
    fi
    
    # Initialize log
    init_log "$LOG_FILE"
    
    local anomaly_multiplier="${TRAFFIC_ANOMALY_MULTIPLIER:-2.0}"
    
    print_info "Analizando datos históricos..."
    print_info "Umbral de anomalía: ${anomaly_multiplier}x el promedio"
    echo ""
    
    local anomalies_found=false
    
    # Check latency anomalies
    print_separator
    print_color "$CYAN" "Análisis de Latencia"
    print_separator
    echo ""
    
    local latency_history="${SCRIPT_DIR}/data/latency_history.dat"
    
    if [[ -f "$latency_history" ]] && [[ -s "$latency_history" ]]; then
        check_latency_anomalies "$latency_history" "$anomaly_multiplier"
        if [[ $? -ne 0 ]]; then
            anomalies_found=true
        fi
    else
        print_warning "No hay datos históricos de latencia"
    fi
    
    # Check traffic anomalies
    echo ""
    print_separator
    print_color "$CYAN" "Análisis de Tráfico"
    print_separator
    echo ""
    
    local traffic_history="${SCRIPT_DIR}/data/traffic_history.dat"
    
    if [[ -f "$traffic_history" ]] && [[ -s "$traffic_history" ]]; then
        check_traffic_anomalies "$traffic_history" "$anomaly_multiplier"
        if [[ $? -ne 0 ]]; then
            anomalies_found=true
        fi
    else
        print_warning "No hay datos históricos de tráfico"
    fi
    
    # Summary
    echo ""
    print_separator
    
    if [[ "$anomalies_found" == true ]]; then
        print_color "$RED" "⚠ SE DETECTARON ANOMALÍAS EN LA RED"
        print_info "Revisa los logs para más detalles: $LOG_FILE"
    else
        print_color "$GREEN" "✓ NO SE DETECTARON ANOMALÍAS"
    fi
    
    print_separator
    echo ""
    
    press_any_key
}

# Check latency anomalies
check_latency_anomalies() {
    local history_file="$1"
    local multiplier="$2"
    
    # Calculate historical average (last 30 entries, excluding most recent)
    local stats=$(tail -31 "$history_file" | head -30 | awk -F'|' '
    {
        sum += $2
        count++
    }
    END {
        if (count > 0) {
            avg = sum / count
            print avg
        }
    }')
    
    if [[ -z "$stats" ]]; then
        print_warning "Datos insuficientes para análisis"
        return 0
    fi
    
    local historical_avg="$stats"
    
    # Get current latency (most recent entry)
    local current=$(tail -1 "$history_file" | cut -d'|' -f2)
    
    # Compare
    local threshold=$(echo "$historical_avg * $multiplier" | bc)
    local is_anomaly=$(echo "$current > $threshold" | bc)
    
    printf "  Latencia histórica promedio: %.2f ms\n" "$historical_avg"
    printf "  Latencia actual:             %.2f ms\n" "$current"
    printf "  Umbral de anomalía:          %.2f ms\n" "$threshold"
    echo ""
    
    if [[ "$is_anomaly" == "1" ]]; then
        print_error "⚠ ANOMALÍA DETECTADA: La latencia actual es ${multiplier}x mayor que el promedio"
        log_message "ALERT" "Latency anomaly detected: current=$current ms, historical_avg=$historical_avg ms" "$LOG_FILE"
        return 1
    else
        print_success "✓ Latencia dentro de rangos normales"
        return 0
    fi
}

# Check traffic anomalies
check_traffic_anomalies() {
    local history_file="$1"
    local multiplier="$2"
    
    # Get unique interfaces
    local interfaces=$(awk -F'|' '{print $2}' "$history_file" | sort -u)
    
    local anomaly_found=false
    
    for iface in $interfaces; do
        # Calculate historical average for this interface
        local stats=$(grep "|${iface}|" "$history_file" | tail -31 | head -30 | awk -F'|' '
        {
            rx_sum += $3
            tx_sum += $4
            count++
        }
        END {
            if (count > 0) {
                rx_avg = rx_sum / count
                tx_avg = tx_sum / count
                print rx_avg "|" tx_avg
            }
        }')
        
        if [[ -z "$stats" ]]; then
            continue
        fi
        
        local rx_avg=$(echo "$stats" | cut -d'|' -f1)
        local tx_avg=$(echo "$stats" | cut -d'|' -f2)
        
        # Get current traffic
        local current=$(grep "|${iface}|" "$history_file" | tail -1)
        local rx_current=$(echo "$current" | cut -d'|' -f3)
        local tx_current=$(echo "$current" | cut -d'|' -f4)
        
        # Check for anomalies
        local rx_threshold=$(echo "$rx_avg * $multiplier" | bc)
        local tx_threshold=$(echo "$tx_avg * $multiplier" | bc)
        
        local rx_anomaly=$(echo "$rx_current > $rx_threshold" | bc)
        local tx_anomaly=$(echo "$tx_current > $tx_threshold" | bc)
        
        printf "  Interfaz: %s\n" "$iface"
        printf "    RX: actual=%s, promedio=%s, umbral=%s\n" \
            "$(format_bytes $rx_current)" \
            "$(format_bytes ${rx_avg%.*})" \
            "$(format_bytes ${rx_threshold%.*})"
        printf "    TX: actual=%s, promedio=%s, umbral=%s\n" \
            "$(format_bytes $tx_current)" \
            "$(format_bytes ${tx_avg%.*})" \
            "$(format_bytes ${tx_threshold%.*})"
        
        if [[ "$rx_anomaly" == "1" ]] || [[ "$tx_anomaly" == "1" ]]; then
            print_error "    ⚠ ANOMALÍA DETECTADA en $iface"
            log_message "ALERT" "Traffic anomaly on $iface: RX=$rx_current TX=$tx_current" "$LOG_FILE"
            anomaly_found=true
        else
            print_success "    ✓ Tráfico normal"
        fi
        echo ""
    done
    
    if [[ "$anomaly_found" == true ]]; then
        return 1
    else
        return 0
    fi
}

# Run main function
main "$@"
