#!/bin/bash

# ==============================================
# 安装 ModelScope
# ==============================================
install_modelscope() {
    echo -e "\033[36m正在安装 ModelScope...\033[0m"
    pip install modelscope==1.11.0 -f https://modelscope.oss-cn-beijing.aliyuncs.com/releases/repo.html
    echo -e "\033[32mModelScope 安装完成 ✔\033[0m"
}

# ==============================================
# 安装 Ollama
# ==============================================
install_ollama() {
    echo -e "\033[36m正在安装 Ollama...\033[0m"
    curl -fsSL https://ollama.com/install | bash
    echo -e "\033[32mOllama 安装完成 ✔\033[0m"
}

# ==============================================
# 安装 vLLM
# ==============================================
install_vllm() {
    echo -e "\033[36m正在安装 vLLM...\033[0m"
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    pip install vllm
    echo -e "\033[32mvLLM 安装完成 ✔\033[0m"
}

# ==============================================
# 安装 HuggingFace
# ==============================================
install_huggingface() {
    echo -e "\033[36m正在安装 HuggingFace Transformers...\033[0m"
    pip install transformers
    echo -e "\033[32mHuggingFace Transformers 安装完成 ✔\033[0m"
}

# ==============================================
# 主菜单 - 选择要安装的模型平台
# ==============================================
echo -e "\033[36m请选择要安装的模型平台：\033[0m"
echo "1. 安装 ModelScope"
echo "2. 安装 Ollama"
echo "3. 安装 vLLM"
echo "4. 安装 HuggingFace"
echo "5. 返回主菜单"
read -p "请选择操作 (1-5): " choice

case $choice in
    1) install_modelscope ;;
    2) install_ollama ;;
    3) install_vllm ;;
    4) install_huggingface ;;
    5) exit 0 ;;
    *) echo -e "\033[31m无效选项!\033[0m" ;;
esac
