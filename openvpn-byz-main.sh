#!/bin/bash
#
# OpenVPN ByZ Management Suite
# Script utama untuk mengelola OpenVPN dengan fitur tambahan
#
# Author: ByNaz @ByNaz0801
# Date: July 14, 2025
# Location: /etc/openvpn-byz/
#

# Definisi direktori
BYZ_HOME="/etc/openvpn-byz"
SCRIPTS_DIR="$BYZ_HOME/scripts"
CONFIGS_DIR="$BYZ_HOME/configs"
TEMPLATES_DIR="$BYZ_HOME/templates"
LOGS_DIR="$BYZ_HOME/logs"

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
    echo -e "${PURPLE}║                    ${CYAN}OpenVPN ByZ Management Suite${PURPLE}                    ║${NC}"
    echo -e "${PURPLE}║                      ${YELLOW}Created by ByNaz @ByNaz0801${PURPLE}                      ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_menu() {
    echo -e "${CYAN}📋 Menu Utama OpenVPN ByZ:${NC}"
    echo
    echo -e "${GREEN}🔧 Management Script:${NC}"
    echo -e "  ${YELLOW}1)${NC} OpenVPN Manager - Management interaktif server"
    echo -e "  ${YELLOW}2)${NC} Auto Config - Konfigurasi otomatis dari file"
    echo -e "  ${YELLOW}3)${NC} Email Manager - Kelola email client dan pengiriman"
    echo -e "  ${YELLOW}4)${NC} Status Monitor - Monitor status dan performa server"
    echo
    echo -e "${GREEN}⚙️  Konfigurasi:${NC}"
    echo -e "  ${YELLOW}5)${NC} Edit Config Auto - Edit file konfigurasi otomatis"
    echo -e "  ${YELLOW}6)${NC} Edit Template Batch - Edit template batch client"
    echo
    echo -e "${GREEN}📊 Info & Bantuan:${NC}"
    echo -e "  ${YELLOW}7)${NC} Lihat Log - Tampilkan log aktivitas"
    echo -e "  ${YELLOW}8)${NC} About - Info tentang OpenVPN ByZ Suite"
    echo
    echo -e "  ${YELLOW}0)${NC} Keluar"
    echo
}

run_manager() {
    echo -e "${BLUE}[INFO]${NC} Menjalankan OpenVPN Manager..."
    bash "$SCRIPTS_DIR/openvpn-manager.sh"
}

run_auto_config() {
    echo -e "${BLUE}[INFO]${NC} Menjalankan Auto Config..."
    bash "$SCRIPTS_DIR/openvpn-auto-config.sh"
}

run_email_manager() {
    echo -e "${BLUE}[INFO]${NC} Menjalankan Email Manager..."
    bash "$SCRIPTS_DIR/openvpn-email-manager.sh"
}

run_status_monitor() {
    echo -e "${BLUE}[INFO]${NC} Menjalankan Status Monitor..."
    bash "$SCRIPTS_DIR/openvpn-status.sh"
}

edit_auto_config() {
    echo -e "${BLUE}[INFO]${NC} Membuka editor untuk file konfigurasi..."
    if command -v nano >/dev/null 2>&1; then
        nano "$CONFIGS_DIR/openvpn-auto-config.conf"
    elif command -v vi >/dev/null 2>&1; then
        vi "$CONFIGS_DIR/openvpn-auto-config.conf"
    else
        echo -e "${RED}[ERROR]${NC} Editor tidak ditemukan. Install nano atau vi."
    fi
}

edit_batch_template() {
    echo -e "${BLUE}[INFO]${NC} Membuka editor untuk template batch client..."
    if command -v nano >/dev/null 2>&1; then
        nano "$TEMPLATES_DIR/client-batch-template.txt"
    elif command -v vi >/dev/null 2>&1; then
        vi "$TEMPLATES_DIR/client-batch-template.txt"
    else
        echo -e "${RED}[ERROR]${NC} Editor tidak ditemukan. Install nano atau vi."
    fi
}

