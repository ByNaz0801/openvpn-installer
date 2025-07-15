# OpenVPN Management Scripts

Kumpulan script untuk mengelola OpenVPN server setelah instalasi. Script ini menyediakan interface yang mudah untuk mengkustomisasi pengaturan OpenVPN secara otomatis.

## 📁 File yang Tersedia

### 1. `openvpn-manager.sh` - Script Management Interaktif
Script dengan menu interaktif untuk mengelola OpenVPN server.

**Fitur:**
- ✅ Tampilkan status OpenVPN
- ✅ Ubah port OpenVPN
- ✅ Ubah protokol (UDP/TCP)
- ✅ Ubah domain/IP server
- ✅ Tambah client baru
- ✅ Hapus client
- ✅ Export konfigurasi client
- ✅ Regenerate semua client
- ✅ Restart OpenVPN service

### 2. `openvpn-auto-config.sh` - Konfigurasi Otomatis
Script untuk konfigurasi otomatis menggunakan file konfigurasi.

**Fitur:**
- ✅ Instalasi otomatis dengan parameter custom
- ✅ Update konfigurasi server yang sudah ada
- ✅ Batch client creation
- ✅ Automatic backup
- ✅ Firewall management

### 3. `openvpn-status.sh` - Monitoring & Status
Script untuk monitoring dan analisis status OpenVPN.

**Fitur:**
- ✅ Status sistem dan service
- ✅ Informasi konfigurasi
- ✅ Status clients
- ✅ Statistik traffic
- ✅ Connectivity check
- ✅ Log analysis
- ✅ Real-time monitoring
- ✅ Generate report

## 🚀 Instalasi dan Setup

### 1. Persiapan
```bash
# Masuk ke direktori openvpn-install
cd /root/openvpn-install

# Buat semua script executable
chmod +x openvpn-manager.sh
chmod +x openvpn-auto-config.sh
chmod +x openvpn-status.sh
```

### 2. Install OpenVPN (jika belum)
```bash
# Install dengan pengaturan default
sudo ./openvpn-install.sh --auto

# Atau install dengan konfigurasi custom
sudo ./openvpn-auto-config.sh auto-install
```

## 📖 Panduan Penggunaan

### A. Menggunakan openvpn-manager.sh

Script interaktif dengan menu yang mudah digunakan:

```bash
sudo ./openvpn-manager.sh
```

**Menu yang tersedia:**
1. Tampilkan Status OpenVPN
2. Ubah Port OpenVPN
3. Ubah Protokol (UDP/TCP)
4. Ubah Domain/IP Server
5. Tambah Client Baru
6. Hapus Client
7. Export Konfigurasi Client
8. Regenerate Semua Client
9. Restart OpenVPN Service
10. Keluar

### B. Menggunakan openvpn-auto-config.sh

#### 1. Buat File Konfigurasi
```bash
./openvpn-auto-config.sh create-config
```

#### 2. Edit Konfigurasi
```bash
nano /root/openvpn-install/openvpn-auto-config.conf
```

**Contoh konfigurasi:**
```bash
# OpenVPN Auto Configuration File
SERVER_DOMAIN="vpn.mydomain.com"      # Domain atau IP public server
SERVER_PORT="1194"                    # Port OpenVPN
SERVER_PROTOCOL="udp"                 # Protokol: udp atau tcp
DNS_SERVER_1="8.8.8.8"              # Primary DNS
DNS_SERVER_2="8.8.4.4"              # Secondary DNS
DEFAULT_CLIENT_NAME="client"          # Nama client default
AUTO_RESTART_SERVICE="yes"           # Restart service otomatis
BACKUP_CONFIG="yes"                  # Backup konfigurasi
REGENERATE_CLIENTS="yes"             # Regenerate client configs
CLIENT_LIST="client1,client2,client3" # Daftar client yang akan dibuat
MANAGE_FIREWALL="yes"                # Kelola firewall otomatis
```

#### 3. Jalankan Auto-Config
```bash
# Untuk server yang belum install OpenVPN
sudo ./openvpn-auto-config.sh auto-install

# Untuk server yang sudah install OpenVPN
sudo ./openvpn-auto-config.sh auto-config
```

#### 4. Validasi Konfigurasi
```bash
./openvpn-auto-config.sh validate-config
./openvpn-auto-config.sh show-config
```

### C. Menggunakan openvpn-status.sh

#### 1. Status Lengkap
```bash
./openvpn-status.sh status
```

#### 2. Status Spesifik
```bash
./openvpn-status.sh system      # Info sistem
./openvpn-status.sh service     # Status service
./openvpn-status.sh config      # Konfigurasi
./openvpn-status.sh clients     # Status clients
./openvpn-status.sh traffic     # Statistik traffic
./openvpn-status.sh check       # Connectivity check
./openvpn-status.sh logs        # Analisis log
```

