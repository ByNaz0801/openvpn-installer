#!/bin/bash
#
# OpenVPN Email Manager
# Script untuk mengelola email client dan pengiriman file konfigurasi OpenVPN
#
# Author: ByNaz @ByNaz0801
# Date: July 14, 2025
#

# Database file untuk menyimpan informasi client
CLIENT_DB="/root/openvpn-install/client-database.txt"
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

# Fungsi untuk memuat konfigurasi email
load_email_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        print_error "File konfigurasi tidak ditemukan: $CONFIG_FILE"
        return 1
    fi
}

# Fungsi untuk setup email configuration
setup_email_config() {
    print_info "Setup konfigurasi email untuk pengiriman otomatis..."
    
    echo -n "SMTP Server (contoh: smtp.gmail.com): "
    read smtp_server
    echo -n "SMTP Port (587 untuk TLS, 465 untuk SSL): "
    read smtp_port
    echo -n "Email pengirim: "
    read smtp_user
    echo -n "Password email (untuk Gmail gunakan App Password): "
    read -s smtp_pass
    echo ""
    echo -n "Nama pengirim: "
    read smtp_from_name
    echo -n "Enkripsi (tls/ssl/none): "
    read smtp_encryption
    
    # Update file konfigurasi
    sed -i "s/^SMTP_SERVER=.*/SMTP_SERVER=\"$smtp_server\"/" "$CONFIG_FILE"
    sed -i "s/^SMTP_PORT=.*/SMTP_PORT=\"$smtp_port\"/" "$CONFIG_FILE"
    sed -i "s/^SMTP_USER=.*/SMTP_USER=\"$smtp_user\"/" "$CONFIG_FILE"
    sed -i "s/^SMTP_PASS=.*/SMTP_PASS=\"$smtp_pass\"/" "$CONFIG_FILE"
    sed -i "s/^SMTP_FROM_NAME=.*/SMTP_FROM_NAME=\"$smtp_from_name\"/" "$CONFIG_FILE"
    sed -i "s/^SMTP_ENCRYPTION=.*/SMTP_ENCRYPTION=\"$smtp_encryption\"/" "$CONFIG_FILE"
    sed -i "s/^ENABLE_EMAIL=.*/ENABLE_EMAIL=\"yes\"/" "$CONFIG_FILE"
    
    print_success "Konfigurasi email berhasil disimpan!"
}

# Fungsi untuk mengirim email
send_email() {
    local recipient_email="$1"
    local client_name="$2"
    local attachment_file="$3"
    local client_info="$4"
    
    if [ "$ENABLE_EMAIL" != "yes" ]; then
        print_warning "Pengiriman email tidak diaktifkan"
        return 0
    fi
    
    # Cek apakah mailx atau sendmail tersedia
    if ! command -v mail >/dev/null && ! command -v sendmail >/dev/null && ! command -v msmtp >/dev/null; then
        print_warning "Installing mail utilities..."
        if command -v apt-get >/dev/null; then
            apt-get update >/dev/null 2>&1
            apt-get install -y mailutils msmtp msmtp-mta >/dev/null 2>&1
        elif command -v yum >/dev/null; then
            yum install -y mailx msmtp >/dev/null 2>&1
        elif command -v dnf >/dev/null; then
            dnf install -y mailx msmtp >/dev/null 2>&1
        fi
    fi
    
    # Setup msmtp configuration
    setup_msmtp_config
    
    # Buat email body
    local email_body=$(cat << EOF
Selamat!

Akun OpenVPN Anda telah berhasil dibuat dengan detail sebagai berikut:

Nama Client: $client_name
Server: $SERVER_DOMAIN
Port: $SERVER_PORT
Protokol: $SERVER_PROTOCOL

$client_info

File konfigurasi OpenVPN (.ovpn) terlampir dalam email ini.

Cara menggunakan:
1. Download file $client_name.ovpn yang terlampir
2. Install aplikasi OpenVPN Connect di device Anda
3. Import file .ovpn ke aplikasi OpenVPN Connect
4. Connect ke VPN

Terima kasih!

---
OpenVPN Server Administrator
ByNaz @ByNaz0801
EOF
)
    
    # Kirim email dengan attachment
    if command -v msmtp >/dev/null; then
        # Menggunakan msmtp
        {
            echo "To: $recipient_email"
            echo "From: $SMTP_FROM_NAME <$SMTP_USER>"
            echo "Subject: Konfigurasi OpenVPN - $client_name"
            echo "MIME-Version: 1.0"
            echo "Content-Type: multipart/mixed; boundary=\"boundary123\""
            echo ""
            echo "--boundary123"
            echo "Content-Type: text/plain; charset=utf-8"
            echo ""
            echo "$email_body"
            echo ""
            echo "--boundary123"
            echo "Content-Type: application/octet-stream"
            echo "Content-Disposition: attachment; filename=\"$client_name.ovpn\""
            echo "Content-Transfer-Encoding: base64"
            echo ""
            base64 "$attachment_file"
            echo ""
            echo "--boundary123--"
        } | msmtp "$recipient_email"
        
        if [ $? -eq 0 ]; then
            print_success "Email berhasil dikirim ke: $recipient_email"
        else
            print_error "Gagal mengirim email ke: $recipient_email"
        fi
    else
        print_error "Mail utility tidak tersedia untuk mengirim email"
    fi
}

