#!/bin/bash
set -euo pipefail

# 脚本信息
readonly SCRIPT_NAME="check-bbr.sh"
readonly DESCRIPTION="TCP BBR 状态完整性检查工具"
readonly SUPPORTED_OS="Linux (内核 ≥ 4.9)"
readonly REPO_URL="https://github.com/你的用户名/仓库名"

# 颜色常量（只读，避免意外修改）
readonly RED=$'\033[31m'
readonly GREEN=$'\033[32m'
readonly YELLOW=$'\033[33m'
readonly NC=$'\033[0m'

# 主检查逻辑
main() {
    # 标题输出（简洁排版）
    echo -e "\n${YELLOW}======================================${NC}"
    echo -e "${YELLOW}  🕵️  ${SCRIPT_NAME} - ${DESCRIPTION}  ${NC}"
    echo -e "${YELLOW}  支持系统：${SUPPORTED_OS}  ${NC}"
    echo -e "${YELLOW}======================================${NC}\n"

    local check_fail=0  # 失败标记（0=成功，1=失败）

    # 检查1：TCP拥塞控制算法
    echo -e "[1] TCP 拥塞控制算法："
    local cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    [[ "$cc" == "bbr" ]] && echo -e "  ${GREEN}✅ 已启用 BBR（当前：$cc）${NC}" || {
        echo -e "  ${RED}❌ 未启用 BBR（当前：$cc，需为 bbr）${NC}"
        check_fail=1
    }

    # 检查2：BBR内核模块加载
    echo -e "\n[2] BBR 内核模块："
    lsmod | grep -q "tcp_bbr" && echo -e "  ${GREEN}✅ 已加载（tcp_bbr 存在）${NC}" || {
        echo -e "  ${RED}❌ 未加载（内核不支持或配置未生效）${NC}"
        check_fail=1
    }

    # 检查3：依赖的FQ队列调度器
    echo -e "\n[3] 默认队列调度器（BBR依赖）："
    local qd=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    [[ "$qd" == "fq" ]] && echo -e "  ${GREEN}✅ 已设置为 fq（正确依赖）${NC}" || {
        echo -e "  ${RED}❌ 未设置为 fq（当前：$qd，需为 fq）${NC}"
        check_fail=1
    }

    # 检查4：内核版本兼容性（简化版本提取逻辑）
    echo -e "\n[4] 内核版本支持性："
    local kernel_ver=$(uname -r | awk -F '[.-]' '{print $1$2}')  # 处理 5.10.0-xx → 510
    [[ "$kernel_ver" -ge 49 ]] && echo -e "  ${GREEN}✅ 内核 $(uname -r) 支持 BBR（≥4.9）${NC}" || {
        echo -e "  ${RED}❌ 内核 $(uname -r) 不支持 BBR（需≥4.9）${NC}"
        check_fail=1
    }

    # 结果总结
    echo -e "\n${YELLOW}======================================${NC}"
    if [[ $check_fail -eq 0 ]]; then
        echo -e "  ${GREEN}🎉 BBR 已完全开启并正常运行！${NC}"
    else
        echo -e "  ${RED}❌ BBR 未完全开启！${NC}"
        echo -e "  ${YELLOW}ℹ️  快速修复：curl -sSL ${REPO_URL}/main/enable-bbr.sh | sudo bash${NC}"
        exit 1
    fi
    echo -e "${YELLOW}======================================${NC}\n"
}

# 启动执行
main
