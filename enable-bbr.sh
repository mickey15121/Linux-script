#!/bin/bash
set -euo pipefail

# 脚本核心信息（精简展示）
readonly SCRIPT_NAME="enable-bbr.sh"
readonly REPO_URL="https://github.com/mickey15121/Linux-script"

# 颜色常量（克制使用，突出重点）
readonly RED=$'\033[31m'
readonly GREEN=$'\033[32m'
readonly YELLOW=$'\033[33m'
readonly NC=$'\033[0m'

# 核心配置（集中管理）
readonly SYSCTL_CONF="/etc/sysctl.conf"
readonly BBR_CONFIGS=(
    "net.core.default_qdisc = fq"
    "net.ipv4.tcp_congestion_control = bbr"
    "net.ipv4.tcp_mtu_probing = 1"
)
readonly BBR_COMMENT="# TCP BBR 优化配置（自动生成）"

# 检查 root 权限（简洁提示）
check_root() {
    [[ "$(id -u)" -ne 0 ]] && {
        echo -e "${RED}❌ 请使用 root 权限运行（sudo ./${SCRIPT_NAME} 或 su -）${NC}"
        exit 1
    }
}

# 检查系统兼容性（直接报错，不冗余）
check_system() {
    [[ ! -f /etc/debian_version ]] && {
        echo -e "${RED}❌ 仅支持 Debian/Ubuntu 系列系统${NC}"
        exit 1
    }
}

# 检查内核版本（简化描述）
check_kernel() {
    local kernel_ver=$(uname -r | awk -F '[.-]' '{print $1$2}')
    [[ "$kernel_ver" -lt 49 ]] && {
        echo -e "${RED}❌ 内核 $(uname -r) 不支持 BBR（需 ≥4.9）${NC}"
        echo -e "${YELLOW}ℹ️  升级命令：sudo apt update && sudo apt install -y linux-image-amd64 && reboot${NC}"
        exit 1
    }
    echo -e "${GREEN}✅ 内核 $(uname -r) 支持 BBR${NC}"
}

# 配置 BBR 参数（批量处理，不逐条输出）
configure_bbr() {
    echo -e "\n正在配置 BBR 内核参数..."
    local modified=0

    # 仅添加一次注释
    grep -qF "$BBR_COMMENT" "$SYSCTL_CONF" || {
        echo -e "\n$BBR_COMMENT" >> "$SYSCTL_CONF"
        modified=1
    }

    # 批量处理配置项
    for config in "${BBR_CONFIGS[@]}"; do
        local key=$(echo "$config" | awk '{print $1}')
        if grep -qF "^$key" "$SYSCTL_CONF"; then
            # 配置错误则更新
            grep -qF "^$config" "$SYSCTL_CONF" || {
                sed -i "s/^$key.*/$config/" "$SYSCTL_CONF"
                modified=1
            }
        else
            # 缺失则添加
            echo "$config" >> "$SYSCTL_CONF"
            modified=1
        fi
    done

    # 统一提示结果
    if [[ $modified -eq 1 ]]; then
        echo -e "${GREEN}✅ 配置已更新${NC}"
    else
        echo -e "${YELLOW}ℹ️  配置已存在且正确，无需修改${NC}"
    fi
}

# 加载配置（简洁提示）
load_config() {
    echo -e "\n正在加载配置..."
    sysctl -p >/dev/null 2>&1
    echo -e "${GREEN}✅ 配置生效成功${NC}"
}

# 验证 BBR 状态（简化输出）
verify_bbr() {
    echo -e "\n正在验证 BBR 状态..."
    local cc=$(sysctl -n net.ipv4.tcp_congestion_control)
    local qd=$(sysctl -n net.core.default_qdisc)
    local module_loaded=$(lsmod | grep -c "tcp_bbr")

    if [[ "$cc" == "bbr" && "$qd" == "fq" && "$module_loaded" -eq 1 ]]; then
        echo -e "\n${GREEN}======================================${NC}"
        echo -e "${GREEN}🎉 BBR 已成功开启并运行！${NC}"
        echo -e "${YELLOW}ℹ️  详细检查：curl -sSL ${REPO_URL}/main/check-bbr.sh | bash${NC}"
        echo -e "${GREEN}======================================${NC}\n"
    else
        echo -e "\n${RED}❌ BBR 开启失败！请检查 /var/log/syslog 或重新运行脚本${NC}\n"
        exit 1
    fi
}

# 主流程（简洁排版）
main() {
    # 简化标题栏
    echo -e "${YELLOW}======================================${NC}"
    echo -e "${YELLOW}🚀 BBR 一键开启工具（Debian/Ubuntu 专用）${NC}"
    echo -e "${YELLOW}======================================${NC}\n"

    check_root
    check_system
    check_kernel
    configure_bbr
    load_config
    verify_bbr
}

main
