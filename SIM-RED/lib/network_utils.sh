#!/bin/bash
# SIM-RED EXTENDIDO - Network Utility Functions
# Network-specific helper functions

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Get local subnet
get_local_subnet() {
    # Try to get from config first
    if [[ -n "$SUBNET" ]]; then
        echo "$SUBNET"
        return 0
    fi
    
    # Auto-detect from ip command
    if command_exists ip; then
        local subnet=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | grep -v '127.0.0.1' | head -1)
        if [[ -n "$subnet" ]]; then
            echo "$subnet"
            return 0
        fi
    fi
    
    # Default fallback
    echo "192.168.1.0/24"
}

# Get network interface
get_network_interface() {
    # Try to get from config first
    if [[ -n "$NETWORK_INTERFACE" ]]; then
        echo "$NETWORK_INTERFACE"
        return 0
    fi
    
    # Auto-detect active interface
    if command_exists ip; then
        local iface=$(ip route | grep default | awk '{print $5}' | head -1)
        if [[ -n "$iface" ]]; then
            echo "$iface"
            return 0
        fi
    fi
    
    # Fallback
    echo "eth0"
}

# Read ARP table
get_arp_table() {
    if command_exists arp-scan; then
        # Use arp-scan for more reliable results (requires root)
        local subnet=$(get_local_subnet)
        sudo arp-scan --localnet --interface=$(get_network_interface) 2>/dev/null | \
            grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
            awk '{print $1"|"$2}'
    elif [[ -f /proc/net/arp ]]; then
        # Fallback to /proc/net/arp
        cat /proc/net/arp | \
            grep -v 'IP address' | \
            grep -v '00:00:00:00:00:00' | \
            awk '$3 != "0x0" {print $1"|"$4}'
    else
        # Last resort: use arp command
        arp -a | \
            grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}.*([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | \
            awk '{print $1"|"$2}'
    fi
}

# Load authorized hosts from config
load_authorized_hosts() {
    local hosts_file="${1:-${SCRIPT_DIR}/config/hosts.conf}"
    
    if ! check_file "$hosts_file"; then
        return 1
    fi
    
    # Return IP|MAC|HOSTNAME|DESCRIPTION
    grep -v '^#' "$hosts_file" | grep -v '^[[:space:]]*$'
}

# Load schedules from config
load_schedules() {
    local schedule_file="${1:-${SCRIPT_DIR}/config/schedule.conf}"
    
    if ! check_file "$schedule_file"; then
        return 1
    fi
    
    # Return IP|DAYS|START_TIME|END_TIME
    grep -v '^#' "$schedule_file" | grep -v '^[[:space:]]*$'
}

# Check if IP is in schedule
check_schedule() {
    local ip="$1"
    local schedule_file="${2:-${SCRIPT_DIR}/config/schedule.conf}"
    
    # Get current day and time
    local current_day=$(date +%a)
    local current_time=$(date +%H:%M)
    
    # Find schedule for this IP
    local schedule=$(grep "^${ip}|" "$schedule_file" 2>/dev/null)
    
    if [[ -z "$schedule" ]]; then
        # No schedule defined, assume not allowed
        echo "NO_SCHEDULE"
        return 1
    fi
    
    local days=$(echo "$schedule" | cut -d'|' -f2)
    local start_time=$(echo "$schedule" | cut -d'|' -f3)
    local end_time=$(echo "$schedule" | cut -d'|' -f4)
    
    # Check if current day is in allowed days
    local day_ok=false
    
    # Handle day ranges (Mon-Fri) or specific days
    if [[ "$days" == "Mon-Sun" ]] || [[ "$days" == "*" ]]; then
        day_ok=true
    elif [[ "$days" =~ - ]]; then
        # Range like Mon-Fri
        # Simplified check - in production would need proper day range logic
        case "$current_day" in
            Mon|Tue|Wed|Thu|Fri)
                if [[ "$days" =~ Mon.*Fri ]]; then
                    day_ok=true
                fi
                ;;
            Sat|Sun)
                if [[ "$days" =~ Sat.*Sun ]]; then
                    day_ok=true
                fi
                ;;
        esac
    else
        # Specific day
        if [[ "$days" == *"$current_day"* ]]; then
            day_ok=true
        fi
    fi
    
    if [[ "$day_ok" == false ]]; then
        echo "WRONG_DAY"
        return 1
    fi
    
    # Check time range
    if [[ "$current_time" < "$start_time" ]] || [[ "$current_time" > "$end_time" ]]; then
        echo "WRONG_TIME"
        return 1
    fi
    
    echo "ALLOWED"
    return 0
}

# Get hostname for IP
get_hostname_for_ip() {
    local ip="$1"
    local hosts_file="${2:-${SCRIPT_DIR}/config/hosts.conf}"
    
    grep "^${ip}|" "$hosts_file" 2>/dev/null | cut -d'|' -f3
}

# Get MAC for IP from authorized hosts
get_authorized_mac() {
    local ip="$1"
    local hosts_file="${2:-${SCRIPT_DIR}/config/hosts.conf}"
    
    grep "^${ip}|" "$hosts_file" 2>/dev/null | cut -d'|' -f2
}

# Check if IP is authorized
is_authorized_ip() {
    local ip="$1"
    local hosts_file="${2:-${SCRIPT_DIR}/config/hosts.conf}"
    
    grep -q "^${ip}|" "$hosts_file" 2>/dev/null
    return $?
}

# Check if MAC is authorized
is_authorized_mac() {
    local mac="$1"
    local hosts_file="${2:-${SCRIPT_DIR}/config/hosts.conf}"
    
    grep -q "|${mac}|" "$hosts_file" 2>/dev/null
    return $?
}

# Ping host and get latency
ping_host() {
    local host="$1"
    local count="${2:-4}"
    
    if ! command_exists ping; then
        echo "ERROR: ping command not found"
        return 1
    fi
    
    # Ping and extract statistics
    ping -c "$count" -W 2 "$host" 2>/dev/null | \
        grep -E 'rtt min/avg/max/mdev' | \
        awk -F'[=/]' '{print $2"|"$3"|"$4"|"$5}'
}

# Get TTL for host
get_ttl() {
    local host="$1"
    
    ping -c 1 -W 2 "$host" 2>/dev/null | \
        grep -oP 'ttl=\K[0-9]+' | head -1
}

# Export functions
export -f get_local_subnet
export -f get_network_interface
export -f get_arp_table
export -f load_authorized_hosts
export -f load_schedules
export -f check_schedule
export -f get_hostname_for_ip
export -f is_authorized_ip
export -f is_authorized_mac
export -f ping_host
export -f get_ttl
