#!/bin/bash
#
# OpenVPN Auto Configuration Script
# Script untuk konfigurasi otomatis OpenVPN dengan parameter yang telah ditentukan
#
# Author: ByNaz @ByNaz0801
# Date: July 14, 2025
#

# File konfigurasi
CONFIG_FILE="/root/openvpn-install/openvpn-auto-config.conf"

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Fungsi untuk membuat file konfigurasi default
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
# OpenVPN Auto Configuration File
# Edit file ini sesuai kebutuhan Anda

# Pengaturan Server
SERVER_DOMAIN="your-domain.com"           # Domain atau IP public server
SERVER_PORT="1194"                        # Port OpenVPN (default: 1194)
SERVER_PROTOCOL="udp"                     # Protokol: udp atau tcp (default: udp)

# Pengaturan DNS untuk Client
DNS_SERVER_1="8.8.8.8"                   # Primary DNS (default: Google DNS)
DNS_SERVER_2="8.8.4.4"                   # Secondary DNS (default: Google DNS)

# Pengaturan Client Default
DEFAULT_CLIENT_NAME="client"              # Nama client default

# Pengaturan Tambahan
AUTO_RESTART_SERVICE="yes"               # Restart service otomatis setelah perubahan
BACKUP_CONFIG="yes"                      # Backup konfigurasi sebelum perubahan
REGENERATE_CLIENTS="yes"                 # Regenerate client configs setelah perubahan server

# Client Management
# Format: CLIENT_LIST="client1,client2,client3"
CLIENT_LIST=""                           # Daftar client yang akan dibuat (kosongkan jika tidak perlu)

# Firewall Management
MANAGE_FIREWALL="yes"                    # Kelola firewall otomatis
EOF

    print_success "File konfigurasi default dibuat: $CONFIG_FILE"
    print_info "Edit file tersebut sesuai kebutuhan Anda sebelum menjalankan auto-config"
}

# Fungsi untuk membaca konfigurasi
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "File konfigurasi tidak ditemukan. Membuat file default..."
        create_default_config
        return 1
    fi
    
    source "$CONFIG_FILE"
    print_info "Konfigurasi dimuat dari: $CONFIG_FILE"
}

