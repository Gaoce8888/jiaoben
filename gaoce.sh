#!/bin/bash

# ==============================================
#                 Gaoce AI 系统
# ==============================================
# 版本: 2.0
# 作者: Gaoce
# 支持: QQ 260060440 | 官网: gaoce.ai
# ==============================================

# 颜色定义
RED="\033[38;5;196m"
GREEN="\033[38;5;46m"
YELLOW="\033[38;5;226m"
BLUE="\033[38;5;33m"
PURPLE="\033[38;5;129m"
CYAN="\033[38;5;51m"
RESET="\033[0m"

# ==============================================
#                 依赖检查
# ==============================================
check_dependencies() {
    echo -e "${CYAN}>>> 正在检查必备工具...${RESET}"
    local dependencies=("bash" "awk" "grep" "ping")

    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}✗ 缺少依赖: $cmd，请安装后重试${RESET}"
            exit 1
        fi
    done

    echo -e "${GREEN}✔ 依赖检查通过${RESET}"
}

# ==============================================
#                 动态进度条
# ==============================================
show_progress() {
    echo -ne "${CYAN}>>> 执行中 "
    spin=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    while true; do
        for i in "${spin[@]}"; do
            printf "\r%s %s" "${CYAN}>>> 执行中" "$i"
            sleep 0.1
        done
    done
}

# ==============================================
#                 Gaoce AI Logo
# ==============================================
show_logo() {
    clear
    echo -e "${PURPLE}
    ╔═╗┌─┐┌─┐┬ ┬  ╔═╗┬  
    ║  ├─┤├─┘├─┤  ╠═╝│  
    ╚═╝┴ ┴┴  ┴ ┴  ╩  ┴─┘
    ${CYAN}
    █████╗ ██╗     Ver 2.0
    ██╔══██╗██║     QQ: 260060440
    ███████║██║     Site: gaoce.ai
    ██╔══██║██║     Powered by NextAI
    ██║  ██║███████╗
    ╚═╝  ╚═╝╚══════╝
    ${RESET}"
    sleep 1
}

# ==============================================
#                 设备状态
# ==============================================
show_status() {
    echo -e "\n${BLUE}╔══════════════ 实时系统状态 ══════════════╗"
    echo -e "  CPU负载: $(uptime | awk -F'load average: ' '{print $2}')"
    echo -e "  内存使用: $(free -m | awk '/Mem/ {print $3"/"$2 "MB"}')"
    echo -e "  存储空间: $(df -h / | awk 'NR==2 {print $4 " Free"}')"
    echo -e "  网络状态: $(ping -c1 baidu.com &>/dev/null && echo "✓" || echo "✗")"
    echo -e "╚══════════════════════════════════════════╝${RESET}"
}

# ==============================================
#                 主菜单系统
# ==============================================
main_menu() {
    while true; do
        show_logo
        show_status

        echo -e "${PURPLE}╔═══════════ Gaoce AI 控制中心 ═══════════╗"
        echo -e "${CYAN} 1. 安装基础环境"
        echo -e " 2. 设备检测"
        echo -e " 3. 安装平台依赖"
        echo -e " 4. 数据与资料管理"
        echo -e " 5. 集成多模型"
        echo -e " 6. 模型平台安装"
        echo -e " 7. 训练模型平台"
        echo -e " 8. 系统优化"
        echo -e " 9. 推荐下载模型"
        echo -e "10. 退出系统"
        echo -e "╚════════════════════════════════════════╝"
        echo -e "${YELLOW}提示: 输入数字选择操作，输入q可随时退出${RESET}"
        
        echo -ne "\n${GREEN}请输入操作指令 (1-10): ${RESET}"
        read -r main_choice

        case $main_choice in
            1) run_script "安装基础环境" ./安装基础.sh ;;
            2) run_script "设备检测" ./检测系统.sh ;;
            3) run_script "安装平台依赖" ./安装平台.sh ;;
            4) run_script "创建虚拟环境" ./虚拟环境.sh ;;
            5) run_script "集成多模型" ./多模型.sh ;;
            6) run_script "模型平台安装" ./install_model_platform.sh ;;
            7) run_script "训练模型平台" ./训练模型.sh ;;
            8) run_script "系统优化" ./系统优化.sh ;;
            9) run_script "推荐下载模型" ./webUl.sh ;;
            10) safe_exit ;;
            q|Q) safe_exit ;;
            *) show_error "无效输入！请输入1-10之间的数字" ;;
        esac
    done
}

# ==============================================
#                 安全执行函数
# ==============================================
run_script() {
    show_progress &
    pid=$!
    trap "kill $pid 2>/dev/null" EXIT
    
    if [ -f "$2" ]; then
        if bash "$2"; then
            kill $pid
            echo -e "\n${GREEN}✔ $1 完成${RESET}"
        else
            kill $pid
            echo -e "\n${RED}✗ $1 失败！错误码: $?${RESET}"
        fi
    else
        kill $pid
        show_error "脚本不存在: $2"
    fi
    sleep 1
}

# ==============================================
#                 安全退出
# ==============================================
safe_exit() {
    echo -e "\n${CYAN}>>> 正在安全退出..."
    echo -e "感谢使用 Gaoce AI 系统！"
    echo -e "技术支持 QQ: ${YELLOW}260060440${RESET}\n"
    exit 0
}

# ==============================================
#                 启动菜单
# ==============================================
check_dependencies
main_menu
