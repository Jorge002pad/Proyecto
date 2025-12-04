#!/bin/bash
# SIM-RED EXTENDIDO - Script de Detección de VPN/Proxy
# Función 3: Detectar si los usuarios están usando VPN o Proxy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/vpn.log"

# Función principal
main() {
    print_header "Detección de VPN/Proxy"
    
    # Verificar herramientas requeridas
    if ! check_required_tools ping nmap gawk; then
        return 1
    fi
    
    # Inicializar log
    init_log "$LOG_FILE"
    
    # Cargar hosts autorizados
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    if ! check_file "$hosts_file"; then
        return 1
    fi
    
    print_info "Analizando hosts autorizados para detectar uso de VPN/Proxy..."
    echo ""
    
    print_separator
    printf "%-15s %-15s %-40s %s\n" "IP" "Hostname" "Indicadores" "Probabilidad"
    print_separator
    
    # Analizar cada host autorizado
    while IFS='|' read -r ip mac hostname desc; do
        analyze_host_for_vpn "$ip" "$hostname"
    done < <(load_authorized_hosts "$hosts_file")
    
    print_separator
    echo ""
    
    press_any_key
}

# Analizar un host para indicadores de VPN/Proxy
analyze_host_for_vpn() {
    local ip="$1"
    local hostname="$2"
    local indicators=()
    local score=0
    
    # Prueba 1: Verificar variaciones de TTL
    local ttl=$(get_ttl "$ip")
    
    if [[ -n "$ttl" ]]; then
        # TTLs normales: 64 (Linux), 128 (Windows), 255 (Dispositivos de red)
        # VPN podría mostrar TTLs inusuales o variaciones
        
        # Almacenar historial de TTL
        local ttl_history_file="${SCRIPT_DIR}/data/ttl_history_${ip}.dat"
        ensure_dir "${SCRIPT_DIR}/data"
        
        if [[ -f "$ttl_history_file" ]]; then
            local prev_ttl=$(tail -1 "$ttl_history_file" | cut -d'|' -f2)
            
            if [[ -n "$prev_ttl" ]] && [[ "$ttl" != "$prev_ttl" ]]; then
                local diff=$((ttl - prev_ttl))
                if [[ ${diff#-} -gt 5 ]]; then
                    indicators+=("TTL_CHANGE")
                    ((score += 30))
                fi
            fi
        fi
        
        # Almacenar TTL actual
        echo "$(date +%s)|$ttl" >> "$ttl_history_file"
        
        # Verificar valores de TTL inusuales
        if [[ $ttl -lt 50 ]] || [[ $ttl -gt 130 && $ttl -lt 250 ]]; then
            indicators+=("UNUSUAL_TTL")
            ((score += 20))
        fi
    fi
    
    # Prueba 2: Verificar variaciones de latencia
    local latency_data=$(ping_host "$ip" 4)
    
    if [[ -n "$latency_data" ]]; then
        local min_lat=$(echo "$latency_data" | cut -d'|' -f1)
        local avg_lat=$(echo "$latency_data" | cut -d'|' -f2)
        local max_lat=$(echo "$latency_data" | cut -d'|' -f3)
        local mdev=$(echo "$latency_data" | cut -d'|' -f4)
        
        # Alta desviación podría indicar VPN
        local deviation_check=$(echo "$mdev $avg_lat" | awk '{if ($1 > $2 * 0.5) print "HIGH"}')
        
        if [[ "$deviation_check" == "HIGH" ]]; then
            indicators+=("HIGH_LATENCY_VAR")
            ((score += 25))
        fi
        
        # Latencia muy alta podría indicar VPN
        local high_latency=$(echo "$avg_lat" | awk '{if ($1 > 100) print "HIGH"}')
        if [[ "$high_latency" == "HIGH" ]]; then
            indicators+=("HIGH_LATENCY")
            ((score += 15))
        fi
    fi
    
    # Prueba 3: Verificar puertos VPN
    if command_exists nmap; then
        local vpn_ports="${VPN_PORTS:-1194,500,4500,1723}"
        local open_vpn_ports=$(nmap -p "$vpn_ports" -T4 --open "$ip" 2>/dev/null | \
            grep "^[0-9]" | grep "open" | awk '{print $1}' | cut -d'/' -f1)
        
        if [[ -n "$open_vpn_ports" ]]; then
            indicators+=("VPN_PORTS")
            ((score += 40))
        fi
    fi
    
    # Calcular probabilidad
    local probability="BAJA"
    local color="$GREEN"
    
    if [[ $score -ge 60 ]]; then
        probability="ALTA"
        color="$RED"
    elif [[ $score -ge 30 ]]; then
        probability="MEDIA"
        color="$YELLOW"
    fi
    
    # Formatear indicadores
    local indicators_str="${indicators[*]}"
    if [[ -z "$indicators_str" ]]; then
        indicators_str="Ninguno"
    fi
    
    # Imprimir resultado
    printf "%-15s %-15s %-40s " "$ip" "$hostname" "${indicators_str// /, }"
    print_color "$color" "$probability ($score%)"
    
    # Registrar si la probabilidad es media o alta
    if [[ $score -ge 30 ]]; then
        log_message "WARNING" "Possible VPN/Proxy detected on $ip ($hostname): $indicators_str (score: $score)" "$LOG_FILE"
    fi
}

# Ejecutar función principal
main "$@"
