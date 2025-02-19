#!/usr/bin/env bash
#
# 一键检测并尝试修复 WSL2 GPU 环境 - 针对 NVIDIA/CUDA 常见问题
# 使用： ./check_wsl2_gpu.sh
#

# 颜色定义
RED="\033[38;5;196m"
GREEN="\033[38;5;46m"
YELLOW="\033[38;5;226m"
BLUE="\033[38;5;33m"
CYAN="\033[38;5;51m"
RESET="\033[0m"

echo -e "${CYAN}=============================================================="
echo -e "  检测并尝试修复 WSL2 GPU 环境 (NVIDIA + CUDA)  "
echo -e "==============================================================${RESET}\n"

# ---------------------------------------------------------
# 1. 检测是否在 WSL 环境，以及是WSL1还是WSL2
# ---------------------------------------------------------
echo -e "${BLUE}[1] 检测 WSL 环境...${RESET}"

if grep -qi microsoft /proc/version; then
    echo -e "  -> 检测到系统内核包含 'Microsoft' 字样，当前处于 WSL 环境。"
    
    # 判断是否 WSL2 (内核一般含有 "microsoft-standard" 或 "WSL2" 关键字)
    KERNEL_INFO=$(uname -r)
    if [[ "$KERNEL_INFO" =~ "microsoft-standard" ]]; then
        echo -e "  -> 检测到 WSL2 内核: ${GREEN}${KERNEL_INFO}${RESET}"
    else
        echo -e "  -> ${YELLOW}你可能使用的是 WSL1 或非标准 WSL2 内核：$KERNEL_INFO${RESET}"
        echo -e "     若需 GPU 支持，请升级到 WSL2。"
        echo -e "     退出脚本。"
        exit 1
    fi
else
    echo -e "${RED}  -> 未检测到 'Microsoft' 内核信息，可能不在 WSL 环境，脚本退出。${RESET}"
    exit 1
fi

# ---------------------------------------------------------
# 2. 检测并卸载可能在WSL中错误安装的 Linux NVIDIA 驱动
# ---------------------------------------------------------
echo -e "\n${BLUE}[2] 检测是否安装了无效的 Linux NVIDIA 驱动包...${RESET}"
BAD_PACKAGES=$(dpkg -l | grep -E "nvidia-driver|nvidia-dkms|nvidia-kernel-common" | awk '{print $2}')
if [ -n "$BAD_PACKAGES" ]; then
    echo -e "${YELLOW}  -> 检测到下列无效 NVIDIA 驱动相关包:${RESET}"
    echo "$BAD_PACKAGES"
    echo -e "${YELLOW}  -> 在WSL2中安装Linux版驱动是无效的，可能会导致冲突或浪费空间。${RESET}"
    echo -ne "     是否需要自动卸载这些包？(y/n): "
    read -r remove_choice
    if [[ "$remove_choice" =~ ^[Yy]$ ]]; then
        sudo apt-get remove --purge -y $BAD_PACKAGES
        sudo apt-get autoremove -y
        echo -e "${GREEN}  -> 已卸载上述无效驱动包。${RESET}"
    else
        echo -e "  -> ${YELLOW}跳过卸载操作，可能依然会有冲突风险。${RESET}"
    fi
else
    echo -e "  -> 未发现无效的 Linux NVIDIA 驱动包。"
fi

# ---------------------------------------------------------
# 3. 检测 Windows 主机是否安装了支持 WSL2 的 NVIDIA 驱动
#    (通过 nvidia-smi 命令判断)
# ---------------------------------------------------------
echo -e "\n${BLUE}[3] 尝试在WSL内运行 nvidia-smi，检测主机驱动透传...${RESET}"
if command -v nvidia-smi &>/dev/null; then
    # 尝试执行
    NVSMI_OUTPUT=$(nvidia-smi 2>&1)
    if echo "$NVSMI_OUTPUT" | grep -q "Driver Version"; then
        echo -e "${GREEN}  -> 成功执行 nvidia-smi: "
        echo "$NVSMI_OUTPUT" | head -n 10  # 简要显示头部几行
    else
        echo -e "${RED}  -> nvidia-smi 存在，但执行报错或无法获取驱动信息！${RESET}"
        echo -e "     输出信息如下：\n$NVSMI_OUTPUT"
        echo -e "${YELLOW}  -> 请确认 Windows 主机安装了支持 WSL2 的 NVIDIA 驱动 (版本>=465)。${RESET}"
    fi
