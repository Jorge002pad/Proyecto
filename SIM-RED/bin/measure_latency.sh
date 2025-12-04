#!/bin/bash
# SIM-RED EXTENDIDO - Script de Medición de Latencia Promedio
# Función 4: Medir latencia promedio de red para todos los hosts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/latency.log"

# Función principal
main() {
    print_header "Medición de Latencia Promedio de la Red"
    
    # Verificar herramientas requeridas
    if ! check_required_tools ping gawk bc; then
        return 1
    fi
    
    # Inicializar log
    init_log "$LOG_FILE"
    
    # Cargar hosts autorizados
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    if ! check_file "$hosts_file"; then
        return 1
    fi
    
    print_info "Midiendo latencia de todos los hosts autorizados..."
    echo ""
    
    # Archivo temporal para resultados
    local temp_file=$(mktemp)
    
    # Medir latencia para cada host
    while IFS='|' read -r ip mac hostname desc; do
        measure_host_latency "$ip" "$hostname" >> "$temp_file"
    done < <(load_authorized_hosts "$hosts_file")
    
    # Ordenar por latencia promedio
    echo ""
    print_separator
    printf "${BOLD}%-15s %-15s %10s %10s %10s %10s${NC}\n" \
        "IP" "Hostname" "Mín (ms)" "Prom (ms)" "Máx (ms)" "Desv"
    print_separator
    
    sort -t'|' -k3 -n "$temp_file" | while IFS='|' read -r ip hostname min avg max mdev status; do
        local color="$GREEN"
        
        # Color basado en latencia promedio
        local avg_int=$(echo "$avg" | cut -d'.' -f1)
        if [[ $avg_int -gt 100 ]]; then
            color="$RED"
        elif [[ $avg_int -gt 50 ]]; then
            color="$YELLOW"
        fi
        
        printf "${color}%-15s %-15s %10s %10s %10s %10s${NC}\n" \
            "$ip" "$hostname" "$min" "$avg" "$max" "$mdev"
    done
    
    print_separator
    echo ""
    
    # Calcular estadísticas de red
    print_color "$CYAN" "ESTADÍSTICAS DE LA RED:"
    print_separator
    
    local stats=$(awk -F'|' '
    BEGIN {
        count = 0
        sum = 0
        min = 999999
        max = 0
    }
    {
        if ($3 != "" && $3 != "N/A") {
            avg = $3
            sum += avg
            count++
            if (avg < min) min = avg
            if (avg > max) max = avg
            values[count] = avg
        }
    }
    END {
        if (count > 0) {
            mean = sum / count
            
            # Calcular desviación estándar
            sum_sq = 0
            for (i = 1; i <= count; i++) {
                diff = values[i] - mean
                sum_sq += diff * diff
            }
            stddev = sqrt(sum_sq / count)
            
            printf "%.2f|%.2f|%.2f|%.2f|%d\n", min, mean, max, stddev, count
        }
    }' "$temp_file")
    
    if [[ -n "$stats" ]]; then
        local net_min=$(echo "$stats" | cut -d'|' -f1)
        local net_avg=$(echo "$stats" | cut -d'|' -f2)
        local net_max=$(echo "$stats" | cut -d'|' -f3)
        local net_std=$(echo "$stats" | cut -d'|' -f4)
        local net_count=$(echo "$stats" | cut -d'|' -f5)
        
        echo ""
        printf "  Hosts medidos:        %d\n" $net_count
        printf "  Latencia mínima:      %.2f ms\n" $net_min
        printf "  Latencia promedio:    %.2f ms\n" $net_avg
        printf "  Latencia máxima:      %.2f ms\n" $net_max
        printf "  Desviación estándar:  %.2f ms\n" $net_std
        echo ""
        
        # Guardar en historial
        local history_file="${SCRIPT_DIR}/data/latency_history.dat"
        ensure_dir "${SCRIPT_DIR}/data"
        echo "$(date +%s)|$net_avg|$net_min|$net_max|$net_std" >> "$history_file"
        
        # Registrar resultados
        log_message "INFO" "Network latency: avg=$net_avg ms, min=$net_min ms, max=$net_max ms, stddev=$net_std ms" "$LOG_FILE"
    fi
    
    # Limpiar
    rm -f "$temp_file"
    
    press_any_key
}

# Medir latencia para un host individual
measure_host_latency() {
    local ip="$1"
    local hostname="$2"
    
    # Hacer ping al host
    local result=$(ping_host "$ip" 10)
    
    if [[ -n "$result" ]]; then
        local min=$(echo "$result" | cut -d'|' -f1)
        local avg=$(echo "$result" | cut -d'|' -f2)
        local max=$(echo "$result" | cut -d'|' -f3)
        local mdev=$(echo "$result" | cut -d'|' -f4)
        
        # Determinar estado
        local status="OK"
        local avg_int=$(echo "$avg" | cut -d'.' -f1)
        
        if [[ $avg_int -gt 100 ]]; then
            status="HIGH"
        elif [[ $avg_int -gt 50 ]]; then
            status="MEDIUM"
        fi
        
        echo "$ip|$hostname|$avg|$min|$max|$mdev|$status"
        
        # Registrar
        log_message "INFO" "Latency for $ip ($hostname): avg=$avg ms" "$LOG_FILE"
    else
        echo "$ip|$hostname|N/A|N/A|N/A|N/A|UNREACHABLE"
        log_message "WARNING" "Host unreachable: $ip ($hostname)" "$LOG_FILE"
    fi
}

# Ejecutar función principal
main "$@"
