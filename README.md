# 🎥 Jellyfin Backup Manager for Windows

**A smart, scriptable solution to back up, restore, and schedule Jellyfin server data.**  
Supports both admin and non-admin installs (ProgramData and LocalAppData).

---

## ✅ Features

- 🧠 Auto-detect Jellyfin data path
- 📦 Full backup (including config, metadata, and database)
- 🔄 Restore from any previous backup
- 📅 Schedule automatic backups (daily, weekly, monthly, yearly)
- 📂 Choose backup location (script folder or custom via UI)
- 🔒 Handles locked files by stopping Jellyfin service/process

---

## 💻 Requirements

- Windows 10/11
- PowerShell 5.1+
- Administrator permissions (for scheduled tasks)
- Jellyfin installed as either service or user process

---

## 🚀 How to Use

1. Clone or download this repo
2. Run `jellyfin_backup_manager.ps1` in PowerShell (as admin recommended)
3. Follow the on-screen menu prompts:

---

# 💬 Contact

For any questions or issues, feel free to contact me through my [GitHub profile](https://github.com/josh2kk/).


Made with 💙 by Josh2kk