show_logs() {
    echo -e "${BLUE}[INFO]${NC} Menampilkan log aktivitas..."
    if [ -f "$LOGS_DIR/openvpn-byz.log" ]; then
        echo -e "${CYAN}=== Log OpenVPN ByZ ===${NC}"
        tail -50 "$LOGS_DIR/openvpn-byz.log"
    else
        echo -e "${YELLOW}[WARNING]${NC} File log belum ada."
    fi
    echo
    read -p "Tekan Enter untuk kembali ke menu..."
}

show_about() {
    clear
    print_header
    echo -e "${CYAN}📖 Tentang OpenVPN ByZ Management Suite${NC}"
    echo
    echo -e "${GREEN}Deskripsi:${NC}"
    echo "  Suite management lengkap untuk OpenVPN server dengan fitur tambahan"
    echo "  yang memudahkan pengelolaan client, konfigurasi, dan monitoring."
    echo
    echo -e "${GREEN}Fitur Utama:${NC}"
    echo "  ✅ Management interaktif dengan menu yang user-friendly"
    echo "  ✅ Konfigurasi otomatis menggunakan file config"
    echo "  ✅ Email management dengan SMTP integration"
    echo "  ✅ Monitoring real-time server dan client"
    echo "  ✅ Batch client creation dari template"
    echo "  ✅ Backup otomatis file konfigurasi"
    echo
    echo -e "${GREEN}Lokasi File:${NC}"
    echo "  📁 Scripts     : $SCRIPTS_DIR"
    echo "  📁 Configs     : $CONFIGS_DIR"
    echo "  📁 Templates   : $TEMPLATES_DIR"
    echo "  📁 Logs        : $LOGS_DIR"
    echo
    echo -e "${GREEN}Author:${NC}"
    echo "  👨‍💻 ByNaz @ByNaz0801"
    echo "  📅 Date: July 14, 2025"
    echo "  🔗 GitHub: https://github.com/ByNaz0801"
    echo
    echo -e "${YELLOW}Dibuat dengan ❤️ untuk memudahkan management OpenVPN Server${NC}"
    echo
    read -p "Tekan Enter untuk kembali ke menu..."
}

log_activity() {
    local activity="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $activity" >> "$LOGS_DIR/openvpn-byz.log"
}

check_root() {
    if [ "$(id -u)" != 0 ]; then
        echo -e "${RED}[ERROR]${NC} Script ini harus dijalankan sebagai root."
        echo "Gunakan: sudo $0"
        exit 1
    fi
}

# Fungsi utama
main() {
    check_root
    
    # Pastikan direktori log ada
    mkdir -p "$LOGS_DIR"
    
    while true; do
        print_header
        print_menu
        
        read -p "Pilih opsi [0-8]: " choice
        
        case $choice in
            1)
                log_activity "Menjalankan OpenVPN Manager"
                run_manager
                ;;
            2)
                log_activity "Menjalankan Auto Config"
                run_auto_config
                ;;
            3)
                log_activity "Menjalankan Email Manager"
                run_email_manager
                ;;
            4)
                log_activity "Menjalankan Status Monitor"
                run_status_monitor
                ;;
            5)
                log_activity "Edit konfigurasi auto"
                edit_auto_config
                ;;
            6)
                log_activity "Edit template batch"
                edit_batch_template
                ;;
            7)
                show_logs
                ;;
            8)
                show_about
                ;;
            0)
                echo -e "${GREEN}Terima kasih telah menggunakan OpenVPN ByZ Suite!${NC}"
                log_activity "Keluar dari OpenVPN ByZ Suite"
                exit 0
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Pilihan tidak valid. Silakan pilih 0-8."
                sleep 2
                ;;
        esac
    done
}

# Jalankan fungsi utama
main "$@"
