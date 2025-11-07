#!/bin/bash
# 完全去掉 set -euo pipefail，避免静默退出
# 极简语法，只保留核心逻辑

GREEN=$'\033[32m'
RED=$'\033[31m'
NC=$'\033[0m'

# 1. 权限检查（必显提示）
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ 错误：请用 root 权限运行（已加 sudo 请忽略）${NC}"
    exit 1
fi

# 2. 系统检查（必显提示）
if [ ! -f /etc/debian_version ]; then
    echo -e "${RED}❌ 错误：仅支持 Debian/Ubuntu 系统${NC}"
    exit 1
fi

# 3. 内核检查（简化解析，避免空值）
kernel_ver=$(uname -r | cut -d '.' -f 1-2)  # 直接取 x.y 格式（如 5.10）
# 转换为数字比较（如 4.9 → 49，5.10 →510）
kernel_num=$(echo "$kernel_ver" | tr -d '.')
if [ -z "$kernel_num" ] || [ "$kernel_num" -lt 49 ]; then
    echo -e "${RED}❌ 错误：内核需 ≥4.9（当前：$(uname -r)）${NC}"
    exit 1
fi

# 4. 配置 BBR（最基础的写法，避免 sed/grep 异常）
conf="/etc/sysctl.conf"
# 先删除旧配置（避免重复）
sed -i '/net.core.default_qdisc/d' "$conf" 2>/dev/null
sed -i '/net.ipv4.tcp_congestion_control/d' "$conf" 2>/dev/null
# 添加新配置
echo "net.core.default_qdisc = fq" >> "$conf"
echo "net.ipv4.tcp_congestion_control = bbr" >> "$conf"
# 加载配置（忽略错误，继续执行）
sysctl -p 2>/dev/null

# 5. 验证并强制输出结果（无论如何都有反馈）
cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
qd=$(sysctl -n net.core.default_qdisc 2>/dev/null)

if [ "$cc" = "bbr" ] && [ "$qd" = "fq" ]; then
    echo -e "${GREEN}✅ BBR 开启成功${NC}"
else
    echo -e "${RED}❌ BBR 开启失败（当前：cc=$cc, qd=$qd）${NC}"
    exit 1
fi