# Fungsi untuk validasi konfigurasi
validate_config() {
    local errors=0
    
    # Validasi domain/IP
    if [ -z "$SERVER_DOMAIN" ] || [ "$SERVER_DOMAIN" = "your-domain.com" ]; then
        print_error "SERVER_DOMAIN harus diset dengan domain atau IP yang valid"
        errors=$((errors + 1))
    fi
    
    # Validasi port
    if [[ ! "$SERVER_PORT" =~ ^[0-9]+$ ]] || [ "$SERVER_PORT" -lt 1 ] || [ "$SERVER_PORT" -gt 65535 ]; then
        print_error "SERVER_PORT harus berupa angka antara 1-65535"
        errors=$((errors + 1))
    fi
    
    # Validasi protokol
    if [ "$SERVER_PROTOCOL" != "udp" ] && [ "$SERVER_PROTOCOL" != "tcp" ]; then
        print_error "SERVER_PROTOCOL harus 'udp' atau 'tcp'"
        errors=$((errors + 1))
    fi
    
    # Validasi DNS
    if ! [[ "$DNS_SERVER_1" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_error "DNS_SERVER_1 harus berupa IP address yang valid"
        errors=$((errors + 1))
    fi
    
    if ! [[ "$DNS_SERVER_2" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_error "DNS_SERVER_2 harus berupa IP address yang valid"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Fungsi untuk backup konfigurasi
backup_current_config() {
    if [ "$BACKUP_CONFIG" = "yes" ]; then
        local backup_dir="/root/openvpn-backups/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        
        if [ -f "/etc/openvpn/server/server.conf" ]; then
            cp "/etc/openvpn/server/server.conf" "$backup_dir/"
            print_info "Backup konfigurasi server: $backup_dir/server.conf"
        fi
        
        # Backup client configs
        for ovpn_file in /root/*.ovpn; do
            if [ -f "$ovpn_file" ]; then
                cp "$ovpn_file" "$backup_dir/"
            fi
        done
        
        print_success "Backup selesai di: $backup_dir"
    fi
}

# Fungsi untuk mengaplikasikan konfigurasi server
apply_server_config() {
    print_info "Mengaplikasikan konfigurasi server..."
    
    # Cek apakah OpenVPN sudah terinstall
    if [ ! -f "/etc/openvpn/server/server.conf" ]; then
        print_error "OpenVPN belum terinstall. Jalankan instalasi terlebih dahulu."
        return 1
    fi
    
    # Backup konfigurasi saat ini
    backup_current_config
    
    # Update port
    current_port=$(grep "^port " /etc/openvpn/server/server.conf | awk '{print $2}')
    if [ "$current_port" != "$SERVER_PORT" ]; then
        sed -i "s/^port $current_port/port $SERVER_PORT/" /etc/openvpn/server/server.conf
        print_info "Port diubah dari $current_port ke $SERVER_PORT"
        
        # Update firewall
        if [ "$MANAGE_FIREWALL" = "yes" ]; then
            update_firewall_rules "$current_port" "$SERVER_PORT"
        fi
    fi
    
    # Update protokol
    current_proto=$(grep "^proto " /etc/openvpn/server/server.conf | awk '{print $2}')
    if [ "$current_proto" != "$SERVER_PROTOCOL" ]; then
        sed -i "s/^proto $current_proto/proto $SERVER_PROTOCOL/" /etc/openvpn/server/server.conf
        print_info "Protokol diubah dari $current_proto ke $SERVER_PROTOCOL"
    fi
    
    # Update DNS servers
    sed -i "s/^push \"dhcp-option DNS .*/push \"dhcp-option DNS $DNS_SERVER_1\"/" /etc/openvpn/server/server.conf
    sed -i "/^push \"dhcp-option DNS $DNS_SERVER_1\"/a push \"dhcp-option DNS $DNS_SERVER_2\"" /etc/openvpn/server/server.conf
    
    # Remove duplicate DNS entries
    sed -i '/^push "dhcp-option DNS /s/^/#/' /etc/openvpn/server/server.conf
    sed -i "0,/^#push \"dhcp-option DNS /{s/^#push \"dhcp-option DNS .*/push \"dhcp-option DNS $DNS_SERVER_1\"/}" /etc/openvpn/server/server.conf
    sed -i "0,/^push \"dhcp-option DNS $DNS_SERVER_1\"/a push \"dhcp-option DNS $DNS_SERVER_2\"" /etc/openvpn/server/server.conf
    
    print_success "Konfigurasi server berhasil diaplikasikan"
}

# Fungsi untuk update firewall rules
update_firewall_rules() {
    local old_port=$1
    local new_port=$2
    
    print_info "Mengupdate firewall rules..."
    
    if command -v ufw >/dev/null; then
        # UFW (Ubuntu)
        ufw delete allow $old_port/udp 2>/dev/null
        ufw delete allow $old_port/tcp 2>/dev/null
        ufw allow $new_port/udp
        ufw allow $new_port/tcp
        print_info "UFW rules updated"
    elif command -v firewall-cmd >/dev/null; then
        # FirewallD (CentOS/RHEL/Fedora)
        firewall-cmd --remove-port=$old_port/udp --permanent 2>/dev/null
        firewall-cmd --remove-port=$old_port/tcp --permanent 2>/dev/null
        firewall-cmd --add-port=$new_port/udp --permanent
        firewall-cmd --add-port=$new_port/tcp --permanent
        firewall-cmd --reload
        print_info "FirewallD rules updated"
    elif command -v iptables >/dev/null; then
        # iptables (manual management)
        print_warning "Detected iptables. Please manually update rules for port $new_port"
    fi
}

# Fungsi untuk membuat clients otomatis
create_auto_clients() {
    if [ -n "$CLIENT_LIST" ]; then
        print_info "Membuat clients otomatis..."
        
        IFS=',' read -ra CLIENTS <<< "$CLIENT_LIST"
        for client in "${CLIENTS[@]}"; do
            # Sanitize client name
            clean_client=$(echo "$client" | sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g')
            
            # Cek apakah client sudah ada
            if [ ! -f "/etc/openvpn/server/easy-rsa/pki/issued/$clean_client.crt" ]; then
                print_info "Membuat client: $clean_client"
                if [ -f "/root/openvpn-install/openvpn-install.sh" ]; then
                    bash /root/openvpn-install/openvpn-install.sh --addclient "$clean_client"
                    
                    # Copy ke direktori backup jika berhasil
                    if [ -f "/root/$clean_client.ovpn" ]; then
                        mkdir -p "$CLIENT_BACKUP_DIR"
                        cp "/root/$clean_client.ovpn" "$CLIENT_BACKUP_DIR/"
                        print_info "Client backup disimpan: $CLIENT_BACKUP_DIR/$clean_client.ovpn"
                    fi
                fi
            else
                print_warning "Client '$clean_client' sudah ada, skip..."
            fi
        done
    fi
}

# Fungsi untuk regenerate semua client configs dengan pengaturan baru
regenerate_client_configs() {
    if [ "$REGENERATE_CLIENTS" = "yes" ]; then
        print_info "Meregenerasi konfigurasi clients dengan pengaturan baru..."
        
        # Backup client configs lama
        mkdir -p "/root/client_backup_$(date +%Y%m%d_%H%M%S)"
        for ovpn_file in /root/*.ovpn; do
            if [ -f "$ovpn_file" ]; then
                mv "$ovpn_file" "/root/client_backup_$(date +%Y%m%d_%H%M%S)/"
            fi
        done
        
        # Regenerate semua clients
        if [ -d "/etc/openvpn/server/easy-rsa/pki/issued" ]; then
            for cert_file in /etc/openvpn/server/easy-rsa/pki/issued/*.crt; do
                if [ -f "$cert_file" ]; then
                    client_name=$(basename "$cert_file" .crt)
                    if [ "$client_name" != "server" ]; then
                        print_info "Regenerating: $client_name"
                        if [ -f "/root/openvpn-install/openvpn-install.sh" ]; then
                            bash /root/openvpn-install/openvpn-install.sh --exportclient "$client_name"
                        fi
                        
                        # Update domain/IP di client config
                        if [ -f "/root/$client_name.ovpn" ]; then
                            sed -i "s/^remote .*/remote $SERVER_DOMAIN $SERVER_PORT/" "/root/$client_name.ovpn"
                        fi
                    fi
                fi
            done
        fi
        
        print_success "Semua konfigurasi client berhasil diregenerasi"
    fi
}

# Fungsi untuk restart service
restart_openvpn_service() {
    if [ "$AUTO_RESTART_SERVICE" = "yes" ]; then
        print_info "Merestart OpenVPN service..."
        systemctl restart openvpn-server@server
        
        if systemctl is-active --quiet openvpn-server@server; then
            print_success "OpenVPN service berhasil direstart"
        else
            print_error "Gagal merestart OpenVPN service"
            return 1
        fi
    fi
}

# Fungsi untuk menampilkan ringkasan konfigurasi
show_config_summary() {
    echo ""
    echo "================================================="
    echo "           RINGKASAN KONFIGURASI"
    echo "================================================="
    echo "Server Domain/IP    : $SERVER_DOMAIN"
    echo "Server Port         : $SERVER_PORT"
    echo "Server Protocol     : $SERVER_PROTOCOL"
    echo "Primary DNS         : $DNS_SERVER_1"
    echo "Secondary DNS       : $DNS_SERVER_2"
    echo "Default Client Name : $DEFAULT_CLIENT_NAME"
    echo "Auto Restart        : $AUTO_RESTART_SERVICE"
    echo "Backup Config       : $BACKUP_CONFIG"
    echo "Regenerate Clients  : $REGENERATE_CLIENTS"
    echo "Manage Firewall     : $MANAGE_FIREWALL"
    
    if [ -n "$CLIENT_LIST" ]; then
        echo "Clients to Create   : $CLIENT_LIST"
    fi
    echo "================================================="
    echo ""
}

# Fungsi untuk instalasi otomatis lengkap
auto_install() {
    print_info "Memulai instalasi otomatis OpenVPN..."
    
    # Jalankan instalasi OpenVPN dengan parameter dari config
    if [ -f "/root/openvpn-install/openvpn-install.sh" ]; then
        bash /root/openvpn-install/openvpn-install.sh --auto \
            --serveraddr "$SERVER_DOMAIN" \
            --proto "$SERVER_PROTOCOL" \
            --port "$SERVER_PORT" \
            --clientname "$DEFAULT_CLIENT_NAME" \
            --dns1 "$DNS_SERVER_1" \
            --dns2 "$DNS_SERVER_2"
    else
        print_error "Script openvpn-install.sh tidak ditemukan!"
        return 1
    fi
    
    # Buat clients tambahan jika ada
    create_auto_clients
    
    print_success "Instalasi otomatis selesai!"
}

# Fungsi utama untuk auto-config
auto_config() {
    print_info "Memulai auto-configuration OpenVPN..."
    
    # Load dan validasi konfigurasi
    if ! load_config; then
        print_error "Gagal memuat konfigurasi. Edit file $CONFIG_FILE terlebih dahulu."
        return 1
    fi
    
    if ! validate_config; then
        print_error "Konfigurasi tidak valid. Perbaiki error di atas."
        return 1
    fi
    
    # Tampilkan ringkasan
    show_config_summary
    
    # Konfirmasi
    echo -n "Lanjutkan dengan konfigurasi ini? (y/N): "
    read confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Auto-configuration dibatalkan."
        return 0
    fi
    
    # Aplikasikan konfigurasi
    apply_server_config
    create_auto_clients
    regenerate_client_configs
    restart_openvpn_service
    
    print_success "Auto-configuration selesai!"
    print_info "Konfigurasi client tersedia di /root/*.ovpn"
}

# Fungsi untuk menampilkan bantuan
show_help() {
    echo "OpenVPN Auto Configuration Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  auto-install     Instalasi OpenVPN lengkap dengan konfigurasi otomatis"
    echo "  auto-config      Aplikasikan konfigurasi otomatis ke OpenVPN yang sudah ada"
    echo "  create-config    Buat file konfigurasi default"
    echo "  validate-config  Validasi file konfigurasi"
    echo "  show-config      Tampilkan ringkasan konfigurasi"
    echo "  help             Tampilkan bantuan ini"
    echo ""
    echo "File konfigurasi: $CONFIG_FILE"
    echo ""
    echo "Contoh penggunaan:"
    echo "  $0 create-config    # Buat file konfigurasi default"
    echo "  # Edit $CONFIG_FILE sesuai kebutuhan"
    echo "  $0 auto-install    # Instalasi lengkap dengan konfigurasi otomatis"
    echo "  $0 auto-config     # Update konfigurasi server yang sudah ada"
}

# Main script logic
case "${1:-help}" in
    "auto-install")
        if [ "$(id -u)" != 0 ]; then
            print_error "Script ini harus dijalankan sebagai root. Gunakan 'sudo bash $0 auto-install'"
            exit 1
        fi
        auto_install
        ;;
    "auto-config")
        if [ "$(id -u)" != 0 ]; then
            print_error "Script ini harus dijalankan sebagai root. Gunakan 'sudo bash $0 auto-config'"
            exit 1
        fi
        auto_config
        ;;
    "create-config")
        create_default_config
        ;;
    "validate-config")
        if load_config; then
            if validate_config; then
                print_success "Konfigurasi valid!"
            else
                print_error "Konfigurasi tidak valid!"
                exit 1
            fi
        else
            exit 1
        fi
        ;;
    "show-config")
        if load_config; then
            show_config_summary
        fi
        ;;
    "help"|*)
        show_help
        ;;
esac
