#!/bin/bash
# SIM-RED EXTENDIDO - VPN/Proxy Detection Script
# Feature 3: Detect if users are using VPN or Proxy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/vpn.log"

# Main function
main() {
    print_header "Detección de VPN/Proxy"
    
    # Check required tools
    if ! check_required_tools ping nmap gawk; then
        return 1
    fi
    
    # Initialize log
    init_log "$LOG_FILE"
    
    # Load authorized hosts
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    if ! check_file "$hosts_file"; then
        return 1
    fi
    
    print_info "Analizando hosts autorizados para detectar uso de VPN/Proxy..."
    echo ""
    
    print_separator
    printf "%-15s %-15s %-40s %s\n" "IP" "Hostname" "Indicadores" "Probabilidad"
    print_separator
    
    # Analyze each authorized host
    while IFS='|' read -r ip mac hostname desc; do
        analyze_host_for_vpn "$ip" "$hostname"
    done < <(load_authorized_hosts "$hosts_file")
    
    print_separator
    echo ""
    
    press_any_key
}

# Analyze a host for VPN/Proxy indicators
analyze_host_for_vpn() {
    local ip="$1"
    local hostname="$2"
    local indicators=()
    local score=0
    
    # Test 1: Check TTL variations
    local ttl=$(get_ttl "$ip")
    
    if [[ -n "$ttl" ]]; then
        # Normal TTLs: 64 (Linux), 128 (Windows), 255 (Network devices)
        # VPN might show unusual TTLs or variations
        
        # Store TTL history
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
        
        # Store current TTL
        echo "$(date +%s)|$ttl" >> "$ttl_history_file"
        
        # Check for unusual TTL values
        if [[ $ttl -lt 50 ]] || [[ $ttl -gt 130 && $ttl -lt 250 ]]; then
            indicators+=("UNUSUAL_TTL")
            ((score += 20))
        fi
    fi
    
    # Test 2: Check latency variations
    local latency_data=$(ping_host "$ip" 4)
    
    if [[ -n "$latency_data" ]]; then
        local min_lat=$(echo "$latency_data" | cut -d'|' -f1)
        local avg_lat=$(echo "$latency_data" | cut -d'|' -f2)
        local max_lat=$(echo "$latency_data" | cut -d'|' -f3)
        local mdev=$(echo "$latency_data" | cut -d'|' -f4)
        
        # High deviation might indicate VPN
        local deviation_check=$(echo "$mdev $avg_lat" | awk '{if ($1 > $2 * 0.5) print "HIGH"}')
        
        if [[ "$deviation_check" == "HIGH" ]]; then
            indicators+=("HIGH_LATENCY_VAR")
            ((score += 25))
        fi
        
        # Very high latency might indicate VPN
        local high_latency=$(echo "$avg_lat" | awk '{if ($1 > 100) print "HIGH"}')
        if [[ "$high_latency" == "HIGH" ]]; then
            indicators+=("HIGH_LATENCY")
            ((score += 15))
        fi
    fi
    
    # Test 3: Check for VPN ports
    if command_exists nmap; then
        local vpn_ports="${VPN_PORTS:-1194,500,4500,1723}"
        local open_vpn_ports=$(nmap -p "$vpn_ports" -T4 --open "$ip" 2>/dev/null | \
            grep "^[0-9]" | grep "open" | awk '{print $1}' | cut -d'/' -f1)
        
        if [[ -n "$open_vpn_ports" ]]; then
            indicators+=("VPN_PORTS")
            ((score += 40))
        fi
    fi
    
    # Calculate probability
    local probability="BAJA"
    local color="$GREEN"
    
    if [[ $score -ge 60 ]]; then
        probability="ALTA"
        color="$RED"
    elif [[ $score -ge 30 ]]; then
        probability="MEDIA"
        color="$YELLOW"
    fi
    
    # Format indicators
    local indicators_str="${indicators[*]}"
    if [[ -z "$indicators_str" ]]; then
        indicators_str="Ninguno"
    fi
    
    # Print result
    printf "%-15s %-15s %-40s " "$ip" "$hostname" "${indicators_str// /, }"
    print_color "$color" "$probability ($score%)"
    
    # Log if probability is medium or high
    if [[ $score -ge 30 ]]; then
        log_message "WARNING" "Possible VPN/Proxy detected on $ip ($hostname): $indicators_str (score: $score)" "$LOG_FILE"
    fi
}

# Run main function
main "$@"
