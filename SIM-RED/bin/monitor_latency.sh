#!/bin/bash
# SIM-RED EXTENDIDO - Continuous Latency Monitoring Script
# Feature 5: Real-time latency monitoring with ASCII graphs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/latency.log"
GRAPH_AWK="${SCRIPT_DIR}/lib/graph_ascii.awk"

# Main function
main() {
    print_header "Monitoreo Continuo de Latencia"
    
    # Check required tools
    if ! check_required_tools ping gawk; then
        return 1
    fi
    
    # Initialize log
    init_log "$LOG_FILE"
    
    # Load authorized hosts
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    if ! check_file "$hosts_file"; then
        return 1
    fi
    
    # Get alert threshold
    local threshold=${LATENCY_ALERT_MS:-200}
    
    print_info "Monitoreando latencia en tiempo real..."
    print_info "Umbral de alerta: ${threshold} ms"
    print_warning "Presiona Ctrl+C para detener"
    echo ""
    
    # Select hosts to monitor (limit to first 5 for display)
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
    
    # Initialize data arrays
    local -A latency_history
    local max_history=60  # Keep last 60 measurements
    
    for ip in "${monitor_ips[@]}"; do
        latency_history[$ip]=""
    done
    
    # Monitoring loop
    local iteration=0
    
    trap 'echo ""; print_info "Monitoreo detenido"; exit 0' INT
    
    while true; do
        clear
        print_header "Monitoreo Continuo de Latencia - Iteración $iteration"
        
        echo "Hora: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Umbral de alerta: ${threshold} ms"
        echo ""
        
        # Measure latency for each host
        for i in "${!monitor_ips[@]}"; do
            local ip="${monitor_ips[$i]}"
            local hostname="${monitor_names[$i]}"
            
            # Ping once
            local latency=$(ping -c 1 -W 2 "$ip" 2>/dev/null | \
                grep -oP 'time=\K[0-9.]+' | head -1)
            
            if [[ -n "$latency" ]]; then
                # Add to history
                latency_history[$ip]="${latency_history[$ip]} $latency"
                
                # Keep only last max_history values
                local -a values=(${latency_history[$ip]})
                if [[ ${#values[@]} -gt $max_history ]]; then
                    latency_history[$ip]="${values[@]: -$max_history}"
                fi
                
                # Display current value
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
        
        # Display ASCII graph for first host
        if [[ ${#monitor_ips[@]} -gt 0 ]]; then
            local first_ip="${monitor_ips[0]}"
            local first_name="${monitor_names[0]}"
            
            echo ""
            print_color "$CYAN" "Gráfica de latencia: $first_name ($first_ip)"
            echo ""
            
            # Prepare data for graphing
            local values="${latency_history[$first_ip]}"
            
            if [[ -n "$values" ]]; then
                # Use AWK to generate graph
                echo "$values" | tr ' ' '\n' | grep -v '^$' | \
                    gawk -v type=line -v width=60 -v height=10 -f "$GRAPH_AWK" 2>/dev/null || \
                    {
                        # Fallback simple graph
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

# Run main function
main "$@"
