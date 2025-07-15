#!/bin/bash
#
# OpenVPN Status & Monitoring Script
# Script untuk monitoring status OpenVPN server dan clients
#
# Author: ByNaz @ByNaz0801
# Date: July 14, 2025
#

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Fungsi untuk mendapatkan informasi sistem
get_system_info() {
    print_header "================================================="
    print_header "           INFORMASI SISTEM"
    print_header "================================================="
    
    echo "Hostname        : $(hostname)"
    echo "OS              : $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel          : $(uname -r)"
    echo "Uptime          : $(uptime -p)"
    echo "Load Average    : $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage    : $(free -m | awk 'NR==2{printf "%.1f%% (%dMB/%dMB)", $3*100/$2, $3, $2}')"
    echo "Disk Usage      : $(df -h / | awk 'NR==2{printf "%s (%s)", $5, $4}')"
    
    # Network interfaces
    echo ""
    print_info "Network Interfaces:"
    ip addr show | grep -E '^[0-9]+:' | awk '{print $2}' | tr -d ':' | while read iface; do
        ip=$(ip addr show $iface | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
        if [ -n "$ip" ]; then
            echo "  $iface: $ip"
        fi
    done
    
    echo ""
}

# Fungsi untuk status OpenVPN service
get_openvpn_status() {
    print_header "================================================="
    print_header "           STATUS OPENVPN SERVICE"
    print_header "================================================="
    
    if systemctl is-active --quiet openvpn-server@server; then
        print_success "OpenVPN Service: RUNNING"
        echo "Start Time      : $(systemctl show openvpn-server@server --property=ActiveEnterTimestamp --value)"
        echo "PID             : $(systemctl show openvpn-server@server --property=MainPID --value)"
        
        # Memory usage
        local pid=$(systemctl show openvpn-server@server --property=MainPID --value)
        if [ "$pid" != "0" ]; then
            local mem_usage=$(ps -p $pid -o rss= | awk '{print $1/1024}')
            echo "Memory Usage    : ${mem_usage}MB"
        fi
    else
        print_error "OpenVPN Service: STOPPED"
        echo "Last Status     : $(systemctl show openvpn-server@server --property=SubState --value)"
    fi
    
    # Port status
    echo ""
    print_info "Port Status:"
    if [ -f "/etc/openvpn/server/server.conf" ]; then
        local port=$(grep "^port " /etc/openvpn/server/server.conf | awk '{print $2}')
        local proto=$(grep "^proto " /etc/openvpn/server/server.conf | awk '{print $2}')
        
        echo "Configured Port : $port/$proto"
        
        if netstat -tuln | grep -q ":$port "; then
            print_success "Port $port is listening"
        else
            print_error "Port $port is NOT listening"
        fi
    fi
    
    echo ""
}

# Fungsi untuk konfigurasi OpenVPN
get_openvpn_config() {
    print_header "================================================="
    print_header "           KONFIGURASI OPENVPN"
    print_header "================================================="
    
    if [ -f "/etc/openvpn/server/server.conf" ]; then
        local port=$(grep "^port " /etc/openvpn/server/server.conf | awk '{print $2}')
        local proto=$(grep "^proto " /etc/openvpn/server/server.conf | awk '{print $2}')
        local cipher=$(grep "^cipher " /etc/openvpn/server/server.conf | awk '{print $2}')
        local auth=$(grep "^auth " /etc/openvpn/server/server.conf | awk '{print $2}')
        local comp=$(grep "^compress " /etc/openvpn/server/server.conf | awk '{print $2}')
        
        echo "Config File     : /etc/openvpn/server/server.conf"
        echo "Listen Port     : $port"
        echo "Protocol        : $proto"
        echo "Cipher          : ${cipher:-AES-256-GCM}"
        echo "Auth Digest     : ${auth:-SHA512}"
        echo "Compression     : ${comp:-lz4-v2}"
        
        # Network settings
        local server_net=$(grep "^server " /etc/openvpn/server/server.conf | awk '{print $2, $3}')
        echo "VPN Network     : $server_net"
        
        # DNS settings
        echo ""
        print_info "DNS Settings:"
        grep "^push.*dhcp-option DNS" /etc/openvpn/server/server.conf | while read line; do
            dns=$(echo $line | awk '{print $3}' | tr -d '"')
            echo "  DNS Server: $dns"
        done
        
        # Routes
        echo ""
        print_info "Routes:"
        grep "^push.*route" /etc/openvpn/server/server.conf | while read line; do
            route=$(echo $line | cut -d'"' -f2)
            echo "  $route"
        done
    else
        print_error "OpenVPN configuration file not found!"
    fi
    
    echo ""
}

# Fungsi untuk status clients
get_client_status() {
    print_header "================================================="
    print_header "           STATUS CLIENTS"
    print_header "================================================="
    
    # Daftar certificates
    if [ -d "/etc/openvpn/server/easy-rsa/pki/issued" ]; then
        echo "Registered Clients:"
        local count=0
        for cert_file in /etc/openvpn/server/easy-rsa/pki/issued/*.crt; do
            if [ -f "$cert_file" ]; then
                local client_name=$(basename "$cert_file" .crt)
                if [ "$client_name" != "server" ]; then
                    count=$((count + 1))
                    echo "  $count. $client_name"
                    
                    # Check certificate validity
                    local expiry=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d'=' -f2)
                    echo "     Expires: $expiry"
                    
                    # Check if config file exists
                    if [ -f "/root/$client_name.ovpn" ]; then
                        echo "     Config : Available (/root/$client_name.ovpn)"
                    else
                        echo "     Config : Missing"
                    fi
                fi
            fi
        done
        
        if [ $count -eq 0 ]; then
            print_warning "No clients registered"
        fi
    else
        print_error "Certificate directory not found!"
    fi
    
    echo ""
    
    # Connected clients (jika ada status log)
    print_info "Connected Clients:"
    if [ -f "/var/log/openvpn/status.log" ]; then
        awk '/^CLIENT_LIST/{if(NR>1) print "  " $2 " (" $3 ") - Connected since: " $4 " " $5}' /var/log/openvpn/status.log 2>/dev/null || print_warning "No clients currently connected"
    elif [ -f "/var/log/openvpn.log" ]; then
        print_warning "Status log not available, checking main log..."
        tail -20 /var/log/openvpn.log | grep -i "connection.*established" | tail -5
    else
        print_warning "No connection status available"
    fi
    
    echo ""
}

# Fungsi untuk statistik traffic
get_traffic_stats() {
    print_header "================================================="
    print_header "           STATISTIK TRAFFIC"
    print_header "================================================="
    
    # Interface statistics
    local tun_interface=$(ip route | grep "10\." | head -1 | awk '{print $3}')
    if [ -n "$tun_interface" ]; then
        echo "TUN Interface   : $tun_interface"
        
        # Get interface stats
        local rx_bytes=$(cat /sys/class/net/$tun_interface/statistics/rx_bytes 2>/dev/null)
        local tx_bytes=$(cat /sys/class/net/$tun_interface/statistics/tx_bytes 2>/dev/null)
        local rx_packets=$(cat /sys/class/net/$tun_interface/statistics/rx_packets 2>/dev/null)
        local tx_packets=$(cat /sys/class/net/$tun_interface/statistics/tx_packets 2>/dev/null)
        
        if [ -n "$rx_bytes" ]; then
            echo "RX Bytes        : $(numfmt --to=iec $rx_bytes)"
            echo "TX Bytes        : $(numfmt --to=iec $tx_bytes)"
            echo "RX Packets      : $(printf "%'d" $rx_packets)"
            echo "TX Packets      : $(printf "%'d" $tx_packets)"
        fi
    else
        print_warning "TUN interface not found or not active"
    fi
    
    # Iptables rules stats (jika ada)
    echo ""
    print_info "Firewall Rules:"
    if command -v iptables >/dev/null; then
        iptables -L -n -v | grep -E "(openvpn|1194)" | head -5
    fi
    
    echo ""
}

# Fungsi untuk cek koneksi dan troubleshooting
check_connectivity() {
    print_header "================================================="
    print_header "           CONNECTIVITY CHECK"
    print_header "================================================="
    
    # Public IP
    echo "Public IP Check:"
    local public_ip=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "Unable to detect")
    echo "  Public IP: $public_ip"
    
    # DNS resolution
    echo ""
    echo "DNS Resolution Test:"
    if nslookup google.com >/dev/null 2>&1; then
        print_success "DNS resolution: OK"
    else
        print_error "DNS resolution: FAILED"
    fi
    
    # Internet connectivity
    echo ""
    echo "Internet Connectivity:"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connectivity: OK"
    else
        print_error "Internet connectivity: FAILED"
    fi
    
    # Port accessibility (dari luar)
    echo ""
    echo "Port Accessibility:"
    if [ -f "/etc/openvpn/server/server.conf" ]; then
        local port=$(grep "^port " /etc/openvpn/server/server.conf | awk '{print $2}')
        echo "  Checking port $port accessibility from external..."
        
        # Simple port check
        if timeout 5 bash -c "</dev/tcp/127.0.0.1/$port" 2>/dev/null; then
            print_success "Port $port is accessible locally"
        else
            print_warning "Port $port may not be accessible"
        fi
    fi
    
    echo ""
}

# Fungsi untuk log analysis
analyze_logs() {
    print_header "================================================="
    print_header "           LOG ANALYSIS"
    print_header "================================================="
    
    # Recent log entries
    echo "Recent OpenVPN Events (last 10):"
    if [ -f "/var/log/openvpn/openvpn.log" ]; then
        tail -10 /var/log/openvpn/openvpn.log
    elif journalctl -u openvpn-server@server --no-pager -n 10 >/dev/null 2>&1; then
        journalctl -u openvpn-server@server --no-pager -n 10 --since "1 hour ago"
    else
        print_warning "No OpenVPN logs found"
    fi
    
    echo ""
    
    # Error analysis
    echo "Recent Errors:"
    if [ -f "/var/log/openvpn/openvpn.log" ]; then
        grep -i "error\|failed\|warning" /var/log/openvpn/openvpn.log | tail -5
    elif journalctl -u openvpn-server@server --no-pager >/dev/null 2>&1; then
        journalctl -u openvpn-server@server --no-pager --since "1 hour ago" | grep -i "error\|failed\|warning" | tail -5
    fi
    
    echo ""
}

# Fungsi untuk generate laporan lengkap
generate_report() {
    local report_file="/root/openvpn-status-report-$(date +%Y%m%d_%H%M%S).txt"
    
    print_info "Generating comprehensive report..."
    
    {
        echo "OpenVPN Status Report"
        echo "Generated on: $(date)"
        echo "========================================"
        echo ""
        
        get_system_info
        get_openvpn_status
        get_openvpn_config
        get_client_status
        get_traffic_stats
        check_connectivity
        analyze_logs
        
    } > "$report_file"
    
    print_success "Report generated: $report_file"
}

# Fungsi untuk monitoring real-time
real_time_monitor() {
    print_header "================================================="
    print_header "         REAL-TIME MONITORING"
    print_header "         (Press Ctrl+C to exit)"
    print_header "================================================="
    
    while true; do
        clear
        echo "OpenVPN Real-time Monitor - $(date)"
        echo "========================================"
        
        # Service status
        if systemctl is-active --quiet openvpn-server@server; then
            print_success "Service: RUNNING"
        else
            print_error "Service: STOPPED"
        fi
        
        # Connected clients
        if [ -f "/var/log/openvpn/status.log" ]; then
            local connected=$(awk '/^CLIENT_LIST/{if(NR>1) count++} END{print count+0}' /var/log/openvpn/status.log)
            echo "Connected Clients: $connected"
        fi
        
        # Traffic stats
        local tun_interface=$(ip route | grep "10\." | head -1 | awk '{print $3}')
        if [ -n "$tun_interface" ]; then
            local rx_bytes=$(cat /sys/class/net/$tun_interface/statistics/rx_bytes 2>/dev/null)
            local tx_bytes=$(cat /sys/class/net/$tun_interface/statistics/tx_bytes 2>/dev/null)
            echo "Traffic RX: $(numfmt --to=iec $rx_bytes) | TX: $(numfmt --to=iec $tx_bytes)"
        fi
        
        # Recent connections
        echo ""
        echo "Recent Activity:"
        if [ -f "/var/log/openvpn/openvpn.log" ]; then
            tail -5 /var/log/openvpn/openvpn.log | cut -c1-80
        fi
        
        sleep 5
    done
}

# Fungsi untuk menampilkan bantuan
show_help() {
    echo "OpenVPN Status & Monitoring Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  status      Tampilkan status lengkap OpenVPN"
    echo "  system      Tampilkan informasi sistem"
    echo "  service     Tampilkan status service OpenVPN"
    echo "  config      Tampilkan konfigurasi OpenVPN"
    echo "  clients     Tampilkan status clients"
    echo "  traffic     Tampilkan statistik traffic"
    echo "  check       Cek konektivitas dan troubleshooting"
    echo "  logs        Analisis log OpenVPN"
    echo "  report      Generate laporan lengkap"
    echo "  monitor     Monitor real-time (Ctrl+C untuk keluar)"
    echo "  help        Tampilkan bantuan ini"
    echo ""
    echo "Default: Jika tidak ada command, akan menampilkan status lengkap"
}

# Main script logic
case "${1:-status}" in
    "status")
        get_system_info
        get_openvpn_status
        get_openvpn_config
        get_client_status
        ;;
    "system")
        get_system_info
        ;;
    "service")
        get_openvpn_status
        ;;
    "config")
        get_openvpn_config
        ;;
    "clients")
        get_client_status
        ;;
    "traffic")
        get_traffic_stats
        ;;
    "check")
        check_connectivity
        ;;
    "logs")
        analyze_logs
        ;;
    "report")
        generate_report
        ;;
    "monitor")
        real_time_monitor
        ;;
    "help"|*)
        show_help
        ;;
esac
