#!/bin/bash

set -euo pipefail

# Check if we have sudo access
check_sudo() {
  if ! sudo -n true 2>/dev/null; then
    echo "⚠️ 此脚本需要 sudo 权限来安装 Go。"
    echo "请输入密码（如果提示）："
    if ! sudo true; then
      echo "❌ 无法获取 sudo 权限，安装失败。"
      return 1
    fi
  fi
  return 0
}

# 定义清理函数
cleanup() {
  local tarball_file="$1"
  if [ -f "$tarball_file" ]; then
    echo "🧹 清理临时文件..."
    rm -f "$tarball_file"
  fi
}

# 配置
GO_INSTALL_DIR="/usr/local/go"
BACKUP_DIR="$HOME/.go_backups"

# 检测用户的 shell 配置文件
detect_profile_file() {
  local shell_name
  shell_name="$(basename "$SHELL")"
  
  case "$shell_name" in
    "zsh")
      if [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
      else
        echo "$HOME/.profile"
      fi
      ;;
    "bash")
      if [ -f "$HOME/.bash_profile" ]; then
        echo "$HOME/.bash_profile"
      elif [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
      else
        echo "$HOME/.profile"
      fi
      ;;
    *)
      echo "$HOME/.profile"
      ;;
  esac
}

# 获取当前版本
get_current_version() {
  if command -v go &> /dev/null; then
    go version | awk '{print $3}'
  else
    echo "未安装"
  fi
}

# 获取最新版本
get_latest_version() {
  # Fetch version and extract only the go version part
  local raw_version
  raw_version=$(curl -s https://go.dev/VERSION?m=text)
  
  # Extract only the "goX.Y.Z" part using grep
  if [[ "$raw_version" =~ go[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "${BASH_REMATCH[0]}"
  else
    echo "Failed to parse version from: $raw_version" >&2
    echo "go0.0.0" # Return a default version to prevent script failure
  fi
}

# 下载文件（带重试）
download_with_retry() {
  local url="$1"
  local output_file="$2"
  local max_retries=3
  local retry_count=0
  local alt_url=""

  # Setup alternative URL using Google's download mirror
  if [[ "$url" == *"go.dev/dl/"* ]]; then
    alt_url="${url/go.dev\/dl\//dl.google.com/go/}"
  fi

  while [ $retry_count -lt $max_retries ]; do
    echo "📥 尝试下载 (尝试 $((retry_count+1))/$max_retries)..."
    
    # First try the primary URL
    if curl -L --retry 3 --retry-delay 2 -f -o "$output_file" "$url" --progress-bar; then
      echo "✅ 下载成功"
      return 0
    fi
    
    # If we have an alternative URL and this isn't the last retry, try the alternative
    if [ -n "$alt_url" ] && [ $retry_count -lt $((max_retries-1)) ]; then
      echo "🔄 尝试替代链接: $alt_url"
      if curl -L --retry 3 --retry-delay 2 -f -o "$output_file" "$alt_url" --progress-bar; then
        echo "✅ 从替代链接下载成功"
        return 0
      fi
    fi
    
    retry_count=$((retry_count+1))
    if [ $retry_count -lt $max_retries ]; then
      echo "⏳ 等待 3 秒后重试..."
      sleep 3
    fi
  done
  
  echo "❌ 下载失败，所有尝试均已失败"
  return 1
}

# Validate version format
is_valid_version() {
  local version="$1"
  [[ "$version" =~ ^go[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

install_go() {
  local version="$1"
  
  # Validate version format
  if ! is_valid_version "$version"; then
    echo "❌ 无效的版本格式: $version"
    echo "版本应该类似于: go1.24.2"
    return 1
  fi
  
  local version_num="${version#go}"
  
  # Construct filenames and URLs carefully to avoid timestamp interference
  local go_tarball_filename="go${version_num}.darwin-amd64.tar.gz"
  local go_download_url="https://go.dev/dl/${go_tarball_filename}"

  # Set cleanup trap with properly quoted variable
  trap "cleanup \"$go_tarball_filename\"" EXIT

  echo "📥 正在下载 Go ${version_num} (${go_tarball_filename})..."

  # Download using our retry function
  if ! download_with_retry "$go_download_url" "$go_tarball_filename"; then
    echo "❌ 下载失败，可能是网络问题。请尝试："
    echo "  1. 检查您的网络连接"
    echo "  2. 手动下载: $go_download_url"
    echo "  3. 或尝试替代链接: ${go_download_url/go.dev\/dl\//dl.google.com/go/}"
    return 1
  fi

  echo "🧹 备份旧版本..."
  if [ -d "$GO_INSTALL_DIR" ]; then
    # Ensure backup directory exists with proper permissions
    if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
      sudo mkdir -p "$BACKUP_DIR"
      sudo chown "$(whoami)" "$BACKUP_DIR"
    fi
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/go_backup_$timestamp"
    
    # Use sudo to move the old Go installation
    if ! sudo mv "$GO_INSTALL_DIR" "$backup_path"; then
      echo "❌ 备份旧版本失败，可能是权限问题"
      return 1
    fi
    echo "✅ 旧版本已备份到 $backup_path"
  fi

  echo "📦 正在安装 $version..."
  if ! sudo tar -C /usr/local -xzf "$go_tarball_filename"; then
    echo "❌ 解压失败，安装中止"
    return 1
  fi
  
  # 清理下载的文件并移除陷阱
  trap - EXIT
  cleanup "$go_tarball_filename"
}

# 更新 PATH（如果尚未设置）
ensure_path() {
  local profile_file
  profile_file="$(detect_profile_file)"
  
  echo "🔧 使用配置文件: $profile_file"
  
  if [ ! -f "$profile_file" ]; then
    touch "$profile_file"
    echo "🔧 创建配置文件: $profile_file"
  fi
  
  if ! grep -q "/usr/local/go/bin" "$profile_file"; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$profile_file"
    echo "🔧 已将 Go 添加到 PATH（$profile_file）"
  else
    echo "✅ PATH 已正确配置"
  fi
  
  # 确保当前会话可用
  export PATH=$PATH:/usr/local/go/bin
}

# 主流程
main() {
  # Check for sudo access upfront
  if ! check_sudo; then
    exit 1
  fi
  
  # Store command outputs in variables with proper quoting
  local current_version
  current_version="$(get_current_version)"
  local latest_version
  latest_version="$(get_latest_version)"

  echo "🔍 当前版本: $current_version"
  echo "🌐 最新版本: $latest_version"
  
  # Verify we have valid version strings
  if ! is_valid_version "$latest_version"; then
    echo "❌ 获取最新版本失败，请手动检查: https://go.dev/dl/"
    exit 1
  fi

  if [ "$current_version" == "$latest_version" ]; then
    echo "✅ 已是最新版本，无需更新。"
    exit 0
  fi

  install_go "$latest_version"
  ensure_path

  echo "✅ 安装完成，当前版本：$(go version)"
}

main
