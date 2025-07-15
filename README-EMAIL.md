# 📧 OpenVPN Email Management - Panduan Lengkap

## Fitur Baru yang Ditambahkan

✅ **Email Client Management** - Menyimpan email client dan mengirim konfigurasi otomatis
✅ **Automatic File Backup** - Copy file client ke direktori backup
✅ **Email Integration** - Terintegrasi dengan SMTP untuk pengiriman email
✅ **Client Database** - Database untuk tracking client dan email
✅ **Batch Client Creation** - Buat multiple client sekaligus dari file
✅ **Email Templates** - Template email professional untuk client

## 🔧 Setup Email Configuration

### 1. Setup Konfigurasi Email
```bash
cd /root/openvpn-install
./openvpn-email-manager.sh setup-email
```

**Informasi yang diperlukan:**
- SMTP Server (contoh: smtp.gmail.com, smtp.office365.com)
- SMTP Port (587 untuk TLS, 465 untuk SSL)
- Email pengirim
- Password email (untuk Gmail gunakan App Password)
- Nama pengirim
- Enkripsi (tls/ssl/none)

### 2. Konfigurasi File Auto-Config
Edit file `/root/openvpn-install/openvpn-auto-config.conf`:

```bash
# Email Configuration untuk mengirim file client
ENABLE_EMAIL="yes"                       # Aktifkan pengiriman email otomatis
SMTP_SERVER="smtp.gmail.com"            # SMTP server
SMTP_PORT="587"                          # SMTP port
SMTP_USER="your-email@gmail.com"        # Email pengirim
SMTP_PASS="your-app-password"           # Password atau app password
SMTP_FROM_NAME="OpenVPN Server"         # Nama pengirim
SMTP_ENCRYPTION="tls"                   # Enkripsi: tls, ssl, atau none

# Directory untuk menyimpan copy file client
CLIENT_BACKUP_DIR="/root/openvpn-clients" # Direktori backup file client
```

## 🚀 Cara Penggunaan

### A. Menggunakan Interactive Manager

```bash
sudo ./openvpn-manager.sh
```

Pilih menu **"10) Email Management"** untuk:
1. Setup Konfigurasi Email
2. Tambah Client dengan Email
3. Tampilkan Database Client
4. Kirim Ulang Email Client
5. Update Email Client
6. Test Konfigurasi Email
7. Batch Creation dari File
8. Buat Template Batch

### B. Menggunakan Email Manager Langsung

#### 1. Tambah Client dengan Email (Interactive)
```bash
sudo ./openvpn-email-manager.sh add
```

#### 2. Tambah Client Langsung (Quick)
```bash
sudo ./openvpn-email-manager.sh add-quick "username" "user@example.com" "Department Info"
```

#### 3. Batch Creation dari File
```bash
# Buat template
./openvpn-email-manager.sh template

# Edit file template
nano /root/openvpn-install/client-batch-template.txt

# Jalankan batch creation
sudo ./openvpn-email-manager.sh batch /root/openvpn-install/client-batch-template.txt
```

#### 4. Tampilkan Database Client
```bash
./openvpn-email-manager.sh show
```

#### 5. Kirim Ulang Email
```bash
./openvpn-email-manager.sh resend "client_name"
```

#### 6. Update Email Client
```bash
./openvpn-email-manager.sh update-email "client_name" "new-email@example.com"
```

#### 7. Test Email Configuration
```bash
./openvpn-email-manager.sh test-email
```

## 📁 File Structure

```
/root/openvpn-install/
├── openvpn-install.sh              # Script instalasi asli
├── openvpn-manager.sh              # Script management utama (UPDATE)
├── openvpn-auto-config.sh          # Script konfigurasi otomatis (UPDATE)
├── openvpn-email-manager.sh        # Script email management (BARU)
├── openvpn-status.sh               # Script monitoring
├── openvpn-auto-config.conf        # File konfigurasi (UPDATE)
├── client-database.txt             # Database client & email (BARU)
├── client-batch-template.txt       # Template batch creation (BARU)
└── README-MANAGEMENT.md            # Dokumentasi

/root/openvpn-clients/              # Direktori backup file client (BARU)
├── client1.ovpn
├── client2.ovpn
└── ...
```

## 📋 Format Batch File

File format untuk batch client creation:
```
# OpenVPN Client Batch Creation Template
# Format: client_name|email|info

user1|user1@company.com|Sales Department
user2|user2@company.com|IT Support  
admin|admin@company.com|System Administrator
mobile|mobile@company.com|Mobile Access
guest|guest@company.com|Guest Access - Valid until 2025-12-31
```

## 📧 Email Template

