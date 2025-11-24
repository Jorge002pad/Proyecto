#!/bin/bash
# SIM-RED EXTENDIDO - File Integrity Check Script
# Feature 8: Verify integrity of hosts.conf file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

LOG_FILE="${SCRIPT_DIR}/logs/integrity.log"
HOSTS_FILE="${SCRIPT_DIR}/config/hosts.conf"
INTEGRITY_FILE="${SCRIPT_DIR}/data/integrity.sha256"

# Main function
main() {
    print_header "Verificación de Integridad de Archivos"
    
    # Check required tools
    if ! check_required_tools sha256sum; then
        return 1
    fi
    
    # Initialize log
    init_log "$LOG_FILE"
    ensure_dir "${SCRIPT_DIR}/data"
    
    # Check if hosts file exists
    if ! check_file "$HOSTS_FILE"; then
        return 1
    fi
    
    print_info "Verificando integridad de: $HOSTS_FILE"
    echo ""
    
    # Calculate current hash
    local current_hash=$(sha256sum "$HOSTS_FILE" | awk '{print $1}')
    
    print_info "Hash actual: $current_hash"
    
    # Check if integrity file exists
    if [[ -f "$INTEGRITY_FILE" ]]; then
        local stored_hash=$(cat "$INTEGRITY_FILE" 2>/dev/null)
        print_info "Hash almacenado: $stored_hash"
        echo ""
        
        # Compare hashes
        if [[ "$current_hash" == "$stored_hash" ]]; then
            print_success "✓ El archivo NO ha sido modificado"
            log_message "INFO" "File integrity check passed for hosts.conf" "$LOG_FILE"
        else
            print_error "⚠ El archivo HA SIDO MODIFICADO"
            print_warning "Se detectó un cambio en el archivo de hosts autorizados"
            log_message "ALERT" "File integrity check FAILED for hosts.conf" "$LOG_FILE"
            
            echo ""
            if ask_yes_no "¿Deseas actualizar el hash almacenado?" "n"; then
                echo "$current_hash" > "$INTEGRITY_FILE"
                print_success "Hash actualizado"
                log_message "INFO" "Integrity hash updated for hosts.conf" "$LOG_FILE"
            fi
        fi
    else
        print_warning "No existe hash almacenado (primera ejecución)"
        echo ""
        
        if ask_yes_no "¿Deseas crear el hash de integridad?" "y"; then
            echo "$current_hash" > "$INTEGRITY_FILE"
            print_success "✓ Hash de integridad creado"
            log_message "INFO" "Integrity hash created for hosts.conf: $current_hash" "$LOG_FILE"
        fi
    fi
    
    echo ""
    press_any_key
}

# Run main function
main "$@"
