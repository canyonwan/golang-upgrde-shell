# Go 语言一键升级脚本 / Go Upgrade Shell Script

本脚本可自动检测、下载并升级你的 Go 语言版本到最新版，支持 macOS (darwin-amd64)。  
This script automatically detects, downloads, and upgrades your Go installation to the latest version, supporting macOS (darwin-amd64).

---

## 特性 Features

- 自动检测当前 Go 版本和最新版本  
  Auto-detects current and latest Go versions
- 支持断点重试下载，自动切换备用下载源  
  Robust download with retry and mirror fallback
- 自动备份旧版本 Go 到 `~/.go_backups`  
  Automatically backs up old Go versions to `~/.go_backups`
- 自动配置环境变量 PATH  
  Automatically configures PATH environment variable
- 全过程中文提示，友好易用  
  User-friendly with Chinese prompts

---

## 使用方法 Usage

1. **下载脚本 Download the script**

   ```bash
   curl -O https://your-repo-url/golang-upgrade-shell.sh
   chmod +x golang-upgrade-shell.sh
   ```

2. **运行脚本 Run the script**

   ```bash
   ./golang-upgrade-shell.sh
   ```

   > 需要 sudo 权限。Sudo privileges required.

3. **重启终端或执行 source 以生效 PATH**  
   Restart your terminal or run `source ~/.zshrc` (or your shell profile) to update PATH.

---

## 注意事项 Notes

- 仅支持 macOS (darwin-amd64) 架构。  
  Only supports macOS (darwin-amd64) architecture.
- 旧版本 Go 会自动备份到 `~/.go_backups` 目录。  
  Old Go versions are backed up to `~/.go_backups`.
- 如遇网络问题，脚本会自动尝试备用下载源。  
  If network issues occur, the script will try a mirror download.

---

## 卸载 Uninstall

如需卸载 Go，可手动删除 `/usr/local/go` 目录：  
To uninstall Go, manually remove the `/usr/local/go` directory:

```bash
sudo rm -rf /usr/local/go
```


---

## 支持作者 Support the Author

如果本脚本对你有帮助，欢迎请作者喝一杯咖啡 ☕  
If you find this script helpful, feel free to buy me a coffee!

<img src="https://github.com/user-attachments/assets/cb49dc41-428f-4a97-8d01-167f864e48cb" alt="微信支付二维码" width="220" />



感谢你的支持！  
Thank you for your support!

## 免责声明 Disclaimer

本脚本仅供学习和个人使用，请自行承担使用风险。  
This script is for learning and personal use only. Use at your own risk.

---

欢迎反馈与改进建议！  
Feedback and suggestions are welcome!
