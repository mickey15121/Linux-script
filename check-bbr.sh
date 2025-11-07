#!/bin/bash
set -euo pipefail

# 颜色常量（仅用于区分结果）
readonly GREEN=$'\033[32m'
readonly RED=$'\033[31m'
readonly NC=$'\033[0m'

# 核心检查（无分步输出）
main() {
    local check_fail=0
    local cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    local qd=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    local kernel_ver=$(uname -r | awk -F '[.-]' '{print $1$2}')

    # 关键条件检查
    [[ "$cc" != "bbr" ]] && check_fail=1
    [[ "$qd" != "fq" ]] && check_fail=1
    ! lsmod | grep -q "tcp_bbr" && check_fail=1
    [[ "$kernel_ver" -lt 49 ]] && check_fail=1

    # 最终极简输出
    if [[ $check_fail -eq 0 ]]; then
        echo -e "${GREEN}✅ BBR 已开启${NC}"
    else
        echo -e "${RED}❌ BBR 未开启${NC}"
        exit 1
    fi
}

main
