#!/bin/bash
# SIM-RED EXTENDIDO - Anti-Spoofing Detection Script
# Feature 2: Detect IP/MAC spoofing attempts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/spoofing.log"

# Main function
main() {
    print_header "Verificación de Suplantación de IP/MAC (Anti-Spoofing)"
    
    # Check required tools
    if ! check_required_tools gawk; then
        return 1
    fi
    
    # Initialize log
    init_log "$LOG_FILE"
    
    # Get ARP table
    print_info "Analizando tabla ARP..."
    local arp_data=$(get_arp_table)
    
    if [[ -z "$arp_data" ]]; then
        print_error "No se pudieron obtener datos ARP"
        return 1
    fi
    
    echo ""
    local issues_found=false
    
    # Check for same IP with multiple MACs
    print_separator
    print_color "$CYAN" "Verificando: Misma IP con múltiples MACs"
    print_separator
    echo ""
    
    local ip_duplicates=$(echo "$arp_data" | awk -F'|' '
    {
        ip_mac[$1] = ip_mac[$1] ? ip_mac[$1] "," $2 : $2
    }
    END {
        for (ip in ip_mac) {
            split(ip_mac[ip], macs, ",")
            # Count unique MACs
            delete unique
            for (i in macs) {
                unique[macs[i]] = 1
            }
            count = 0
            for (m in unique) count++
            
            if (count > 1) {
                print ip "|" ip_mac[ip]
            }
        }
    }')
    
    if [[ -n "$ip_duplicates" ]]; then
        issues_found=true
        while IFS='|' read -r ip macs; do
            print_error "⚠ IP $ip tiene múltiples MACs:"
            IFS=',' read -ra mac_array <<< "$macs"
            for mac in "${mac_array[@]}"; do
                echo "    - $mac"
            done
            log_message "ALERT" "IP spoofing detected: $ip has multiple MACs: $macs" "$LOG_FILE"
        done <<< "$ip_duplicates"
    else
        print_success "✓ No se detectaron IPs con múltiples MACs"
    fi
    
    # Check for same MAC with multiple IPs
    echo ""
    print_separator
    print_color "$CYAN" "Verificando: Misma MAC con múltiples IPs"
    print_separator
    echo ""
    
    local mac_duplicates=$(echo "$arp_data" | awk -F'|' '
    {
        mac_ip[$2] = mac_ip[$2] ? mac_ip[$2] "," $1 : $1
    }
    END {
        for (mac in mac_ip) {
            split(mac_ip[mac], ips, ",")
            # Count unique IPs
            delete unique
            for (i in ips) {
                unique[ips[i]] = 1
            }
            count = 0
            for (ip in unique) count++
            
            if (count > 1) {
                print mac "|" mac_ip[mac]
            }
        }
    }')
    
    if [[ -n "$mac_duplicates" ]]; then
        issues_found=true
        while IFS='|' read -r mac ips; do
            print_error "⚠ MAC $mac tiene múltiples IPs:"
            IFS=',' read -ra ip_array <<< "$ips"
            for ip in "${ip_array[@]}"; do
                echo "    - $ip"
            done
            log_message "ALERT" "MAC spoofing detected: $mac has multiple IPs: $ips" "$LOG_FILE"
        done <<< "$mac_duplicates"
    else
        print_success "✓ No se detectaron MACs con múltiples IPs"
    fi
    
    # Check for MAC changes for known IPs
    echo ""
    print_separator
    print_color "$CYAN" "Verificando: Cambios de MAC en IPs conocidas"
    print_separator
    echo ""
    
    local history_file="${SCRIPT_DIR}/data/arp_history.dat"
    ensure_dir "${SCRIPT_DIR}/data"
    
    if [[ -f "$history_file" ]]; then
        # Compare with historical data
        local changes_detected=false
        
        while IFS='|' read -r current_ip current_mac; do
            # Check if this IP existed before
            local old_mac=$(grep "^${current_ip}|" "$history_file" 2>/dev/null | cut -d'|' -f2 | tail -1)
            
            if [[ -n "$old_mac" ]] && [[ "${old_mac,,}" != "${current_mac,,}" ]]; then
                changes_detected=true
                print_warning "⚠ IP $current_ip cambió de MAC:"
                echo "    Anterior: $old_mac"
                echo "    Actual:   $current_mac"
                log_message "WARNING" "MAC change detected for $current_ip: $old_mac -> $current_mac" "$LOG_FILE"
            fi
        done <<< "$arp_data"
        
        if [[ "$changes_detected" == false ]]; then
            print_success "✓ No se detectaron cambios de MAC"
        else
            issues_found=true
        fi
    else
        print_info "Primera ejecución - creando historial de ARP"
    fi
    
    # Update history
    echo "$arp_data" > "$history_file"
    
    # Summary
    echo ""
    print_separator
    if [[ "$issues_found" == true ]]; then
        print_color "$RED" "⚠ SE DETECTARON POSIBLES INTENTOS DE SUPLANTACIÓN"
        print_info "Revisa los logs en: $LOG_FILE"
    else
        print_color "$GREEN" "✓ NO SE DETECTARON INTENTOS DE SUPLANTACIÓN"
    fi
    print_separator
    echo ""
    
    press_any_key
}

# Run main function
main "$@"
