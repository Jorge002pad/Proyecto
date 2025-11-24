#!/bin/bash
# SIM-RED EXTENDIDO - DNS Availability Check Script
# Feature 10: Check DNS server availability and response time

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

LOG_FILE="${SCRIPT_DIR}/logs/dns.log"

# Main function
main() {
    print_header "Comprobación de Disponibilidad del DNS"
    
    # Check required tools
    if ! check_required_tools dig; then
        print_warning "dig no está disponible, intentando con host..."
        if ! check_required_tools host; then
            return 1
        fi
    fi
    
    # Initialize log
    init_log "$LOG_FILE"
    
    # Get DNS servers from config
    local dns_servers="${DNS_SERVERS:-8.8.8.8 8.8.4.4 1.1.1.1}"
    
    print_info "Probando servidores DNS: $dns_servers"
    echo ""
    
    print_separator
    printf "${BOLD}%-20s %-15s %-15s %s${NC}\n" \
        "Servidor DNS" "Estado" "Tiempo (ms)" "Resultado"
    print_separator
    
    local test_domain="google.com"
    local all_ok=true
    
    for dns in $dns_servers; do
        test_dns_server "$dns" "$test_domain"
        if [[ $? -ne 0 ]]; then
            all_ok=false
        fi
    done
    
    print_separator
    echo ""
    
    if [[ "$all_ok" == true ]]; then
        print_success "✓ Todos los servidores DNS están funcionando correctamente"
    else
        print_warning "⚠ Algunos servidores DNS presentan problemas"
    fi
    
    echo ""
    press_any_key
}

# Test a single DNS server
test_dns_server() {
    local dns="$1"
    local domain="$2"
    
    # Try with dig first
    if command_exists dig; then
        local start_time=$(date +%s%N)
        local result=$(dig @"$dns" "$domain" +short +time=2 +tries=1 2>/dev/null)
        local end_time=$(date +%s%N)
        
        if [[ -n "$result" ]]; then
            local time_ms=$(( (end_time - start_time) / 1000000 ))
            
            local color="$GREEN"
            if [[ $time_ms -gt 1000 ]]; then
                color="$YELLOW"
            fi
            
            printf "%-20s ${GREEN}%-15s${NC} ${color}%-15s${NC} %s\n" \
                "$dns" "✓ Disponible" "${time_ms} ms" "$(echo "$result" | head -1)"
            
            log_message "INFO" "DNS $dns is available (${time_ms}ms)" "$LOG_FILE"
            return 0
        else
            printf "%-20s ${RED}%-15s${NC} %-15s %s\n" \
                "$dns" "✗ No responde" "-" "Timeout"
            
            log_message "ERROR" "DNS $dns is not responding" "$LOG_FILE"
            return 1
        fi
    # Fallback to host command
    elif command_exists host; then
        local start_time=$(date +%s%N)
        local result=$(host -W 2 "$domain" "$dns" 2>/dev/null | grep "has address")
        local end_time=$(date +%s%N)
        
        if [[ -n "$result" ]]; then
            local time_ms=$(( (end_time - start_time) / 1000000 ))
            
            printf "%-20s ${GREEN}%-15s${NC} %-15s %s\n" \
                "$dns" "✓ Disponible" "${time_ms} ms" "OK"
            
            log_message "INFO" "DNS $dns is available (${time_ms}ms)" "$LOG_FILE"
            return 0
        else
            printf "%-20s ${RED}%-15s${NC} %-15s %s\n" \
                "$dns" "✗ No responde" "-" "Timeout"
            
            log_message "ERROR" "DNS $dns is not responding" "$LOG_FILE"
            return 1
        fi
    fi
}

# Run main function
main "$@"
