#!/bin/bash
set -euo pipefail  # 严格模式，减少错误

# ==============================================
# 脚本名称：enable-bbr.sh
# 功能：一键开启 TCP BBR 拥塞控制（Debian/Ubuntu 专用）
# 支持系统：Debian 9+/Ubuntu 16.04+（内核 ≥ 4.9）
# 作者：你的名字（可选）
# 仓库地址：https://github.com/你的用户名/仓库名（替换成你的 GitHub 仓库）
# ==============================================

# 颜色常量（终端输出更友好）
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NC="\033[0m"  # 重置颜色

# 检查是否为 root 权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}❌ 错误：请用 root 权限运行（sudo ./enable-bbr.sh 或 su - 切换 root）${NC}"
        exit 1
    fi
}

# 检查系统兼容性（仅支持 Debian/Ubuntu）
check_system() {
    if [ ! -f /etc/debian_version ]; then
        echo -e "${RED}❌ 错误：仅支持 Debian/Ubuntu 系列系统，其他系统暂不兼容${NC}"
        exit 1
    fi
}

# 检查内核版本（BBR 要求内核 ≥ 4.9）
check_kernel() {
    local kernel_version=$(uname -r | awk -F '.' '{print $1$2}')  # 提取内核主版本（如 5.10 → 510）
    if [ "$kernel_version" -lt 49 ]; then
        echo -e "${RED}❌ 错误：当前内核版本 $(uname -r) 不支持 BBR（需内核 ≥ 4.9）${NC}"
        echo -e "${YELLOW}ℹ️  建议升级内核：sudo apt update && sudo apt install -y linux-image-amd64 && reboot${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ 内核版本 $(uname -r) 支持 BBR${NC}"
}

# 配置 BBR 内核参数（避免重复添加）
configure_bbr() {
    local sysctl_conf="/etc/sysctl.conf"
    local bbr_configs=(
        "net.core.default_qdisc = fq"
        "net.ipv4.tcp_congestion_control = bbr"
        "net.ipv4.tcp_mtu_probing = 1"
    )

    echo -e "\n📌 开始配置 BBR 内核参数..."
    # 循环添加/更新配置（已存在则覆盖错误值，不存在则添加）
    for config in "${bbr_configs[@]}"; do
        local key=$(echo "$config" | awk '{print $1}')
        # 检查配置是否存在，不存在则添加
        if ! grep -q "^$key" "$sysctl_conf" 2>/dev/null; then
            echo -e "\n# TCP BBR 配置（自动添加）" >> "$sysctl_conf"
            echo "$config" >> "$sysctl_conf"
            echo -e "✅ 添加配置：$config"
        else
            # 配置存在但值错误，自动更新
            if ! grep -q "^$config" "$sysctl_conf" 2>/dev/null; then
                sed -i "s/^$key.*/$config/" "$sysctl_conf"
                echo -e "🔄 更新配置：$config"
            else
                echo -e "ℹ️  配置已存在（正确）：$config"
            fi
        fi
    done
}

# 加载配置并生效
load_config() {
    echo -e "\n📌 加载配置，使 BBR 立即生效..."
    sysctl -p >/dev/null 2>&1  # 静默执行，避免冗余输出
    echo -e "${GREEN}✅ 配置加载成功！${NC}"
}

# 验证配置结果（快速检查）
verify_bbr() {
    echo -e "\n📌 快速验证 BBR 状态..."
    local cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    local qd=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    
    if [ "$cc" == "bbr" ] && [ "$qd" == "fq" ]; then
        echo -e "${GREEN}🎉 BBR 已成功开启并运行！${NC}"
        echo -e "${YELLOW}ℹ️  如需详细检查，可执行：curl -sSL https://raw.githubusercontent.com/你的用户名/仓库名/main/check-bbr.sh | bash${NC}"
    else
        echo -e "${RED}❌ BBR 开启失败！请检查系统日志或重新运行脚本${NC}"
        exit 1
    fi
}

# 主流程
main() {
    echo -e "${YELLOW}======================================${NC}"
    echo -e "${YELLOW}          🚀 BBR 一键开启工具          ${NC}"
    echo -e "${YELLOW}======================================${NC}"
    check_root
    check_system
    check_kernel
    configure_bbr
    load_config
    verify_bbr
}

# 启动主流程
main
