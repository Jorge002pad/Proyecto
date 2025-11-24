#!/bin/bash
# SIM-RED EXTENDIDO - Log Management Script
# Feature 13: Manage system logs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

LOGS_DIR="${SCRIPT_DIR}/logs"

# Main function
main() {
    while true; do
        print_header "Gestión de Logs"
        
        echo "  1) Ver logs"
        echo "  2) Borrar logs"
        echo "  3) Exportar logs"
        echo "  4) Estadísticas de logs"
        echo "  0) Volver al menú principal"
        echo ""
        echo -n "Selecciona una opción: "
        read -r option
        
        case "$option" in
            1) view_logs ;;
            2) clear_logs ;;
            3) export_logs ;;
            4) log_statistics ;;
            0) return 0 ;;
            *) print_error "Opción inválida" ;;
        esac
    done
}

# View logs
view_logs() {
    print_header "Ver Logs"
    
    # List available logs
    local logs=$(ls "$LOGS_DIR"/*.log 2>/dev/null)
    
    if [[ -z "$logs" ]]; then
        print_warning "No hay logs disponibles"
        press_any_key
        return
    fi
    
    echo "Logs disponibles:"
    echo ""
    
    local -a log_files=()
    local i=1
    
    for log in $logs; do
        local basename=$(basename "$log")
        local size=$(du -h "$log" 2>/dev/null | cut -f1)
        local lines=$(wc -l < "$log" 2>/dev/null)
        
        echo "  $i) $basename ($size, $lines líneas)"
        log_files+=("$log")
        ((i++))
    done
    
    echo "  0) Volver"
    echo ""
    echo -n "Selecciona un log: "
    read -r choice
    
    if [[ "$choice" == "0" ]]; then
        return
    fi
    
    if [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#log_files[@]} ]]; then
        local selected="${log_files[$((choice-1))]}"
        
        echo ""
        print_info "Mostrando: $(basename "$selected")"
        print_separator
        echo ""
        
        # Show with pagination
        less "$selected" 2>/dev/null || cat "$selected" | more
    else
        print_error "Selección inválida"
    fi
    
    press_any_key
}

# Clear logs
clear_logs() {
    print_header "Borrar Logs"
    
    print_warning "Esta acción eliminará todos los archivos de log"
    echo ""
    
    if ! ask_yes_no "¿Estás seguro de que deseas continuar?" "n"; then
        print_info "Operación cancelada"
        press_any_key
        return
    fi
    
    # List logs
    local logs=$(ls "$LOGS_DIR"/*.log 2>/dev/null)
    
    if [[ -z "$logs" ]]; then
        print_warning "No hay logs para borrar"
        press_any_key
        return
    fi
    
    # Clear each log
    for log in $logs; do
        > "$log"
        print_success "✓ $(basename "$log") borrado"
    done
    
    echo ""
    print_success "Todos los logs han sido borrados"
    
    press_any_key
}

# Export logs
export_logs() {
    print_header "Exportar Logs"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local export_file="${SCRIPT_DIR}/logs_export_${timestamp}.tar.gz"
    
    print_info "Exportando logs a: $export_file"
    echo ""
    
    # Create tarball
    tar -czf "$export_file" -C "$SCRIPT_DIR" logs/ 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        local size=$(du -h "$export_file" | cut -f1)
        print_success "✓ Logs exportados exitosamente"
        echo ""
        echo "  Archivo: $export_file"
        echo "  Tamaño:  $size"
    else
        print_error "Error al exportar logs"
    fi
    
    echo ""
    press_any_key
}

# Log statistics
log_statistics() {
    print_header "Estadísticas de Logs"
    
    local logs=$(ls "$LOGS_DIR"/*.log 2>/dev/null)
    
    if [[ -z "$logs" ]]; then
        print_warning "No hay logs disponibles"
        press_any_key
        return
    fi
    
    print_separator
    printf "${BOLD}%-20s %10s %10s %10s %10s${NC}\n" \
        "Log" "Tamaño" "Líneas" "INFO" "ALERT"
    print_separator
    
    for log in $logs; do
        local basename=$(basename "$log")
        local size=$(du -h "$log" 2>/dev/null | cut -f1)
        local lines=$(wc -l < "$log" 2>/dev/null)
        local info=$(grep -c "INFO" "$log" 2>/dev/null || echo "0")
        local alerts=$(grep -c "ALERT" "$log" 2>/dev/null || echo "0")
        
        printf "%-20s %10s %10s %10s %10s\n" \
            "$basename" "$size" "$lines" "$info" "$alerts"
    done
    
    print_separator
    echo ""
    
    press_any_key
}

# Run main function
main "$@"