Email yang dikirim ke client berisi:
- **Subject**: "Konfigurasi OpenVPN - [client_name]"
- **Body**: Informasi lengkap server dan cara penggunaan
- **Attachment**: File .ovpn siap pakai

Contoh email:
```
Selamat!

Akun OpenVPN Anda telah berhasil dibuat dengan detail sebagai berikut:

Nama Client: user1
Server: your-domain.com
Port: 443
Protokol: tcp

Sales Department

File konfigurasi OpenVPN (.ovpn) terlampir dalam email ini.

Cara menggunakan:
1. Download file user1.ovpn yang terlampir
2. Install aplikasi OpenVPN Connect di device Anda
3. Import file .ovpn ke aplikasi OpenVPN Connect
4. Connect ke VPN

Terima kasih!

---
OpenVPN Server Administrator
```

## 🔒 Setup Gmail App Password

Untuk menggunakan Gmail SMTP:

1. **Enable 2-Factor Authentication** di akun Gmail
2. **Generate App Password**:
   - Masuk ke Google Account settings
   - Security → 2-Step Verification → App passwords
   - Pilih "Mail" dan device yang sesuai
   - Copy password yang dihasilkan
3. **Gunakan App Password** sebagai SMTP_PASS

## 🛠 Setup SMTP Providers

### Gmail
```bash
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
SMTP_ENCRYPTION="tls"
```

### Outlook/Hotmail
```bash
SMTP_SERVER="smtp-mail.outlook.com"
SMTP_PORT="587"
SMTP_ENCRYPTION="tls"
```

### Yahoo
```bash
SMTP_SERVER="smtp.mail.yahoo.com"
SMTP_PORT="587"
SMTP_ENCRYPTION="tls"
```

### Custom SMTP
```bash
SMTP_SERVER="mail.yourdomain.com"
SMTP_PORT="587"
SMTP_ENCRYPTION="tls"
```

## 📊 Database Client

Database client disimpan di `/root/openvpn-install/client-database.txt` dengan format:
```
Date Created|Client Name|Email|Info|File Location
2025-07-14 13:45:20|user1|user1@company.com|Sales Dept|/root/openvpn-clients/user1.ovpn
2025-07-14 13:46:15|admin|admin@company.com|Admin|/root/openvpn-clients/admin.ovpn
```

## 🎯 Contoh Skenario Lengkap

### Skenario 1: Setup Server Baru dengan Email
```bash
# 1. Setup server
sudo ./openvpn-auto-config.sh auto-install

# 2. Setup email
./openvpn-email-manager.sh setup-email

# 3. Tambah client dengan email
sudo ./openvpn-email-manager.sh add
```

### Skenario 2: Batch Creation untuk Team
```bash
# 1. Buat template
./openvpn-email-manager.sh template

# 2. Edit template dengan data team
nano /root/openvpn-install/client-batch-template.txt

# Content:
# john|john@company.com|Marketing Manager
# sarah|sarah@company.com|Sales Executive  
# mike|mike@company.com|IT Support
# admin|admin@company.com|System Administrator

# 3. Jalankan batch creation
sudo ./openvpn-email-manager.sh batch /root/openvpn-install/client-batch-template.txt
```

### Skenario 3: Update Konfigurasi Server & Regenerate
```bash
# 1. Update konfigurasi server (port, protokol, dll)
sudo ./openvpn-auto-config.sh auto-config

# 2. Kirim ulang konfigurasi ke semua client
./openvpn-email-manager.sh show  # Lihat daftar client
./openvpn-email-manager.sh resend "client1"
./openvpn-email-manager.sh resend "client2"
# dst...
```

## 🔍 Troubleshooting Email

### Problem: Email tidak terkirim
**Solution:**
1. Test konfigurasi: `./openvpn-email-manager.sh test-email`
2. Cek log: `tail -f /tmp/msmtp.log`
3. Verifikasi SMTP credentials
4. Pastikan firewall tidak block port SMTP

### Problem: Gmail authentication error
**Solution:**
1. Enable 2FA di Gmail
2. Generate App Password
3. Gunakan App Password, bukan password biasa

### Problem: File attachment terlalu besar
**Solution:**
File .ovpn biasanya kecil (<10KB), jika ada masalah:
1. Cek size file: `ls -la /root/*.ovpn`
2. Compress jika perlu: `gzip file.ovpn`

## 📈 Monitoring & Backup

### Backup Database
```bash
./openvpn-email-manager.sh backup
```

### Monitoring Email Activity
```bash
# Cek log email
tail -f /tmp/msmtp.log

# Cek database client
./openvpn-email-manager.sh show
```

### Backup Otomatis File Client
Semua file client otomatis di-backup ke `/root/openvpn-clients/`

---

**✨ OpenVPN Email Management System - Dibuat oleh ByNaz @ByNaz0801**
