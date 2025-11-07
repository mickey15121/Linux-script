#!/bin/bash
set -euo pipefail

# 颜色常量（确保输出可见）
GREEN=$'\033[32m'
RED=$'\033[31m'
NC=$'\033[0m'

# 权限检查（强制输出错误，避免静默）
if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${RED}❌ 错误：请用 root 权限运行（添加 sudo）${NC}" >&2
    exit 1
fi

# 系统检查
if [[ ! -f /etc/debian_version ]]; then
    echo -e "${RED}❌ 错误：仅支持 Debian/Ubuntu 系统${NC}" >&2
    exit 1
fi

# 内核检查
kernel_ver=$(uname -r | awk -F '[.-]' '{print $1$2}')
if [[ "$kernel_ver" -lt 49 ]]; then
    echo -e "${RED}❌ 错误：内核需 ≥4.9（当前：$(uname -r)）${NC}" >&2
    exit 1
fi

# 配置 BBR（静默执行，仅保留核心逻辑）
conf="/etc/sysctl.conf"
configs=(
    "net.core.default_qdisc = fq"
    "net.ipv4.tcp_congestion_control = bbr"
)
for cfg in "${configs[@]}"; do
    key=$(echo "$cfg" | awk '{print $1}')
    grep -qF "^$key" "$conf" && sed -i "s/^$key.*/$cfg/" "$conf" || echo "$cfg" >> "$conf"
done
sysctl -p >/dev/null 2>&1

# 验证并输出结果（仅一句话）
cc=$(sysctl -n net.ipv4.tcp_congestion_control)
qd=$(sysctl -n net.core.default_qdisc)
if [[ "$cc" == "bbr" && "$qd" == "fq" ]]; then
    echo -e "${GREEN}✅ BBR 开启成功${NC}"
else
    echo -e "${RED}❌ BBR 开启失败${NC}" >&2
    exit 1
fi
