# 🎯 OpenVPN ByZ Management Suite

Selamat datang di **OpenVPN ByZ Management Suite** - solusi lengkap untuk mengelola OpenVPN server dengan mudah dan efisien!

## 📁 Struktur Direktori

```
/etc/openvpn-byz/
├── openvpn-byz           # Script utama (entry point)
├── scripts/              # Script management
│   ├── openvpn-manager.sh
│   ├── openvpn-auto-config.sh
│   ├── openvpn-email-manager.sh
│   └── openvpn-status.sh
├── configs/              # File konfigurasi
│   ├── openvpn-auto-config.conf
│   └── client-database.txt
├── templates/            # Template file
│   └── client-batch-template.txt
└── logs/                 # Log aktivitas
    └── openvpn-byz.log
```

## 🚀 Cara Penggunaan

### Menjalankan Suite Utama:
```bash
# Dari mana saja
openvpn-byz
# atau
ovpn-byz

# Atau langsung dari direktori
/etc/openvpn-byz/openvpn-byz
```

### Menjalankan Script Individual:
```bash
# Management interaktif
bash /etc/openvpn-byz/scripts/openvpn-manager.sh

# Konfigurasi otomatis
bash /etc/openvpn-byz/scripts/openvpn-auto-config.sh

# Email management
bash /etc/openvpn-byz/scripts/openvpn-email-manager.sh

# Status monitoring
bash /etc/openvpn-byz/scripts/openvpn-status.sh
```

## ⚙️ Konfigurasi

### File Konfigurasi Utama:
- **openvpn-auto-config.conf** - Konfigurasi untuk auto setup
- **client-database.txt** - Database client dan email

### Template:
- **client-batch-template.txt** - Template untuk pembuatan client masal

## 🔧 Fitur Suite

### 1. OpenVPN Manager
- ✅ Management interaktif server OpenVPN
- ✅ Tambah/hapus client dengan mudah
- ✅ Ubah port dan protokol
- ✅ Export konfigurasi client
- ✅ Regenerate semua client

### 2. Auto Configuration
- ✅ Setup otomatis dengan file config
- ✅ Batch client creation
- ✅ Update konfigurasi yang sudah ada
- ✅ Backup otomatis

### 3. Email Manager
- ✅ Integrasi SMTP untuk pengiriman email
- ✅ Template email professional
- ✅ Database client dengan email
- ✅ Pengiriman otomatis file .ovpn

### 4. Status Monitor
- ✅ Monitor real-time server dan client
- ✅ Informasi sistem lengkap
- ✅ Status koneksi client
- ✅ Performa network

## 📋 Requirements

- **Root access** - Script harus dijalankan sebagai root
- **OpenVPN** - Server OpenVPN harus sudah terinstall
- **Dependencies**: wget, curl, systemctl, iptables/firewall

## 🎨 Interface

Suite ini menggunakan interface yang colorful dan user-friendly dengan:
- 🎨 **Header bergaya** dengan border ASCII art
- 🌈 **Color coding** untuk berbagai jenis pesan
- 📋 **Menu interaktif** yang mudah digunakan
- 📊 **Progress indicator** dan status message

## 📞 Support & Info

- **Author**: ByNaz @ByNaz0801
- **Date**: July 14, 2025
- **GitHub**: https://github.com/ByNaz0801
- **Repository**: https://github.com/ByNaz0801/openvpn-installer

## 📝 Log Activity

Semua aktivitas dicatat dalam file log:
```bash
tail -f /etc/openvpn-byz/logs/openvpn-byz.log
```

---

**🔥 Dibuat dengan ❤️ untuk memudahkan management OpenVPN Server**

*Happy VPN-ing! 🚀*
