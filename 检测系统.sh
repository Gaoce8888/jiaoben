#!/bin/bash
# File: gaoce_hardware_detect.sh
# 版本: 3.0
# 技术支持: QQ 260060440 | 官网: gaoce.ai

# ==============================================
#                 全局配置
# ==============================================
RED="\033[38;5;196m"    # 错误/重要
GREEN="\033[38;5;46m"   # 成功
YELLOW="\033[38;5;226m" # 警告
BLUE="\033[38;5;33m"    # 信息
CYAN="\033[38;5;51m"    # 高亮
PURPLE="\033[38;5;129m" # 菜单
RESET="\033[0m"

REPORT_FILE="/tmp/gaoce_hardware_report_$(date +%Y%m%d%H%M%S).log"

# ==============================================
#                 初始化函数
# ==============================================
init_system() {
    clear
    echo -e "${PURPLE}
    ╔═╗┌─┐┌─┐┬ ┬  ╔═╗┬  ╔═╗╔═╗╦ ╦
    ║  ├─┤├─┘├─┤  ╠═╝│  ╠═╝║  ╠═╣
    ╚═╝┴ ┴┴  ┴ ┴  ╩  ┴─┘╩  ╚═╝╩ ╩
    ${CYAN}      硬件检测系统 v3.0
    ${GREEN}------------------------------
    ${YELLOW}技术支持 QQ: 260060440
    ${YELLOW}官方网站: gaoce.ai
    ${RESET}"

    # 包管理器检测
    if command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
    else
        echo -e "${RED}不支持的Linux发行版！${RESET}"
        exit 1
    fi

    # 自动提权验证
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}提示: 部分功能需要sudo权限${RESET}"
    fi
}

# ==============================================
#                 依赖管理
# ==============================================
install_dependencies() {
    local deps=("$@")
    for pkg in "${deps[@]}"; do
        if ! command -v $pkg &>/dev/null; then
            echo -e "${YELLOW}正在安装 $pkg ...${RESET}"
            case $PKG_MANAGER in
                apt) sudo apt-get install -y $pkg >/dev/null ;;
                dnf) sudo dnf install -y $pkg >/dev/null ;;
                yum) sudo yum install -y $pkg >/dev/null ;;
            esac
        fi
    done
}

# ==============================================
#                 CPU检测模块
# ==============================================
detect_cpu() {
    echo -e "\n${BLUE}╔══════════════ CPU 详细信息 ═════════════╗"
    
    # 传感器自动配置
    if ! sensors &>/dev/null; then
        install_dependencies lm-sensors hddtemp
        sudo sensors-detect --auto >/dev/null
        sudo modprobe coretemp 2>/dev/null
    fi

    # 温度检测逻辑
    local temp_source=(
        "Package id" 
        "Core 0" 
        "Tdie" 
        "Physical id 0"
    )
    for source in "${temp_source[@]}"; do
        local cpu_temp=$(sensors | grep "$source" | awk '{print $4}' | head -1)
        [ -n "$cpu_temp" ] && break
    done

    # 信息输出
    echo -e "  ${CYAN}型号\t: $(lscpu | grep 'Model name' | cut -d: -f2 | sed 's/^ *//')" | tee -a $REPORT_FILE
    echo -e "  架构\t: $(lscpu | grep Architecture | awk '{print $2}')" | tee -a $REPORT_FILE
    echo -e "  温度\t: ${cpu_temp:-${YELLOW}未获取到数据}${RESET}" | tee -a $REPORT_FILE
    echo -e "${BLUE}╚══════════════════════════════════════════╝${RESET}"
}

# ==============================================
#                GPU检测模块
# ==============================================
detect_gpu() {
    echo -e "\n${BLUE}╔══════════════ GPU 详细信息 ═════════════╗"
    local gpu_info=$(lspci -nn | grep -E 'VGA|3D')
    
    # NVIDIA检测
    if [[ $gpu_info == *"NVIDIA"* ]]; then
        install_dependencies nvidia-smi
        echo -e "  ${CYAN}品牌\t: NVIDIA" | tee -a $REPORT_FILE
        echo -e "  型号\t: $(nvidia-smi --query-gpu=gpu_name --format=csv,noheader | uniq)" | tee -a $REPORT_FILE
        echo -e "  显存\t: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader | uniq)" | tee -a $REPORT_FILE
    
    # AMD检测
    elif [[ $gpu_info == *"AMD"* ]]; then
        echo -e "  ${CYAN}品牌\t: AMD" | tee -a $REPORT_FILE
        echo -e "  型号\t: $(glxinfo | grep "OpenGL renderer" | cut -d: -f2)" | tee -a $REPORT_FILE
    
    # Intel检测
    elif [[ $gpu_info == *"Intel"* ]]; then
        echo -e "  ${CYAN}品牌\t: Intel" | tee -a $REPORT_FILE
        echo -e "  型号\t: $(lspci -nn | grep VGA | cut -d ':' -f3-)" | tee -a $REPORT_FILE
    
    else
        echo -e "  ${RED}未检测到显卡设备!${RESET}" | tee -a $REPORT_FILE
    fi
    echo -e "${BLUE}╚══════════════════════════════════════════╝${RESET}"
}