# Fungsi untuk setup msmtp configuration
setup_msmtp_config() {
    local msmtp_config="/root/.msmtprc"
    
    cat > "$msmtp_config" << EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /tmp/msmtp.log

account        default
host           $SMTP_SERVER
port           $SMTP_PORT
from           $SMTP_USER
user           $SMTP_USER
password       $SMTP_PASS
EOF

    if [ "$SMTP_ENCRYPTION" = "ssl" ]; then
        echo "tls_starttls   off" >> "$msmtp_config"
    elif [ "$SMTP_ENCRYPTION" = "none" ]; then
        sed -i 's/tls            on/tls            off/' "$msmtp_config"
    fi
    
    chmod 600 "$msmtp_config"
}

# Fungsi untuk menambah client dengan email
add_client_with_email() {
    local client_name="$1"
    local client_email="$2"
    local client_info="$3"
    
    # Buat direktori backup jika belum ada
    mkdir -p "$CLIENT_BACKUP_DIR"
    
    # Sanitize client name
    client_name=$(echo "$client_name" | sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g')
    
    # Cek apakah client sudah ada
    if [ -f "/etc/openvpn/server/easy-rsa/pki/issued/$client_name.crt" ]; then
        print_error "Client '$client_name' sudah ada!"
        return 1
    fi
    
    print_info "Membuat client: $client_name"
    
    # Jalankan script asli untuk menambah client
    if [ -f "/root/openvpn-install/openvpn-install.sh" ]; then
        bash /root/openvpn-install/openvpn-install.sh --addclient "$client_name"
    else
        print_error "Script openvpn-install.sh tidak ditemukan!"
        return 1
    fi
    
    # Cek apakah file client berhasil dibuat
    if [ -f "/root/$client_name.ovpn" ]; then
        # Copy file ke direktori backup
        cp "/root/$client_name.ovpn" "$CLIENT_BACKUP_DIR/"
        
        # Simpan informasi client ke database
        echo "$(date '+%Y-%m-%d %H:%M:%S')|$client_name|$client_email|$client_info|$CLIENT_BACKUP_DIR/$client_name.ovpn" >> "$CLIENT_DB"
        
        print_success "Client '$client_name' berhasil dibuat!"
        print_info "File backup disimpan di: $CLIENT_BACKUP_DIR/$client_name.ovpn"
        
        # Kirim email jika diaktifkan
        if [ "$ENABLE_EMAIL" = "yes" ] && [ -n "$client_email" ]; then
            print_info "Mengirim email ke: $client_email"
            send_email "$client_email" "$client_name" "/root/$client_name.ovpn" "$client_info"
        fi
        
        return 0
    else
        print_error "Gagal membuat file konfigurasi client!"
        return 1
    fi
}

# Fungsi untuk menampilkan database client
show_client_database() {
    print_info "Database Client OpenVPN:"
    echo "========================================"
    
    if [ ! -f "$CLIENT_DB" ]; then
        print_warning "Database client kosong"
        return 0
    fi
    
    echo "Date Created | Client Name | Email | Info | File Location"
    echo "----------------------------------------------------------------------"
    
    while IFS='|' read -r date name email info file_path; do
        echo "$date | $name | $email | $info | $file_path"
    done < "$CLIENT_DB"
    
    echo "========================================"
}

# Fungsi untuk resend email client
resend_client_email() {
    local client_name="$1"
    
    if [ ! -f "$CLIENT_DB" ]; then
        print_error "Database client tidak ditemukan"
        return 1
    fi
    
    # Cari client dalam database
    local client_info=$(grep "|$client_name|" "$CLIENT_DB" | tail -1)
    
    if [ -z "$client_info" ]; then
        print_error "Client '$client_name' tidak ditemukan dalam database"
        return 1
    fi
    
    # Parse informasi client
    local email=$(echo "$client_info" | cut -d'|' -f3)
    local info=$(echo "$client_info" | cut -d'|' -f4)
    local file_path=$(echo "$client_info" | cut -d'|' -f5)
    
    if [ ! -f "$file_path" ]; then
        print_error "File konfigurasi tidak ditemukan: $file_path"
        return 1
    fi
    
    print_info "Mengirim ulang email untuk client: $client_name"
    send_email "$email" "$client_name" "$file_path" "$info"
}

# Fungsi untuk update email client
update_client_email() {
    local client_name="$1"
    local new_email="$2"
    
    if [ ! -f "$CLIENT_DB" ]; then
        print_error "Database client tidak ditemukan"
        return 1
    fi
    
    # Update email dalam database
    sed -i "s/|$client_name|.*|/|$client_name|$new_email|/" "$CLIENT_DB"
    
    print_success "Email client '$client_name' berhasil diupdate ke: $new_email"
}

# Fungsi untuk test email configuration
test_email_config() {
    load_email_config
    
    echo -n "Masukkan email untuk test: "
    read test_email
    
    if [ -z "$test_email" ]; then
        print_error "Email tidak boleh kosong"
        return 1
    fi
    
    print_info "Mengirim test email ke: $test_email"
    
    # Buat temporary file untuk test
    local temp_file="/tmp/test_openvpn.txt"
    echo "This is a test file from OpenVPN Email Manager" > "$temp_file"
    
    send_email "$test_email" "test-client" "$temp_file" "This is a test email"
    
    rm -f "$temp_file"
}

# Fungsi untuk interactive client creation
interactive_client_creation() {
    load_email_config
    
    echo ""
    print_info "Membuat Client OpenVPN Baru dengan Email"
    echo "=========================================="
    
    echo -n "Nama client: "
    read client_name
    
    if [ -z "$client_name" ]; then
        print_error "Nama client tidak boleh kosong"
        return 1
    fi
    
    echo -n "Email client: "
    read client_email
    
    # Validasi email
    if [[ ! "$client_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        print_error "Format email tidak valid"
        return 1
    fi
    
    echo -n "Informasi tambahan (opsional): "
    read client_info
    
    # Konfirmasi
    echo ""
    echo "Konfirmasi pembuatan client:"
    echo "Nama: $client_name"
    echo "Email: $client_email"
    echo "Info: $client_info"
    echo -n "Lanjutkan? (y/N): "
    read confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Pembuatan client dibatalkan"
        return 0
    fi
    
    add_client_with_email "$client_name" "$client_email" "$client_info"
}

# Fungsi untuk batch client creation dari file
batch_client_creation() {
    local batch_file="$1"
    
    if [ ! -f "$batch_file" ]; then
        print_error "File batch tidak ditemukan: $batch_file"
        return 1
    fi
    
    load_email_config
    
    print_info "Memproses batch client creation dari: $batch_file"
    
    # Format file: client_name|email|info
    while IFS='|' read -r client_name email info; do
        if [ -n "$client_name" ] && [ -n "$email" ]; then
            print_info "Processing: $client_name"
            add_client_with_email "$client_name" "$email" "$info"
            echo ""
        fi
    done < "$batch_file"
    
    print_success "Batch client creation selesai!"
}

# Fungsi untuk create batch template
create_batch_template() {
    local template_file="/root/openvpn-install/client-batch-template.txt"
    
    cat > "$template_file" << 'EOF'
# OpenVPN Client Batch Creation Template
# Format: client_name|email|info
# Contoh:
user1|user1@example.com|Marketing Department
user2|user2@example.com|IT Support
admin|admin@company.com|System Administrator
mobile_user|mobile@example.com|Mobile Access
guest|guest@company.com|Guest Access - Valid until 2025-12-31
EOF

    print_success "Template batch file dibuat: $template_file"
    print_info "Edit file tersebut dan jalankan: $0 batch $template_file"
}

# Fungsi untuk backup database
backup_database() {
    if [ -f "$CLIENT_DB" ]; then
        local backup_file="$CLIENT_DB.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$CLIENT_DB" "$backup_file"
        print_success "Database di-backup ke: $backup_file"
    else
        print_warning "Database tidak ditemukan untuk di-backup"
    fi
}

# Fungsi untuk menampilkan bantuan
show_help() {
    echo "OpenVPN Email Manager"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  add                     Tambah client baru secara interaktif"
    echo "  add-quick <name> <email> [info]  Tambah client langsung"
    echo "  show                    Tampilkan database client"
    echo "  resend <client_name>    Kirim ulang email client"
    echo "  update-email <client> <email>  Update email client"
    echo "  test-email              Test konfigurasi email"
    echo "  setup-email             Setup konfigurasi email"
    echo "  batch <file>            Batch creation dari file"
    echo "  template                Buat template batch file"
    echo "  backup                  Backup database client"
    echo "  help                    Tampilkan bantuan ini"
    echo ""
    echo "Files:"
    echo "  Database: $CLIENT_DB"
    echo "  Config: $CONFIG_FILE"
    echo "  Backup Dir: $CLIENT_BACKUP_DIR"
    echo ""
    echo "Contoh penggunaan:"
    echo "  $0 add                  # Interactive client creation"
    echo "  $0 add-quick john john@example.com \"Sales Team\""
    echo "  $0 batch /path/to/clients.txt"
    echo "  $0 resend john"
}

# Main script logic
case "${1:-help}" in
    "add")
        if [ "$(id -u)" != 0 ]; then
            print_error "Script ini harus dijalankan sebagai root"
            exit 1
        fi
        interactive_client_creation
        ;;
    "add-quick")
        if [ "$(id -u)" != 0 ]; then
            print_error "Script ini harus dijalankan sebagai root"
            exit 1
        fi
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Usage: $0 add-quick <client_name> <email> [info]"
            exit 1
        fi
        load_email_config
        add_client_with_email "$2" "$3" "$4"
        ;;
    "show")
        show_client_database
        ;;
    "resend")
        if [ -z "$2" ]; then
            print_error "Usage: $0 resend <client_name>"
            exit 1
        fi
        load_email_config
        resend_client_email "$2"
        ;;
    "update-email")
        if [ -z "$2" ] || [ -z "$3" ]; then
            print_error "Usage: $0 update-email <client_name> <new_email>"
            exit 1
        fi
        update_client_email "$2" "$3"
        ;;
    "test-email")
        test_email_config
        ;;
    "setup-email")
        setup_email_config
        ;;
    "batch")
        if [ "$(id -u)" != 0 ]; then
            print_error "Script ini harus dijalankan sebagai root"
            exit 1
        fi
        if [ -z "$2" ]; then
            print_error "Usage: $0 batch <batch_file>"
            exit 1
        fi
        batch_client_creation "$2"
        ;;
    "template")
        create_batch_template
        ;;
    "backup")
        backup_database
        ;;
    "help"|*)
        show_help
        ;;
esac
