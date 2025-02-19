#!/bin/bash

# =====================================================
#          Gaoce AI 训练系统 v1.0
#        傻瓜式训练流程 | 每步提示 | 增加私有知识库与Prompts
# =====================================================

# 训练数据目录和配置路径
TRAIN_DIR="$HOME/ai_trainings"
KNOWLEDGE_BASE_DIR="$HOME/ai_knowledge_base"
PROMPTS_DIR="$HOME/ai_prompts"
mkdir -p $TRAIN_DIR $KNOWLEDGE_BASE_DIR $PROMPTS_DIR

# 设置颜色提示
CYAN="\033[36m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# 显示Logo和欢迎界面
show_logo() {
    clear
    echo -e "${CYAN}
    ┌──────────────────────────────────────────────────────────────┐
    │                                                              │
    │   ██████   █████   ██████   ██████  ███████                  │
    │   ██   ██ ██   ██ ██    ██ ██    ██ ██                       │
    │   ██████  ███████ ██    ██ ██    ██ █████                    │
    │   ██   ██ ██   ██ ██    ██ ██    ██ ██                       │
    │   ██████  ██   ██  ██████   ██████  ███████                  │
    │                                                              │
    │   AI 训练系统 v1.0                                           │
    │   傻瓜式训练流程 | 每步提示 | 增加私有知识库与Prompts        │
    │                                                              │
    └──────────────────────────────────────────────────────────────┘
    ${RESET}"
    echo -e "${GREEN}欢迎使用 Gaoce AI 训练系统！${RESET}"
    echo -e "${YELLOW}如有问题，请联系：support@gaoceai.com${RESET}"
    echo -e "${CYAN}===================================================${RESET}"
}

# 1. 环境配置：虚拟环境和依赖项安装
install_environment() {
    echo -e "\033[36m步骤1：创建虚拟环境并安装依赖...\033[0m"
    echo -e "\033[36m虚拟环境的作用：\033[0m"
    echo -e "1. \033[32m隔离依赖\033[0m：避免不同项目的依赖冲突。"
    echo -e "2. \033[32m保持系统干净\033[0m：不会影响系统的全局 Python 环境。"
    echo -e "3. \033[32m方便管理\033[0m：每个项目都有独立的运行环境。"
    
    if [ ! -d "./venv" ]; then
        echo -e "\033[32m虚拟环境不存在，创建新的虚拟环境...\033[0m"
        python3 -m venv ./venv
        source ./venv/bin/activate
        echo -e "\033[32m虚拟环境已创建并激活！\033[0m"
    else
        echo -e "\033[32m虚拟环境已存在，直接激活...\033[0m"
        source ./venv/bin/activate
    fi
    
    # 安装依赖项
    echo -e "\033[36m安装训练所需的依赖：torch, torchvision, transformers, deepspeed...\033[0m"
    pip install --upgrade pip
    pip install torch torchvision torchaudio transformers deepspeed optuna faiss prompts axios
    echo -e "\033[32m依赖项安装成功！\033[0m"
}

# 2. 数据准备：下载并准备数据集
prepare_data() {
    echo -e "\033[36m步骤2：准备训练数据...\033[0m"
    echo -e "\033[36m数据准备的作用：\033[0m"
    echo -e "1. \033[32m提供训练素材\033[0m：数据是模型训练的基础。"
    echo -e "2. \033[32m支持多种任务\033[0m：可以是文本（NLP任务）或图像（CV任务）。"
    echo -e "3. \033[32m提高模型性能\033[0m：高质量的数据集有助于训练出更好的模型。"
    
    read -p "请输入数据集文件夹路径（例如：./dataset）： " dataset_dir
    mkdir -p $dataset_dir
    echo -e "\033[32m数据目录已创建：$dataset_dir\033[0m"
    
    echo -e "\033[36m数据准备完成！你可以将数据文件上传至此目录。\033[0m"
}

# 3. 私有知识库管理：上传并检索知识库数据
manage_knowledge_base() {
    echo -e "\033[36m步骤3：管理私有知识库...\033[0m"
    echo -e "\033[36m知识库的作用：\033[0m"
    echo -e "1. \033[32m存储私有数据\033[0m：用于模型的知识检索（RAG任务）。"
    echo -e "2. \033[32m支持文档上传\033[0m：可以将文档上传至知识库。"
    echo -e "3. \033[32m提高模型智能\033[0m：通过知识库增强模型的知识能力。"
    
    # 假设 `AnythingLLMDesktop` 提供了一个简单的 HTTP API，允许文件上传
    read -p "请输入文档路径来上传至知识库（例如：./docs/document.pdf）： " doc_path
    curl -X POST -F "file=@$doc_path" http://localhost:5000/upload
    
    echo -e "\033[32m文档上传成功！\033[0m"
    echo -e "\033[36m当前知识库目录：$KNOWLEDGE_BASE_DIR\033[0m"
}