# ==============================================
#               存储检测模块
# ==============================================
detect_storage() {
    echo -e "\n${BLUE}╔════════════ 存储设备健康报告 ════════════╗"
    lsblk -d -o NAME,ROTA,TYPE | grep -v NAME | while read -r line; do
        local disk=$(echo $line | awk '{print $1}')
        local type=$(echo $line | awk '{print $3}')
        
        echo -e "  ${CYAN}设备\t: /dev/$disk" | tee -a $REPORT_FILE
        
        # NVMe检测
        if [[ $disk == nvme* ]]; then
            local smart_data=$(sudo nvme smart-log /dev/$disk 2>/dev/null)
            [ $? -eq 0 ] && {
                echo -e "  温度\t: $(echo "$smart_data" | grep temperature | awk '{print $3}')°C" | tee -a $REPORT_FILE
                echo -e "  寿命\t: $(echo "$smart_data" | grep percentage_used | awk '{print $3}')%" | tee -a $REPORT_FILE
            }
        
        # 机械硬盘检测
        elif [ $(echo $line | awk '{print $2}') -eq 1 ]; then
            local smart_data=$(sudo smartctl -a /dev/$disk 2>/dev/null)
            [ $? -eq 0 ] && {
                echo -e "  健康\t: $(echo "$smart_data" | grep -i 'SMART overall-health' | awk -F': ' '{print $2}')" | tee -a $REPORT_FILE
                echo -e "  寿命\t: $(echo "$smart_data" | grep -i 'Power_On_Hours' | awk '{print $10 " 小时"}')" | tee -a $REPORT_FILE
            }
        fi
        echo -e "  ${PURPLE}―――――――――――――――――――――――――――――――――――${RESET}" | tee -a $REPORT_FILE
    done
    echo -e "${BLUE}╚══════════════════════════════════════════╝${RESET}"
}

# ==============================================
#               网络检测模块
# ==============================================
detect_network() {
    echo -e "\n${BLUE}╔══════════════ 网络拓扑分析 ═════════════╗"
    echo -e "  ${CYAN}主机名\t: $(hostname)" | tee -a $REPORT_FILE
    echo -e "  IP地址\t: $(hostname -I | awk '{print $1}')" | tee -a $REPORT_FILE
    echo -e "  网关\t: $(ip route | grep default | awk '{print $3}')" | tee -a $REPORT_FILE
    echo -e "  DNS\t: $(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')" | tee -a $REPORT_FILE
    
    # 接口详情
    echo -e "\n  ${CYAN}=== 网络接口详情 ===" | tee -a $REPORT_FILE
    for iface in $(ls /sys/class/net | grep -v lo); do
        echo -e "  ${PURPLE}接口名: $iface" | tee -a $REPORT_FILE
        echo -e "  MAC\t: $(cat /sys/class/net/$iface/address)" | tee -a $REPORT_FILE
        echo -e "  状态\t: $(cat /sys/class/net/$iface/operstate)" | tee -a $REPORT_FILE
        echo -e "  ${PURPLE}―――――――――――――――――${RESET}" | tee -a $REPORT_FILE
    done
    echo -e "${BLUE}╚══════════════════════════════════════════╝${RESET}"
}

# ==============================================
#                 报告生成模块
# ==============================================
generate_report() {
    echo -e "\n${CYAN}════════════ 检测报告已生成 ════════════"
    echo -e "  完整报告路径: ${YELLOW}$REPORT_FILE"
    echo -e "  ${CYAN}技术支持: QQ 260060440"
    echo -e "  官方网站: gaoce.ai${RESET}"
}

# ==============================================
#                 主执行流程
# ==============================================
main() {
    init_system
    detect_cpu
    detect_gpu
    detect_storage
    detect_network
    generate_report
}

# ==============================================
#                 脚本入口
# ==============================================
trap "echo -e '\n${RED}操作已中止！${RESET}'; exit 1" SIGINT
main