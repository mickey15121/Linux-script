#!/bin/bash
set -euo pipefail

# 颜色常量（仅用于区分结果）
readonly GREEN=$'\033[32m'
readonly RED=$'\033[31m'
readonly NC=$'\033[0m'

# 必要检查（仅保留错误提示）
check_root() {
    [[ "$(id -u)" -ne 0 ]] && { echo -e "${RED}❌ 请用 root 权限运行${NC}"; exit 1; }
}

check_system() {
    [[ ! -f /etc/debian_version ]] && { echo -e "${RED}❌ 仅支持 Debian/Ubuntu${NC}"; exit 1; }
}

check_kernel() {
    local kernel_ver=$(uname -r | awk -F '[.-]' '{print $1$2}')
    [[ "$kernel_ver" -lt 49 ]] && { echo -e "${RED}❌ 内核需 ≥4.9${NC}"; exit 1; }
}

# 核心配置（无中间输出）
configure_bbr() {
    local conf="/etc/sysctl.conf"
    local configs=(
        "net.core.default_qdisc = fq"
        "net.ipv4.tcp_congestion_control = bbr"
        "net.ipv4.tcp_mtu_probing = 1"
    )

    # 批量配置
    for cfg in "${configs[@]}"; do
        local key=$(echo "$cfg" | awk '{print $1}')
        grep -qF "^$key" "$conf" && sed -i "s/^$key.*/$cfg/" "$conf" || echo "$cfg" >> "$conf"
    done
    sysctl -p >/dev/null 2>&1
}

# 最终验证（极简输出）
verify_bbr() {
    local cc=$(sysctl -n net.ipv4.tcp_congestion_control)
    local qd=$(sysctl -n net.core.default_qdisc)
    local mod=$(lsmod | grep -c "tcp_bbr")

    if [[ "$cc" == "bbr" && "$qd" == "fq" && "$mod" -eq 1 ]]; then
        echo -e "${GREEN}✅ BBR 开启成功${NC}"
    else
        echo -e "${RED}❌ BBR 开启失败${NC}"
        exit 1
    fi
}

# 主流程（无多余排版）
main() {
    check_root
    check_system
    check_kernel
    configure_bbr
    verify_bbr
}

main