else
    echo -e "${YELLOW}  -> 未检测到 nvidia-smi 命令，说明WSL2尚未透传GPU或命令缺失。${RESET}"
    echo -e "     可能是 Windows 主机未安装新版本驱动；"
    echo -e "     或安装了但还没在WSL2更新内核/重启系统。\n"
    echo -e "     解决方案："
    echo -e "       1) 在 Windows 中安装或更新到最新版 NVIDIA 驱动（>=465）。"
    echo -e "       2) 在 PowerShell 中执行 'wsl --update' 并重启。"
    echo -e "       3) 重新进入 WSL 后再次运行本脚本。"
fi

# ---------------------------------------------------------
# 4. 检测 CUDA 工具链 (nvcc) 并尝试自动安装
# ---------------------------------------------------------
echo -e "\n${BLUE}[4] 检测 CUDA 工具链 (nvcc)${RESET}"
if command -v nvcc &>/dev/null; then
    CUDA_VER=$(nvcc --version | grep "release" | sed 's/.*release \([0-9\.]*\).*/\1/')
    echo -e "  -> 检测到 nvcc，CUDA 版本: ${GREEN}$CUDA_VER${RESET}"
else
    echo -e "${YELLOW}  -> nvcc 命令不存在，说明尚未安装 CUDA Toolkit。${RESET}"
    echo -ne "     是否需要自动安装 'cuda-toolkit-11-8' (可能需要sudo权限)? (y/n): "
    read -r install_choice
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
        # 简单示例，默认安装 cuda-toolkit-11-8。可根据系统发行版定制。
        # 如果本地没有官方源，需要先添加 NVIDIA CUDA repo。
        # 这里只做示例简单处理： 
        sudo apt-get update
        # 如果有官方 CUDA repo，也可执行: 
        #   sudo apt-get install -y cuda-toolkit-11-8 
        # 假设默认仓库能找到
        sudo apt-get install -y cuda-toolkit
        if command -v nvcc &>/dev/null; then
            echo -e "${GREEN}  -> CUDA Toolkit 安装成功。${RESET}"
        else
            echo -e "${RED}  -> 安装失败或仓库中无对应版本，请手动配置NVIDIA CUDA源。${RESET}"
        fi
    else
        echo -e "  -> ${YELLOW}跳过安装CUDA Toolkit，之后无法进行GPU编译。${RESET}"
    fi
fi

# ---------------------------------------------------------
# 5. 检测 Python 深度学习框架 (PyTorch / TensorFlow) GPU 可用性
# ---------------------------------------------------------
echo -e "\n${BLUE}[5] 检测 Python 深度学习框架的 GPU 可见性 (可选)${RESET}"

if command -v python3 &>/dev/null; then
    PYTHON_BIN="python3"
elif command -v python &>/dev/null; then
    PYTHON_BIN="python"
else
    echo -e "${YELLOW}  -> 未检测到 python3/python，跳过此项检测。${RESET}"
    PYTHON_BIN=""
fi

if [ -n "$PYTHON_BIN" ]; then
    echo -e "  -> 检测 PyTorch GPU:"
    $PYTHON_BIN -c "import torch; print('  PyTorch CUDA is_available:', torch.cuda.is_available())" 2>/dev/null || echo -e "    [提示] 未安装torch或运行出错"

    echo -e "\n  -> 检测 TensorFlow GPU:"
    $PYTHON_BIN -c "import tensorflow as tf; print('  TensorFlow GPUs:', tf.config.list_physical_devices('GPU'))" 2>/dev/null || echo -e "    [提示] 未安装tensorflow或运行出错"
fi

# ---------------------------------------------------------
# 结束总结
# ---------------------------------------------------------
echo -e "\n${CYAN}=============================================================="
echo -e "  检测/修复流程结束，请根据上方输出检查环境是否就绪。"
echo -e "  若仍无法使用GPU，务必确认："
echo -e "    1) Windows主机已安装支持WSL2的NVIDIA驱动 (>=465)。"
echo -e "    2) Windows已更新至 Win10 21H2 / Win11 或更高版本。"
echo -e "    3) WSL内核已通过 'wsl --update' 升级并重启。"
echo -e "    4) 在WSL2内部，正确安装了 CUDA 工具链 / AI 框架 (用户态库)。"
echo -e "==============================================================${RESET}\n"
