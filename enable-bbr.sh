#!/bin/bash
set -euo pipefail

# 脚本信息
readonly SCRIPT_NAME="enable-bbr.sh"
readonly DESCRIPTION="TCP BBR 一键开启工具（Debian/Ubuntu 专用）"
readonly SUPPORTED_OS="Debian 9+/Ubuntu 16.04+（内核 ≥4.9）"
readonly REPO_URL="https://github.com/你的用户名/仓库名"

# 颜色常量
readonly RED=$'\033[31m'
readonly GREEN=$'\033[32m'
readonly YELLOW=$'\033[33m'
readonly NC=$'\033[0m'

# 核心配置（集中管理，便于维护）
readonly SYSCTL_CONF="/etc/sysctl.conf"
readonly BBR_CONFIGS=(
    "net.core.default_qdisc = fq"
    "net.ipv4.tcp_congestion_control = bbr"
    "net.ipv4.tcp_mtu_probing = 1"
)
readonly BBR_COMMENT="# TCP BBR 优化配置（自动生成）"

# 检查 root 权限
check_root() {
    [[ "$(id -u)" -ne 0 ]] && {
        echo -e "${RED}❌ 错误：请用 root 权限运行（sudo ./${SCRIPT_NAME} 或 su -）${NC}"
        exit 1
    }
}

# 检查系统兼容性
check_system() {
    [[ ! -f /etc/debian_version ]] && {
        echo -e "${RED}❌ 错误：仅支持 Debian/Ubuntu 系列系统${NC}"
        exit 1
    }
}

# 检查内核版本
check_kernel() {
    local kernel_ver=$(uname -r | awk -F '[.-]' '{print $1$2}')
    [[ "$kernel_ver" -lt 49 ]] && {
        echo -e "${RED}❌ 错误：内核 $(uname -r) 不支持 BBR（需≥4.9）${NC}"
        echo -e "${YELLOW}ℹ️  升级内核：sudo apt update && sudo apt install -y linux-image-amd64 && reboot${NC}"
        exit 1
    }
    echo -e "${GREEN}✅ 内核 $(uname -r) 支持 BBR${NC}"
}

# 配置 BBR 参数（避免重复添加/冗余）
configure_bbr() {
    echo -e "\n📌 配置 BBR 内核参数..."
    # 仅添加一次注释（避免重复）
    grep -qF "$BBR_COMMENT" "$SYSCTL_CONF" || echo -e "\n$BBR_COMMENT" >> "$SYSCTL_CONF"

    # 批量处理配置（存在则更新，不存在则添加）
    for config in "${BBR_CONFIGS[@]}"; do
        local key=$(echo "$config" | awk '{print $1}')
        if grep -qF "^$key" "$SYSCTL_CONF"; then
            # 配置存在但值错误 → 更新
            grep -qF "^$config" "$SYSCTL_CONF" && echo -e "ℹ️  配置已正确：$config" || {
                sed -i "s/^$key.*/$config/" "$SYSCTL_CONF"
                echo -e "🔄 更新配置：$config"
            }
        else
            # 配置不存在 → 添加
            echo "$config" >> "$SYSCTL_CONF"
            echo -e "✅ 添加配置：$config"
        fi
    done
}

# 加载配置并生效
load_config() {
    echo -e "\n📌 加载配置并生效..."
    sysctl -p >/dev/null 2>&1  # 静默执行，仅输出结果
    echo -e "${GREEN}✅ 配置加载成功！${NC}"
}

# 验证 BBR 状态
verify_bbr() {
    echo -e "\n📌 验证 BBR 开启状态..."
    local cc=$(sysctl -n net.ipv4.tcp_congestion_control)
    local qd=$(sysctl -n net.core.default_qdisc)
    local module_loaded=$(lsmod | grep -c "tcp_bbr")

    if [[ "$cc" == "bbr" && "$qd" == "fq" && "$module_loaded" -eq 1 ]]; then
        echo -e "${GREEN}🎉 BBR 已成功开启并运行！${NC}"
        echo -e "${YELLOW}ℹ️  详细检查：curl -sSL ${REPO_URL}/main/check-bbr.sh | bash${NC}\n"
    else
        echo -e "${RED}❌ BBR 开启失败！请检查 /var/log/syslog 或重新运行脚本${NC}"
        exit 1
    fi
}

# 主流程（线性执行，逻辑清晰）
main() {
    echo -e "${YELLOW}======================================${NC}"
    echo -e "${YELLOW}  🚀 ${SCRIPT_NAME} - ${DESCRIPTION}  ${NC}"
    echo -e "${YELLOW}  支持系统：${SUPPORTED_OS}  ${NC}"
    echo -e "${YELLOW}======================================${NC}\n"

    check_root
    check_system
    check_kernel
    configure_bbr
    load_config
    verify_bbr
}

# 启动执行
main