# 4. 设置Prompts：优化模型的Prompt输入
set_prompts() {
    echo -e "\033[36m步骤4：设置Prompts...\033[0m"
    echo -e "\033[36mPrompt的作用：\033[0m"
    echo -e "1. \033[32m引导模型输出\033[0m：通过Prompt控制模型生成的内容。"
    echo -e "2. \033[32m提高任务准确性\033[0m：明确的Prompt有助于模型更好地理解任务。"
    echo -e "3. \033[32m支持自定义任务\033[0m：可以根据需求设计不同的Prompt。"
    
    # 使用npm的prompts库来交互式设置Prompt
    npm install --save prompts
    node -e "
    const prompts = require('prompts');
    (async () => {
      const response = await prompts({
        type: 'text',
        name: 'prompt',
        message: '请输入用于训练任务的Prompt文本（例如：\"给定输入，生成故事\"）：'
      });
      console.log(\`你的Prompt：\${response.prompt}\`);
      require('fs').writeFileSync('./ai_prompts/custom_prompt.txt', response.prompt);
    })();
    "
    echo -e "\033[32mPrompt设置完成！\033[0m"
    echo "你可以在$PROMPTS_DIR目录下查看和修改已设置的Prompts。"
}

# 5. 训练模型：选择训练方式（单机/分布式）
train_model() {
    echo -e "\033[36m步骤5：选择训练方式（单机/分布式训练）...\033[0m"
    echo -e "\033[36m训练方法说明：\033[0m"
    echo -e "1. \033[32m单机训练\033[0m：适合小规模数据集和单GPU环境。"
    echo -e "2. \033[32m分布式训练\033[0m：适合大规模数据集和多GPU环境，加速训练过程。"
    
    select train_mode in "单机训练" "分布式训练" "退出"; do
        case $train_mode in
            "单机训练")
                echo -e "\033[36m开始单机训练...\033[0m"
                read -p "请输入训练脚本路径（例如：train.py）： " train_script
                python $train_script 2>&1 | tee $TRAIN_DIR/train_log.log
                break
                ;;
            "分布式训练")
                echo -e "\033[36m开始分布式训练...\033[0m"
                read -p "请输入训练脚本路径（例如：train.py）： " train_script
                num_gpus=$(nvidia-smi -L | wc -l)
                if (( num_gpus > 1 )); then
                    deepspeed --num_gpus $num_gpus $train_script | tee $TRAIN_DIR/train_log.log
                else
                    echo -e "\033[31m分布式训练需要至少2个GPU！\033[0m"
                fi
                break
                ;;
            "退出")
                echo -e "\033[31m退出训练系统。\033[0m"
                exit 0
                ;;
            *)
                echo -e "\033[31m无效选项，请重新选择。\033[0m"
                ;;
        esac
    done
}

# 6. 训练监控
monitor_training() {
    echo -e "\033[36m步骤6：实时训练监控...\033[0m"
    echo -e "\033[36m监控的作用：\033[0m"
    echo -e "1. \033[32m实时查看训练进度\033[0m：了解模型的训练状态。"
    echo -e "2. \033[32m快速发现问题\033[0m：如训练中断或性能下降。"
    echo -e "3. \033[32m优化训练过程\033[0m：根据监控结果调整参数。"
    
    tail -f ./train_log.log
}

# 7. 导出模型：将训练后的模型导出为ONNX格式
export_model() {
    echo -e "\033[36m步骤7：导出训练后的模型...\033[0m"
    echo -e "\033[36m模型导出的作用：\033[0m"
    echo -e "1. \033[32m跨平台部署\033[0m：ONNX格式支持多种框架和硬件。"
    echo -e "2. \033[32m提高兼容性\033[0m：方便与其他系统集成。"
    echo -e "3. \033[32m优化推理性能\033[0m：ONNX模型通常具有更高的推理效率。"
    
    read -p "请输入训练后模型的路径（例如：model.pth）： " model_path
    python -c "
from torch.onnx import export
import torch
model = torch.load('$model_path')
dummy_input = torch.randn(1, 3, 224, 224)  # 示例输入
export(model, dummy_input, '$model_path.onnx')"
    
    echo -e "\033[32m模型导出成功！ONNX模型保存在：$model_path.onnx\033[0m"
}

# 8. 主菜单：选择操作
main_menu() {
    while true; do
        show_logo
        echo -e "\033[36m===== Gaoce AI 训练系统 =====\033[0m"
        echo "1. 安装环境"
        echo "2. 准备数据集"
        echo "3. 管理私有知识库"
        echo "4. 设置Prompts"
        echo "5. 训练模型"
        echo "6. 训练监控"
        echo "7. 导出训练模型"
        echo "0. 退出系统"
        echo -e "============================\033[0m"
        echo -e "${YELLOW}提示：请根据提示逐步操作，如有问题请联系 support@gaoceai.com${RESET}"
        
        read -p "请输入选项: " choice
        case $choice in
            1)
                install_environment
                ;;
            2)
                prepare_data
                ;;
            3)
                manage_knowledge_base
                ;;
            4)
                set_prompts
                ;;
            5)
                train_model
                ;;
            6)
                monitor_training
                ;;
            7)
                export_model
                ;;
            0)
                echo -e "\033[31m退出系统...\033[0m"
                exit 0
                ;;
            *)
                echo -e "\033[31m无效选项！请重新选择。\033[0m"
                ;;
        esac
    done
}

# =======================================
# 训练系统启动
# =======================================
main_menu
