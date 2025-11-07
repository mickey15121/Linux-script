#!/bin/bash
# 终极极简版：无任何多余逻辑，仅保留“配置+验证+强制输出”
GREEN=$'\033[32m'
RED=$'\033[31m'
NC=$'\033[0m'

# 强制输出执行状态（让你看到脚本走到哪一步）
echo -n "正在配置 BBR..."

# 1. 直接写入配置（不用 sed 删除旧配置，避免 sed 兼容问题）
# 先判断配置是否已存在，不存在则添加（最简单的写法）
grep -q "net.core.default_qdisc = fq" /etc/sysctl.conf || echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
grep -q "net.ipv4.tcp_congestion_control = bbr" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf

# 2. 加载配置（忽略错误，继续执行）
sysctl -p >/dev/null

echo "完成"
echo "正在验证状态..."

# 3. 验证（直接获取值，不做复杂判断）
cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>&1)
qd=$(sysctl -n net.core.default_qdisc 2>&1)

# 4. 强制输出结果（无论前面是否有小错误）
if [ "$cc" = "bbr" ] && [ "$qd" = "fq" ]; then
    echo -e "\n${GREEN}✅ BBR 开启成功${NC}"
else
    echo -e "\n${RED}❌ BBR 开启失败${NC}"
    echo -e "${RED}  详情：tcp_congestion_control=$cc, default_qdisc=$qd${NC}"
    exit 1
fi
