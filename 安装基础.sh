#!/bin/bash

# ==============================================
#                 安装基础依赖工具
# ==============================================
install_dependencies() {
    echo -e "\033[36m安装基础工具（git、curl、wget、Python 等）...\033[0m"
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        git \
        wget \
        curl \
        python3 \
        python3-pip \
        python3-venv \
        software-properties-common
    echo -e "\033[32m基础工具安装完成 ✔\033[0m"
}

# ==============================================
#                 安装 CUDA
# ==============================================
install_cuda() {
    read -p "请输入要安装的 CUDA 版本（例如：11.8）：" cuda_version
    wget "https://developer.download.nvidia.com/compute/cuda/${cuda_version}/local_installers/cuda_${cuda_version}_linux.run"
    sudo sh "cuda_${cuda_version}_linux.run" --silent --toolkit --override
    echo -e "\033[32mCUDA 安装完成 ✔\033[0m"
}

# ==============================================
#                 安装 cuDNN
# ==============================================
install_cudnn() {
    read -p "请输入要安装的 CUDA 版本对应的 cuDNN（例如：11.x）：" cudnn_cuda_version
    wget "https://developer.download.nvidia.com/compute/cudnn/8.9.7/local_installers/${cudnn_cuda_version}/cudnn-linux-x86_64-8.9.7.29_cuda${cudnn_cuda_version}-archive.tar.xz"
    tar -xvf "cudnn-linux-x86_64-8.9.7.29_cuda${cudnn_cuda_version}-archive.tar.xz"
    sudo cp cudnn-*-archive/include/cudnn*.h /usr/local/cuda/include
    sudo cp -P cudnn-*-archive/lib/libcudnn* /usr/local/cuda/lib64
    sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*
    echo -e "\033[32mcuDNN 安装完成 ✔\033[0m"
}

install_pytorch() {
    echo -e "\033[36m正在安装 PyTorch 和 vLLM...\033[0m"
    pip install --upgrade pip
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    pip install vllm
    echo -e "\033[32mPyTorch 和 vLLM 安装完成 ✔\033[0m"
}

# ==============================================
# 脚本入口
# ==============================================
install_dependencies
install_cuda
install_cudnn
install_pytorch
