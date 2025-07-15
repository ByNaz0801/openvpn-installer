#!/bin/bash
#
# OpenVPN ByZ Management Suite Installer
# Script installer untuk setup OpenVPN ByZ Management Suite
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

print_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║              ${CYAN}OpenVPN ByZ Management Suite Installer${PURPLE}              ║${NC}"
    echo -e "${PURPLE}║                      ${YELLOW}Created by ByNaz @ByNaz0801${PURPLE}                      ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

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

check_root() {
    if [ "$(id -u)" != 0 ]; then
        print_error "Script ini harus dijalankan sebagai root."
        echo "Gunakan: sudo $0"
        exit 1
    fi
}

install_dependencies() {
    print_info "Menginstall dependencies yang diperlukan..."
    
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update >/dev/null 2>&1
        apt-get install -y wget curl git nano >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
        yum install -y wget curl git nano >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y wget curl git nano >/dev/null 2>&1
    else
        print_warning "Package manager tidak dikenali. Pastikan wget, curl, git, dan nano sudah terinstall."
    fi
}

create_directory_structure() {
    print_info "Membuat struktur direktori OpenVPN ByZ..."
    
    # Buat direktori utama
    mkdir -p /etc/openvpn-byz/{scripts,configs,templates,logs}
    
    # Set permission
    chmod 755 /etc/openvpn-byz
    chmod 755 /etc/openvpn-byz/{scripts,configs,templates,logs}
    
    print_success "Struktur direktori berhasil dibuat"
}

download_files() {
    print_info "Mendownload file OpenVPN ByZ dari GitHub..."
    
    # URL repository
    REPO_URL="https://raw.githubusercontent.com/ByNaz0801/openvpn-installer/main"
    
    # Download script utama
    wget -q -O /etc/openvpn-byz/openvpn-byz "$REPO_URL/openvpn-byz-main.sh"
    
    # Download script management
    wget -q -O /etc/openvpn-byz/scripts/openvpn-manager.sh "$REPO_URL/openvpn-manager.sh"
    wget -q -O /etc/openvpn-byz/scripts/openvpn-auto-config.sh "$REPO_URL/openvpn-auto-config.sh"
    wget -q -O /etc/openvpn-byz/scripts/openvpn-email-manager.sh "$REPO_URL/openvpn-email-manager.sh"
    wget -q -O /etc/openvpn-byz/scripts/openvpn-status.sh "$REPO_URL/openvpn-status.sh"
    
    # Download file konfigurasi dan template
    wget -q -O /etc/openvpn-byz/configs/openvpn-auto-config.conf "$REPO_URL/openvpn-auto-config.conf"
    wget -q -O /etc/openvpn-byz/templates/client-batch-template.txt "$REPO_URL/client-batch-template.txt"
    wget -q -O /etc/openvpn-byz/README.md "$REPO_URL/README-BYZ.md"
    
    print_success "File berhasil didownload"
}

update_script_paths() {
    print_info "Mengupdate path pada script..."
    
    # Update path pada auto-config script
    sed -i 's|CONFIG_FILE="/root/openvpn-install/openvpn-auto-config.conf"|CONFIG_FILE="/etc/openvpn-byz/configs/openvpn-auto-config.conf"|g' /etc/openvpn-byz/scripts/openvpn-auto-config.sh
    
    # Update path pada email manager
    sed -i 's|CLIENT_DB="/root/openvpn-install/client-database.txt"|CLIENT_DB="/etc/openvpn-byz/configs/client-database.txt"|g' /etc/openvpn-byz/scripts/openvpn-email-manager.sh
    sed -i 's|CONFIG_FILE="/root/openvpn-install/openvpn-auto-config.conf"|CONFIG_FILE="/etc/openvpn-byz/configs/openvpn-auto-config.conf"|g' /etc/openvpn-byz/scripts/openvpn-email-manager.sh
    
    print_success "Path berhasil diupdate"
}

set_permissions() {
    print_info "Mengatur permission file..."
    
    # Set executable untuk script
    chmod +x /etc/openvpn-byz/openvpn-byz
    chmod +x /etc/openvpn-byz/scripts/*.sh
    
    # Set permission untuk file konfigurasi
    chmod 644 /etc/openvpn-byz/configs/*
    chmod 644 /etc/openvpn-byz/templates/*
    
    print_success "Permission berhasil diatur"
}

create_symbolic_links() {
    print_info "Membuat symbolic link..."
    
    # Buat symbolic link ke /usr/local/bin
    ln -sf /etc/openvpn-byz/openvpn-byz /usr/local/bin/openvpn-byz
    ln -sf /etc/openvpn-byz/openvpn-byz /usr/local/bin/ovpn-byz
    
    print_success "Symbolic link berhasil dibuat"
}

show_completion_message() {
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ${CYAN}INSTALASI BERHASIL!${GREEN}                          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}🎉 OpenVPN ByZ Management Suite berhasil diinstall!${NC}"
    echo
    echo -e "${YELLOW}📍 Lokasi Instalasi:${NC}"
    echo "   📁 /etc/openvpn-byz/"
    echo
    echo -e "${YELLOW}🚀 Cara Penggunaan:${NC}"
    echo "   ${GREEN}openvpn-byz${NC}     # Menjalankan suite lengkap"
    echo "   ${GREEN}ovpn-byz${NC}        # Alias pendek"
    echo
    echo -e "${YELLOW}📚 Dokumentasi:${NC}"
    echo "   ${CYAN}cat /etc/openvpn-byz/README.md${NC}"
    echo
    echo -e "${YELLOW}📞 Support:${NC}"
    echo "   👨‍💻 Author: ByNaz @ByNaz0801"
    echo "   🔗 GitHub: https://github.com/ByNaz0801"
    echo
    echo -e "${CYAN}Selamat menggunakan OpenVPN ByZ Management Suite! 🚀${NC}"
    echo
}

main() {
    print_header
    
    echo -e "${CYAN}Installer ini akan menginstall OpenVPN ByZ Management Suite${NC}"
    echo -e "${CYAN}ke direktori /etc/openvpn-byz/ dengan semua dependensinya.${NC}"
    echo
    read -p "Lanjutkan instalasi? [Y/n]: " response
    case $response in
        [nN][oO]|[nN])
            echo "Instalasi dibatalkan."
            exit 0
            ;;
    esac
    
    echo
    print_info "Memulai instalasi OpenVPN ByZ Management Suite..."
    
    check_root
    install_dependencies
    create_directory_structure
    download_files
    update_script_paths
    set_permissions
    create_symbolic_links
    
    show_completion_message
}

main "$@"
