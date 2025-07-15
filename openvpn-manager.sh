#!/bin/bash
#
# OpenVPN Server Management Script
# Script untuk mengelola konfigurasi OpenVPN setelah instalasi
#
# Author: ByNaz @ByNaz0801
# Date: July 14, 2025
#

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fungsi untuk menampilkan pesan berwarna
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

# Cek apakah script dijalankan sebagai root
check_root() {
    if [ "$(id -u)" != 0 ]; then
        print_error "Script ini harus dijalankan sebagai root. Gunakan 'sudo bash $0'"
        exit 1
    fi
}

# Cek apakah OpenVPN sudah terinstall
check_openvpn_installed() {
    if [ ! -f "/etc/openvpn/server/server.conf" ]; then
        print_error "OpenVPN server tidak ditemukan. Pastikan OpenVPN sudah terinstall."
        exit 1
    fi
}

# Fungsi untuk menampilkan status OpenVPN
show_status() {
    print_info "Status OpenVPN Server:"
    echo "=========================="
    
    # Status service
    if systemctl is-active --quiet openvpn-server@server; then
        print_success "OpenVPN Service: RUNNING"
    else
        print_error "OpenVPN Service: STOPPED"
    fi
    
    # Port dan protokol saat ini
    current_port=$(grep "^port " /etc/openvpn/server/server.conf | awk '{print $2}')
    current_proto=$(grep "^proto " /etc/openvpn/server/server.conf | awk '{print $2}')
    
    echo "Port saat ini: $current_port"
    echo "Protokol saat ini: $current_proto"
    
    # Daftar client
    echo ""
    print_info "Daftar Client:"
    if [ -d "/etc/openvpn/server/easy-rsa/pki/issued" ]; then
        ls /etc/openvpn/server/easy-rsa/pki/issued/ | grep -v "server.crt" | sed 's/.crt$//' | nl
    fi
    echo "=========================="
}

# Fungsi untuk mengubah port
change_port() {
    current_port=$(grep "^port " /etc/openvpn/server/server.conf | awk '{print $2}')
    
    echo ""
    print_info "Port saat ini: $current_port"
    echo -n "Masukkan port baru (1-65535): "
    read new_port
    
    # Validasi port
    if [[ ! "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
        print_error "Port tidak valid. Harus berupa angka antara 1-65535."
        return 1
    fi
    
    # Backup konfigurasi
    cp /etc/openvpn/server/server.conf /etc/openvpn/server/server.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Ubah port di konfigurasi
    sed -i "s/^port $current_port/port $new_port/" /etc/openvpn/server/server.conf
    
    # Update firewall rules
    if command -v ufw >/dev/null; then
        ufw delete allow $current_port/udp 2>/dev/null
        ufw delete allow $current_port/tcp 2>/dev/null
        ufw allow $new_port/udp
        ufw allow $new_port/tcp
    elif command -v firewall-cmd >/dev/null; then
        firewall-cmd --remove-port=$current_port/udp --permanent 2>/dev/null
        firewall-cmd --remove-port=$current_port/tcp --permanent 2>/dev/null
        firewall-cmd --add-port=$new_port/udp --permanent
        firewall-cmd --add-port=$new_port/tcp --permanent
        firewall-cmd --reload
    fi
    
    # Restart OpenVPN
    systemctl restart openvpn-server@server
    
    print_success "Port berhasil diubah dari $current_port ke $new_port"
    print_warning "Pastikan untuk update firewall eksternal (AWS Security Groups, etc.) jika diperlukan"
}

# Fungsi untuk mengubah protokol
change_protocol() {
    current_proto=$(grep "^proto " /etc/openvpn/server/server.conf | awk '{print $2}')
    
    echo ""
    print_info "Protokol saat ini: $current_proto"
    echo "Pilih protokol baru:"
    echo "1) UDP (Recommended untuk performance)"
    echo "2) TCP (Recommended untuk firewall ketat)"
    echo -n "Pilihan (1-2): "
    read proto_choice
    
    case $proto_choice in
        1)
            new_proto="udp"
            ;;
        2)
            new_proto="tcp"
            ;;
        *)
            print_error "Pilihan tidak valid."
            return 1
            ;;
    esac
    
    if [ "$current_proto" = "$new_proto" ]; then
        print_warning "Protokol sudah menggunakan $new_proto"
        return 0
    fi
    
    # Backup konfigurasi
    cp /etc/openvpn/server/server.conf /etc/openvpn/server/server.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Ubah protokol di konfigurasi
    sed -i "s/^proto $current_proto/proto $new_proto/" /etc/openvpn/server/server.conf
    
    # Restart OpenVPN
    systemctl restart openvpn-server@server
    
    print_success "Protokol berhasil diubah dari $current_proto ke $new_proto"
    print_warning "Semua client perlu mengupdate konfigurasi mereka!"
}