#### 3. Generate Report
```bash
./openvpn-status.sh report
```

#### 4. Real-time Monitoring
```bash
./openvpn-status.sh monitor     # Tekan Ctrl+C untuk keluar
```

## 🔧 Contoh Skenario Penggunaan

### Skenario 1: Setup Server Baru
```bash
# 1. Buat konfigurasi
./openvpn-auto-config.sh create-config

# 2. Edit konfigurasi sesuai kebutuhan
nano /root/openvpn-install/openvpn-auto-config.conf

# 3. Install dengan konfigurasi otomatis
sudo ./openvpn-auto-config.sh auto-install

# 4. Cek status
./openvpn-status.sh status
```

### Skenario 2: Ubah Port dari 1194 ke 443
```bash
# Menggunakan manager interaktif
sudo ./openvpn-manager.sh
# Pilih menu 2, masukkan port 443

# Atau menggunakan auto-config
# Edit file config, ubah SERVER_PORT="443"
sudo ./openvpn-auto-config.sh auto-config
```

### Skenario 3: Ubah dari UDP ke TCP
```bash
# Menggunakan manager interaktif
sudo ./openvpn-manager.sh
# Pilih menu 3, pilih TCP

# Atau menggunakan auto-config
# Edit file config, ubah SERVER_PROTOCOL="tcp"
sudo ./openvpn-auto-config.sh auto-config
```

### Skenario 4: Tambah Multiple Clients
```bash
# Menggunakan auto-config
# Edit file config: CLIENT_LIST="user1,user2,user3,admin"
sudo ./openvpn-auto-config.sh auto-config

# Atau menggunakan manager satu per satu
sudo ./openvpn-manager.sh
# Pilih menu 5 untuk setiap client
```

### Skenario 5: Monitoring Server
```bash
# Cek status cepat
./openvpn-status.sh service

# Monitor real-time
./openvpn-status.sh monitor

# Generate laporan lengkap
./openvpn-status.sh report
```

## 🛡️ Security & Backup

### Automatic Backup
Script akan otomatis membuat backup sebelum melakukan perubahan:
- Server config: `/root/openvpn-backups/YYYYMMDD_HHMMSS/`
- Client configs: `/root/client_backup_YYYYMMDD_HHMMSS/`

### Firewall Management
Script akan otomatis mengelola firewall rules untuk:
- UFW (Ubuntu)
- FirewallD (CentOS/RHEL/Fedora)
- Manual iptables (dengan warning)

### Certificate Management
- Validasi certificate expiry
- Automatic client certificate generation
- Revocation list management

## 🔍 Troubleshooting

### Masalah Umum

1. **Service tidak bisa start**
   ```bash
   ./openvpn-status.sh service
   ./openvpn-status.sh logs
   ```

2. **Client tidak bisa connect**
   ```bash
   ./openvpn-status.sh check
   ./openvpn-status.sh traffic
   ```

3. **Port tidak accessible**
   ```bash
   # Cek firewall
   sudo ufw status
   sudo firewall-cmd --list-all
   
   # Cek port listening
   netstat -tuln | grep 1194
   ```

4. **Configuration error**
   ```bash
   # Validasi config
   ./openvpn-auto-config.sh validate-config
   
   # Restore backup
   cp /root/openvpn-backups/LATEST/server.conf /etc/openvpn/server/
   sudo systemctl restart openvpn-server@server
   ```

### Log Files
- OpenVPN log: `/var/log/openvpn/openvpn.log`
- Status log: `/var/log/openvpn/status.log`
- Systemd journal: `journalctl -u openvpn-server@server`

## 📋 Requirements

- Ubuntu 20.04+ / Debian 10+ / CentOS 8+ / Fedora / openSUSE
- Root access atau sudo privileges
- OpenVPN server (akan diinstall otomatis jika belum ada)
- Internet connection
- Public IP address

## 🤝 Tips & Best Practices

1. **Backup Reguler**: Selalu backup konfigurasi sebelum perubahan besar
2. **Test Connectivity**: Gunakan `openvpn-status.sh check` setelah perubahan
3. **Monitor Logs**: Cek log secara berkala untuk deteksi dini masalah
4. **Update Clients**: Setelah ubah server config, regenerate semua client configs
5. **Firewall External**: Jangan lupa update firewall eksternal (AWS Security Groups, dll)
6. **Certificate Expiry**: Monitor expiry date certificates secara berkala

## 📞 Support

Jika mengalami masalah:

1. Cek status dengan `./openvpn-status.sh status`
2. Generate report dengan `./openvpn-status.sh report`
3. Periksa logs dengan `./openvpn-status.sh logs`
4. Cek connectivity dengan `./openvpn-status.sh check`

---

