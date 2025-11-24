#!/bin/bash
# SIM-RED EXTENDIDO - Configuration Script
# Feature 14: System configuration management

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/network_utils.sh"

CONFIG_FILE="${SCRIPT_DIR}/config/config.conf"
HOSTS_FILE="${SCRIPT_DIR}/config/hosts.conf"
SCHEDULE_FILE="${SCRIPT_DIR}/config/schedule.conf"

# Main function
main() {
    while true; do
        print_header "Configuración del Sistema"
        
        echo "  1) Cambiar subred a escanear"
        echo "  2) Configurar intervalos de monitoreo"
        echo "  3) Gestionar hosts autorizados"
        echo "  4) Configurar umbrales de alerta"
        echo "  5) Ver configuración actual"
        echo "  0) Volver al menú principal"
        echo ""
        echo -n "Selecciona una opción: "
        read -r option
        
        case "$option" in
            1) configure_subnet ;;
            2) configure_intervals ;;
            3) manage_hosts ;;
            4) configure_thresholds ;;
            5) view_config ;;
            0) return 0 ;;
            *) print_error "Opción inválida" ;;
        esac
    done
}

# Configure subnet
configure_subnet() {
    print_header "Configurar Subred"
    
    local current=$(grep "^SUBNET=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '"')
    
    print_info "Subred actual: $current"
    echo ""
    echo -n "Nueva subred (ej: 192.168.1.0/24): "
    read -r new_subnet
    
    if [[ -z "$new_subnet" ]]; then
        print_warning "Operación cancelada"
        press_any_key
        return
    fi
    
    # Update config file
    sed -i "s|^SUBNET=.*|SUBNET=\"$new_subnet\"|" "$CONFIG_FILE"
    
    print_success "✓ Subred actualizada a: $new_subnet"
    
    press_any_key
}

# Configure monitoring intervals
configure_intervals() {
    print_header "Configurar Intervalos de Monitoreo"
    
    echo "  1) Intervalo de monitoreo general"
    echo "  2) Intervalo de monitoreo ARP"
    echo "  3) Intervalo de monitoreo de latencia"
    echo "  0) Volver"
    echo ""
    echo -n "Selecciona: "
    read -r choice
    
    case "$choice" in
        1)
            local current=$(grep "^MONITOR_INTERVAL=" "$CONFIG_FILE" | cut -d'=' -f2)
            print_info "Intervalo actual: $current segundos"
            echo -n "Nuevo intervalo (segundos): "
            read -r new_val
            if [[ -n "$new_val" ]]; then
                sed -i "s/^MONITOR_INTERVAL=.*/MONITOR_INTERVAL=$new_val/" "$CONFIG_FILE"
                print_success "✓ Actualizado"
            fi
            ;;
        2)
            local current=$(grep "^ARP_MONITOR_INTERVAL=" "$CONFIG_FILE" | cut -d'=' -f2)
            print_info "Intervalo actual: $current segundos"
            echo -n "Nuevo intervalo (segundos): "
            read -r new_val
            if [[ -n "$new_val" ]]; then
                sed -i "s/^ARP_MONITOR_INTERVAL=.*/ARP_MONITOR_INTERVAL=$new_val/" "$CONFIG_FILE"
                print_success "✓ Actualizado"
            fi
            ;;
        3)
            local current=$(grep "^LATENCY_MONITOR_INTERVAL=" "$CONFIG_FILE" | cut -d'=' -f2)
            print_info "Intervalo actual: $current segundos"
            echo -n "Nuevo intervalo (segundos): "
            read -r new_val
            if [[ -n "$new_val" ]]; then
                sed -i "s/^LATENCY_MONITOR_INTERVAL=.*/LATENCY_MONITOR_INTERVAL=$new_val/" "$CONFIG_FILE"
                print_success "✓ Actualizado"
            fi
            ;;
    esac
    
    press_any_key
}

# Manage authorized hosts
manage_hosts() {
    while true; do
        print_header "Gestión de Hosts Autorizados"
        
        echo "  1) Ver hosts autorizados"
        echo "  2) Añadir host"
        echo "  3) Eliminar host"
        echo "  0) Volver"
        echo ""
        echo -n "Selecciona: "
        read -r choice
        
        case "$choice" in
            1) view_hosts ;;
            2) add_host ;;
            3) remove_host ;;
            0) return 0 ;;
            *) print_error "Opción inválida" ;;
        esac
    done
}