# Fungsi untuk mengubah domain/IP server
change_server_address() {
    echo ""
    print_info "Mengubah alamat server (domain/IP) untuk client configurations"
    echo -n "Masukkan domain atau IP baru: "
    read new_address
    
    if [ -z "$new_address" ]; then
        print_error "Alamat tidak boleh kosong."
        return 1
    fi
    
    # Update semua konfigurasi client yang ada
    if [ -d "/root" ]; then
        for client_file in /root/*.ovpn; do
            if [ -f "$client_file" ]; then
                # Backup file client
                cp "$client_file" "${client_file}.backup.$(date +%Y%m%d_%H%M%S)"
                
                # Update alamat server
                sed -i "s/^remote .*/remote $new_address $(grep "^port " /etc/openvpn/server/server.conf | awk '{print $2}')/" "$client_file"
                
                client_name=$(basename "$client_file" .ovpn)
                print_info "Updated client config: $client_name"
            fi
        done
    fi
    
    print_success "Alamat server berhasil diubah ke: $new_address"
    print_warning "Client yang sudah ada perlu mendownload ulang konfigurasi mereka!"
}

# Fungsi untuk menambah client baru
add_client() {
    echo ""
    echo -n "Masukkan nama client baru: "
    read client_name
    
    if [ -z "$client_name" ]; then
        print_error "Nama client tidak boleh kosong."
        return 1
    fi
    
    # Tanya apakah ingin menambahkan email
    echo -n "Tambahkan email untuk client? (y/N): "
    read add_email
    
    client_email=""
    client_info=""
    
    if [[ "$add_email" =~ ^[Yy]$ ]]; then
        echo -n "Email client: "
        read client_email
        
        # Validasi email
        if [[ ! "$client_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            print_warning "Format email tidak valid, melanjutkan tanpa email"
            client_email=""
        else
            echo -n "Informasi tambahan (opsional): "
            read client_info
        fi
    fi
    
    # Sanitize client name
    client_name=$(echo "$client_name" | sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g')
    
    # Cek apakah client sudah ada
    if [ -f "/etc/openvpn/server/easy-rsa/pki/issued/$client_name.crt" ]; then
        print_error "Client '$client_name' sudah ada!"
        return 1
    fi
    
    print_info "Menambahkan client: $client_name"
    
    # Jalankan script asli untuk menambah client
    if [ -f "/root/openvpn-install/openvpn-install.sh" ]; then
        bash /root/openvpn-install/openvpn-install.sh --addclient "$client_name"
    else
        print_error "Script openvpn-install.sh tidak ditemukan!"
        return 1
    fi
    
    # Jika berhasil dan ada email, gunakan email manager
    if [ -f "/root/$client_name.ovpn" ] && [ -n "$client_email" ]; then
        print_info "Memproses email untuk client: $client_name"
        
        # Buat direktori backup jika belum ada
        CLIENT_BACKUP_DIR="/root/openvpn-clients"
        mkdir -p "$CLIENT_BACKUP_DIR"
        
        # Copy file ke direktori backup
        cp "/root/$client_name.ovpn" "$CLIENT_BACKUP_DIR/"
        
        # Simpan ke database
        CLIENT_DB="/root/openvpn-install/client-database.txt"
        echo "$(date '+%Y-%m-%d %H:%M:%S')|$client_name|$client_email|$client_info|$CLIENT_BACKUP_DIR/$client_name.ovpn" >> "$CLIENT_DB"
        
        print_info "File backup disimpan di: $CLIENT_BACKUP_DIR/$client_name.ovpn"
        
        # Cek apakah email manager tersedia dan konfigurasi email aktif
        if [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
            # Load konfigurasi email
            CONFIG_FILE="/root/openvpn-install/openvpn-auto-config.conf"
            if [ -f "$CONFIG_FILE" ]; then
                source "$CONFIG_FILE"
                if [ "$ENABLE_EMAIL" = "yes" ]; then
                    print_info "Mengirim email ke: $client_email"
                    bash /root/openvpn-install/openvpn-email-manager.sh add-quick "$client_name" "$client_email" "$client_info"
                else
                    print_warning "Pengiriman email tidak diaktifkan dalam konfigurasi"
                fi
            fi
        fi
    fi
    
    print_success "Client '$client_name' berhasil ditambahkan!"
    print_info "File konfigurasi tersimpan di: /root/$client_name.ovpn"
}

# Fungsi untuk menghapus client
remove_client() {
    echo ""
    print_info "Daftar client yang tersedia:"
    
    # Tampilkan daftar client
    if [ -d "/etc/openvpn/server/easy-rsa/pki/issued" ]; then
        ls /etc/openvpn/server/easy-rsa/pki/issued/ | grep -v "server.crt" | sed 's/.crt$//' | nl
    else
        print_error "Tidak ada client yang ditemukan."
        return 1
    fi
    
    echo ""
    echo -n "Masukkan nama client yang akan dihapus: "
    read client_name
    
    if [ -z "$client_name" ]; then
        print_error "Nama client tidak boleh kosong."
        return 1
    fi
    
    # Cek apakah client ada
    if [ ! -f "/etc/openvpn/server/easy-rsa/pki/issued/$client_name.crt" ]; then
        print_error "Client '$client_name' tidak ditemukan!"
        return 1
    fi
    
    # Konfirmasi penghapusan
    echo -n "Apakah Anda yakin ingin menghapus client '$client_name'? (y/N): "
    read confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Penghapusan dibatalkan."
        return 0
    fi
    
    print_info "Menghapus client: $client_name"
    
    # Jalankan script asli untuk menghapus client
    if [ -f "/root/openvpn-install/openvpn-install.sh" ]; then
        bash /root/openvpn-install/openvpn-install.sh --revokeclient "$client_name" -y
    else
        print_error "Script openvpn-install.sh tidak ditemukan!"
        return 1
    fi
    
    # Hapus file konfigurasi client jika ada
    if [ -f "/root/$client_name.ovpn" ]; then
        rm "/root/$client_name.ovpn"
    fi
    
    print_success "Client '$client_name' berhasil dihapus!"
}

# Fungsi untuk mengexport konfigurasi client
export_client() {
    echo ""
    print_info "Daftar client yang tersedia:"
    
    # Tampilkan daftar client
    if [ -d "/etc/openvpn/server/easy-rsa/pki/issued" ]; then
        ls /etc/openvpn/server/easy-rsa/pki/issued/ | grep -v "server.crt" | sed 's/.crt$//' | nl
    else
        print_error "Tidak ada client yang ditemukan."
        return 1
    fi
    
    echo ""
    echo -n "Masukkan nama client untuk export: "
    read client_name
    
    if [ -z "$client_name" ]; then
        print_error "Nama client tidak boleh kosong."
        return 1
    fi
    
    # Cek apakah client ada
    if [ ! -f "/etc/openvpn/server/easy-rsa/pki/issued/$client_name.crt" ]; then
        print_error "Client '$client_name' tidak ditemukan!"
        return 1
    fi
    
    print_info "Mengexport konfigurasi client: $client_name"
    
    # Jalankan script asli untuk export client
    if [ -f "/root/openvpn-install/openvpn-install.sh" ]; then
        bash /root/openvpn-install/openvpn-install.sh --exportclient "$client_name"
    else
        print_error "Script openvpn-install.sh tidak ditemukan!"
        return 1
    fi
    
    print_success "Konfigurasi client '$client_name' berhasil diexport!"
    print_info "File konfigurasi tersimpan di: /root/$client_name.ovpn"
}

# Fungsi untuk regenerate semua client dengan pengaturan baru
regenerate_all_clients() {
    echo ""
    print_warning "Fungsi ini akan meregenerasi semua konfigurasi client dengan pengaturan server terbaru."
    echo -n "Apakah Anda yakin ingin melanjutkan? (y/N): "
    read confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Regenerasi dibatalkan."
        return 0
    fi
    
    print_info "Meregenerasi semua konfigurasi client..."
    
    # Backup direktori client lama
    if [ -d "/root/client_backups" ]; then
        rm -rf "/root/client_backups"
    fi
    mkdir -p "/root/client_backups"
    
    # Backup file .ovpn yang ada
    for client_file in /root/*.ovpn; do
        if [ -f "$client_file" ]; then
            mv "$client_file" "/root/client_backups/"
        fi
    done
    
    # Regenerate semua client
    if [ -d "/etc/openvpn/server/easy-rsa/pki/issued" ]; then
        for cert_file in /etc/openvpn/server/easy-rsa/pki/issued/*.crt; do
            if [ -f "$cert_file" ]; then
                client_name=$(basename "$cert_file" .crt)
                if [ "$client_name" != "server" ]; then
                    print_info "Regenerating client: $client_name"
                    if [ -f "/root/openvpn-install/openvpn-install.sh" ]; then
                        bash /root/openvpn-install/openvpn-install.sh --exportclient "$client_name"
                    fi
                fi
            fi
        done
    fi
    
    print_success "Semua konfigurasi client berhasil diregenerasi!"
    print_info "Backup konfigurasi lama tersimpan di: /root/client_backups/"
}

# Fungsi untuk restart OpenVPN service
restart_service() {
    print_info "Merestart OpenVPN service..."
    systemctl restart openvpn-server@server
    
    if systemctl is-active --quiet openvpn-server@server; then
        print_success "OpenVPN service berhasil direstart!"
    else
        print_error "Gagal merestart OpenVPN service!"
        systemctl status openvpn-server@server
    fi
}

# Fungsi untuk email management
email_management() {
    clear
    echo "================================================="
    echo "              Email Management                   "
    echo "================================================="
    echo ""
    echo "1) Setup Konfigurasi Email"
    echo "2) Tambah Client dengan Email"
    echo "3) Tampilkan Database Client"
    echo "4) Kirim Ulang Email Client"
    echo "5) Update Email Client"
    echo "6) Test Konfigurasi Email"
    echo "7) Batch Creation dari File"
    echo "8) Buat Template Batch"
    echo "9) Kembali ke Menu Utama"
    echo ""
    echo -n "Pilih opsi (1-9): "
    read email_choice
    
    case $email_choice in
        1)
            if [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
                bash /root/openvpn-install/openvpn-email-manager.sh setup-email
            else
                print_error "Email manager script tidak ditemukan!"
            fi
            ;;
        2)
            if [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
                bash /root/openvpn-install/openvpn-email-manager.sh add
            else
                print_error "Email manager script tidak ditemukan!"
            fi
            ;;
        3)
            if [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
                bash /root/openvpn-install/openvpn-email-manager.sh show
            else
                print_error "Email manager script tidak ditemukan!"
            fi
            ;;
        4)
            echo -n "Masukkan nama client: "
            read client_name
            if [ -n "$client_name" ] && [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
                bash /root/openvpn-install/openvpn-email-manager.sh resend "$client_name"
            else
                print_error "Nama client tidak boleh kosong atau email manager tidak ditemukan!"
            fi
            ;;
        5)
            echo -n "Masukkan nama client: "
            read client_name
            echo -n "Masukkan email baru: "
            read new_email
            if [ -n "$client_name" ] && [ -n "$new_email" ] && [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
                bash /root/openvpn-install/openvpn-email-manager.sh update-email "$client_name" "$new_email"
            else
                print_error "Nama client dan email tidak boleh kosong!"
            fi
            ;;
        6)
            if [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
                bash /root/openvpn-install/openvpn-email-manager.sh test-email
            else
                print_error "Email manager script tidak ditemukan!"
            fi
            ;;
        7)
            echo -n "Masukkan path file batch: "
            read batch_file
            if [ -n "$batch_file" ] && [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
                bash /root/openvpn-install/openvpn-email-manager.sh batch "$batch_file"
            else
                print_error "Path file tidak boleh kosong atau email manager tidak ditemukan!"
            fi
            ;;
        8)
            if [ -f "/root/openvpn-install/openvpn-email-manager.sh" ]; then
                bash /root/openvpn-install/openvpn-email-manager.sh template
            else
                print_error "Email manager script tidak ditemukan!"
            fi
            ;;
        9)
            return 0
            ;;
        *)
            print_error "Pilihan tidak valid!"
            ;;
    esac
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke email menu..."
    read
    email_management
}

# Menu utama
show_menu() {
    clear
    echo "================================================="
    echo "         OpenVPN Server Management Script        "
    echo "================================================="
    echo ""
    echo "1)  Tampilkan Status OpenVPN"
    echo "2)  Ubah Port OpenVPN"
    echo "3)  Ubah Protokol (UDP/TCP)"
    echo "4)  Ubah Domain/IP Server"
    echo "5)  Tambah Client Baru"
    echo "6)  Hapus Client"
    echo "7)  Export Konfigurasi Client"
    echo "8)  Regenerate Semua Client"
    echo "9)  Restart OpenVPN Service"
    echo "10) Email Management"
    echo "11) Keluar"
    echo ""
    echo -n "Pilih opsi (1-11): "
}

# Main script
main() {
    check_root
    check_openvpn_installed
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                clear
                show_status
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            2)
                change_port
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            3)
                change_protocol
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            4)
                change_server_address
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            5)
                add_client
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            6)
                remove_client
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            7)
                export_client
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            8)
                regenerate_all_clients
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            9)
                restart_service
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
            10)
                email_management
                ;;
            11)
                print_info "Terima kasih telah menggunakan OpenVPN Manager!"
                exit 0
                ;;
            *)
                print_error "Pilihan tidak valid. Silakan pilih 1-11."
                echo ""
                echo -n "Tekan Enter untuk kembali ke menu..."
                read
                ;;
        esac
    done
}

# Jalankan script utama
main "$@"
