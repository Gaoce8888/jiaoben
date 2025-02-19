#!/bin/bash

# ==============================================
# 显示虚拟环境的作用（新手友好提示）
# ==============================================
explain_venv() {
    echo -e "\033[1;34m🤔 为什么要使用虚拟环境？\033[0m"
    echo -e "\033[36m虚拟环境是一个独立的 Python 运行环境，它可以帮助你：\033[0m"
    echo -e "1. \033[32m避免版本冲突\033[0m：不同项目可能需要不同版本的库，虚拟环境可以隔离它们。"
    echo -e "2. \033[32m保持全局环境干净\033[0m：不会污染系统的 Python 环境。"
    echo -e "3. \033[32m方便分享和协作\033[0m：可以通过一个文件记录所有依赖，其他人一键安装。"
    echo -e "\033[36m简单来说，虚拟环境就像是一个‘独立的小房间’，让你更轻松地管理项目！\033[0m"
    echo -e "\033[1;34m==============================================\033[0m"
}

# ==============================================
# 创建和激活虚拟环境
# ==============================================
create_venv() {
    echo -e "\033[36m正在创建 Python 虚拟环境...\033[0m"
    read -p "请输入虚拟环境名称（默认：vllm_env）：" venv_name
    venv_name=${venv_name:-vllm_env}
    python3 -m venv "$venv_name"
    source "$venv_name/bin/activate"
    echo -e "\033[32m虚拟环境 $venv_name 创建并激活成功 ✔\033[0m"
}

# ==============================================
# 安装 Python 模块
# ==============================================
install_modules() {
    echo -e "\033[36m是否安装常用 Python 模块？(y/n)\033[0m"
    read -r install_choice
    if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
        echo -e "\033[36m请选择要安装的模块：\033[0m"
        echo "1. PyTorch (CUDA 11.8)"
        echo "2. vLLM"
        echo "3. 全部安装"
        echo "4. 自定义模块"
        read -p "请输入选项（1/2/3/4）：" module_choice

        case $module_choice in
            1)
                echo -e "\033[36m正在安装 PyTorch (CUDA 11.8)...\033[0m"
                pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
                ;;
            2)
                echo -e "\033[36m正在安装 vLLM...\033[0m"
                pip install vllm
                ;;
            3)
                echo -e "\033[36m正在安装 PyTorch 和 vLLM...\033[0m"
                pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
                pip install vllm
                ;;
            4)
                read -p "请输入要安装的模块名称（用空格分隔）：" custom_modules
                echo -e "\033[36m正在安装自定义模块：$custom_modules...\033[0m"
                pip install $custom_modules
                ;;
            *)
                echo -e "\033[33m未选择安装模块，跳过。\033[0m"
                ;;
        esac

        echo -e "\033[32m模块安装完成 ✔\033[0m"
    else
        echo -e "\033[33m跳过模块安装。\033[0m"
    fi
}

# ==============================================
# 脚本入口
# ==============================================
echo -e "\033[1;34m========== 虚拟环境与模块安装脚本 ==========\033[0m"
explain_venv
create_venv
install_modules
echo -e "\033[1;34m========== 脚本执行完成 ==========\033[0m"