# View hosts
view_hosts() {
    print_header "Hosts Autorizados"
    
    print_separator
    printf "${BOLD}%-15s %-20s %-15s %s${NC}\n" "IP" "MAC" "Hostname" "Descripción"
    print_separator
    
    while IFS='|' read -r ip mac hostname desc; do
        printf "%-15s %-20s %-15s %s\n" "$ip" "$mac" "$hostname" "$desc"
    done < <(load_authorized_hosts "$HOSTS_FILE")
    
    print_separator
    
    press_any_key
}

# Add host
add_host() {
    print_header "Añadir Host Autorizado"
    
    echo -n "IP: "
    read -r ip
    
    if ! validate_ip "$ip"; then
        print_error "IP inválida"
        press_any_key
        return
    fi
    
    echo -n "MAC: "
    read -r mac
    
    if ! validate_mac "$mac"; then
        print_error "MAC inválida"
        press_any_key
        return
    fi
    
    echo -n "Hostname: "
    read -r hostname
    
    echo -n "Descripción: "
    read -r desc
    
    # Add to hosts file
    echo "$ip|$mac|$hostname|$desc" >> "$HOSTS_FILE"
    
    print_success "✓ Host añadido"
    
    # Ask about schedule
    if ask_yes_no "¿Deseas configurar un horario para este host?" "y"; then
        echo -n "Días (ej: Mon-Fri, Mon-Sun): "
        read -r days
        
        echo -n "Hora inicio (HH:MM): "
        read -r start_time
        
        echo -n "Hora fin (HH:MM): "
        read -r end_time
        
        echo "$ip|$days|$start_time|$end_time" >> "$SCHEDULE_FILE"
        
        print_success "✓ Horario configurado"
    fi
    
    press_any_key
}

# Remove host
remove_host() {
    print_header "Eliminar Host Autorizado"
    
    echo -n "IP del host a eliminar: "
    read -r ip
    
    if ! grep -q "^${ip}|" "$HOSTS_FILE"; then
        print_error "Host no encontrado"
        press_any_key
        return
    fi
    
    # Show host info
    local host_info=$(grep "^${ip}|" "$HOSTS_FILE")
    echo ""
    print_info "Host a eliminar: $host_info"
    echo ""
    
    if ask_yes_no "¿Estás seguro?" "n"; then
        # Remove from hosts file
        sed -i "/^${ip}|/d" "$HOSTS_FILE"
        
        # Remove from schedule file
        sed -i "/^${ip}|/d" "$SCHEDULE_FILE"
        
        print_success "✓ Host eliminado"
    else
        print_info "Operación cancelada"
    fi
    
    press_any_key
}

# Configure thresholds
configure_thresholds() {
    print_header "Configurar Umbrales de Alerta"
    
    echo "  1) Umbral de latencia (ms)"
    echo "  2) Umbral de alerta de latencia (ms)"
    echo "  3) Multiplicador de anomalías"
    echo "  0) Volver"
    echo ""
    echo -n "Selecciona: "
    read -r choice
    
    case "$choice" in
        1)
            local current=$(grep "^LATENCY_THRESHOLD_MS=" "$CONFIG_FILE" | cut -d'=' -f2)
            print_info "Umbral actual: $current ms"
            echo -n "Nuevo umbral (ms): "
            read -r new_val
            if [[ -n "$new_val" ]]; then
                sed -i "s/^LATENCY_THRESHOLD_MS=.*/LATENCY_THRESHOLD_MS=$new_val/" "$CONFIG_FILE"
                print_success "✓ Actualizado"
            fi
            ;;
        2)
            local current=$(grep "^LATENCY_ALERT_MS=" "$CONFIG_FILE" | cut -d'=' -f2)
            print_info "Umbral actual: $current ms"
            echo -n "Nuevo umbral (ms): "
            read -r new_val
            if [[ -n "$new_val" ]]; then
                sed -i "s/^LATENCY_ALERT_MS=.*/LATENCY_ALERT_MS=$new_val/" "$CONFIG_FILE"
                print_success "✓ Actualizado"
            fi
            ;;
        3)
            local current=$(grep "^TRAFFIC_ANOMALY_MULTIPLIER=" "$CONFIG_FILE" | cut -d'=' -f2)
            print_info "Multiplicador actual: $current"
            echo -n "Nuevo multiplicador: "
            read -r new_val
            if [[ -n "$new_val" ]]; then
                sed -i "s/^TRAFFIC_ANOMALY_MULTIPLIER=.*/TRAFFIC_ANOMALY_MULTIPLIER=$new_val/" "$CONFIG_FILE"
                print_success "✓ Actualizado"
            fi
            ;;
    esac
    
    press_any_key
}

# View current configuration
view_config() {
    print_header "Configuración Actual"
    
    print_separator
    cat "$CONFIG_FILE" | grep -v "^#" | grep -v "^$"
    print_separator
    
    press_any_key
}

# Run main function
main "$@"
