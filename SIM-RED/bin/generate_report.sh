#!/bin/bash
# SIM-RED EXTENDIDO - Report Generation Script
# Feature 12: Generate complete network status report

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

LOG_FILE="${SCRIPT_DIR}/logs/system.log"
REPORT_DIR="${SCRIPT_DIR}/reports"

# Main function
main() {
    print_header "Generación de Informe Completo de Red"
    
    # Initialize
    init_log "$LOG_FILE"
    ensure_dir "$REPORT_DIR"
    
    print_info "Recopilando información de la red..."
    echo ""
    
    # Generate report filename
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local report_txt="${REPORT_DIR}/report_${timestamp}.txt"
    local report_html="${REPORT_DIR}/report_${timestamp}.html"
    local report_data="${REPORT_DIR}/report_${timestamp}.dat"
    
    # Collect all data
    print_info "Analizando dispositivos..."
    collect_device_data > "${report_data}.tmp"
    
    print_info "Verificando seguridad..."
    collect_security_data >> "${report_data}.tmp"
    
    print_info "Midiendo rendimiento..."
    collect_performance_data >> "${report_data}.tmp"
    
    # Move temp file
    mv "${report_data}.tmp" "$report_data"
    
    # Generate TXT report
    print_info "Generando reporte TXT..."
    generate_txt_report "$report_data" "$report_txt"
    
    # Generate HTML report
    local format="${REPORT_FORMAT:-both}"
    
    if [[ "$format" == "html" ]] || [[ "$format" == "both" ]]; then
        print_info "Generando reporte HTML..."
        
        if command_exists perl; then
            perl "${SCRIPT_DIR}/lib/report_generator.pl" "$report_data" "$report_html"
        else
            print_warning "Perl no disponible, saltando reporte HTML"
        fi
    fi
    
    # Summary
    echo ""
    print_separator
    print_success "✓ Informes generados:"
    echo "  - TXT:  $report_txt"
    
    if [[ -f "$report_html" ]]; then
        echo "  - HTML: $report_html"
    fi
    
    print_separator
    echo ""
    
    if ask_yes_no "¿Deseas ver el reporte TXT?" "y"; then
        less "$report_txt" 2>/dev/null || cat "$report_txt" | more
    fi
    
    echo ""
    press_any_key
}

# Collect device data
collect_device_data() {
    echo "[SUMMARY]"
    
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    local total_auth=$(grep -v '^#' "$hosts_file" | grep -v '^[[:space:]]*$' | wc -l)
    
    echo "Total Hosts Autorizados: $total_auth"
    
    # Get connected devices
    local connected=$(get_arp_table 2>/dev/null | wc -l)
    echo "Dispositivos Conectados: $connected"
    
    echo ""
    echo "[DEVICES]"
    
    # List devices
    while IFS='|' read -r ip mac; do
        local hostname=$(get_hostname_for_ip "$ip" "$hosts_file")
        
        if [[ -z "$hostname" ]]; then
            hostname="Desconocido"
            echo "$ip|$mac|$hostname|WARNING"
        else
            echo "$ip|$mac|$hostname|OK"
        fi
    done < <(get_arp_table 2>/dev/null)
}

# Collect security data
collect_security_data() {
    echo ""
    echo "[SPOOFING]"
    
    # Check for spoofing (simplified)
    local arp_data=$(get_arp_table 2>/dev/null)
    
    local spoofing=$(echo "$arp_data" | awk -F'|' '
    {
        ip_count[$1]++
        mac_count[$2]++
    }
    END {
        found = 0
        for (ip in ip_count) {
            if (ip_count[ip] > 1) {
                print "IP duplicada: " ip
                found = 1
            }
        }
        for (mac in mac_count) {
            if (mac_count[mac] > 1) {
                print "MAC duplicada: " mac
                found = 1
            }
        }
        if (found == 0) {
            print "No se detectaron anomalías"
        }
    }')
    
    echo "$spoofing"
    
    echo ""
    echo "[ALERTS]"
    
    # Get recent alerts from logs
    if [[ -f "${SCRIPT_DIR}/logs/spoofing.log" ]]; then
        tail -10 "${SCRIPT_DIR}/logs/spoofing.log" | grep "ALERT" || echo "Sin alertas recientes"
    else
        echo "Sin alertas recientes"
    fi
}

# Collect performance data
collect_performance_data() {
    echo ""
    echo "[LATENCY]"
    
    # Get latency data
    local hosts_file="${SCRIPT_DIR}/config/hosts.conf"
    
    while IFS='|' read -r ip mac hostname desc; do
        local latency=$(ping_host "$ip" 4 2>/dev/null)
        
        if [[ -n "$latency" ]]; then
            local min=$(echo "$latency" | cut -d'|' -f1)
            local avg=$(echo "$latency" | cut -d'|' -f2)
            local max=$(echo "$latency" | cut -d'|' -f3)
            
            local status="OK"
            local avg_int=$(echo "$avg" | cut -d'.' -f1)
            
            if [[ $avg_int -gt 100 ]]; then
                status="HIGH"
            elif [[ $avg_int -gt 50 ]]; then
                status="MEDIUM"
            fi
            
            echo "$hostname|$min|$avg|$max|$status"
        fi
    done < <(load_authorized_hosts "$hosts_file" | head -5)
}

# Generate TXT report
generate_txt_report() {
    local data_file="$1"
    local output_file="$2"
    
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "  SIM-RED EXTENDIDO - Informe de Red"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        
        # Parse data file
        local section=""
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^\[(.+)\]$ ]]; then
                section="${BASH_REMATCH[1]}"
                echo ""
                echo "───────────────────────────────────────────────────────────────"
                echo "  $section"
                echo "───────────────────────────────────────────────────────────────"
                echo ""
            elif [[ -n "$line" ]]; then
                echo "  $line"
            fi
        done < "$data_file"
        
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "  Fin del Informe"
        echo "═══════════════════════════════════════════════════════════════"
    } > "$output_file"
}

# Run main function
main "$@"
