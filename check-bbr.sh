#!/bin/bash
set -euo pipefail

# ==============================================
# 脚本名称：check-bbr.sh
# 功能：检查 TCP BBR 是否完全开启
# 支持系统：所有 Linux 系统（内核 ≥ 4.9）
# 作者：你的名字（可选）
# 仓库地址：https://github.com/你的用户名/仓库名（替换成你的 GitHub 仓库）
# ==============================================

# 颜色常量
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NC="\033[0m"

# 主检查流程
main() {
    echo -e "${YELLOW}======================================${NC}"
    echo -e "${YELLOW}          🕵️  BBR 状态检查工具          ${NC}"
    echo -e "${YELLOW}======================================${NC}"

    # 检查 1：TCP 拥塞控制算法
    echo -e "\n[1] TCP 拥塞控制算法："
    local cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ "$cc" == "bbr" ]; then
        echo -e "  ${GREEN}✅ 已启用 BBR（当前值：$cc）${NC}"
    else
        echo -e "  ${RED}❌ 未启用 BBR（当前值：$cc，需为 bbr）${NC}"
        local check_fail=1
    fi

    # 检查 2：BBR 内核模块加载
    echo -e "\n[2] BBR 内核模块："
    if lsmod | grep -q "tcp_bbr"; then
        echo -e "  ${GREEN}✅ 已加载（tcp_bbr 模块存在）${NC}"
    else
        echo -e "  ${RED}❌ 未加载（内核可能不支持或配置未生效）${NC}"
        local check_fail=1
    fi

    # 检查 3：BBR 依赖的 fq 队列调度器
    echo -e "\n[3] 默认队列调度器（BBR 依赖）："
    local qd=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    if [ "$qd" == "fq" ]; then
        echo -e "  ${GREEN}✅ 已设置为 fq（正确依赖）${NC}"
    else
        echo -e "  ${RED}❌ 未设置为 fq（当前值：$qd，需为 fq）${NC}"
        local check_fail=1
    fi

    # 检查 4：内核版本兼容性
    echo -e "\n[4] 内核版本支持性："
    local kernel_version=$(uname -r | awk -F '.' '{print $1$2}')
    if [ "$kernel_version" -ge 49 ]; then
        echo -e "  ${GREEN}✅ 内核版本 $(uname -r) 支持 BBR（≥4.9）${NC}"
    else
        echo -e "  ${RED}❌ 内核版本 $(uname -r) 不支持 BBR（需≥4.9）${NC}"
        local check_fail=1
    fi

    # 最终总结
    echo -e "\n${YELLOW}======================================${NC}"
    if [ -z "${check_fail:-}" ]; then
        echo -e "  ${GREEN}🎉 恭喜！BBR 已完全开启并正常运行～${NC}"
    else
        echo -e "  ${RED}❌ 警告！BBR 未完全开启！${NC}"
        echo -e "  ${YELLOW}ℹ️  建议执行开启脚本：curl -sSL https://raw.githubusercontent.com/你的用户名/仓库名/main/enable-bbr.sh | sudo bash${NC}"
        exit 1
    fi
}

# 启动主流程
main
