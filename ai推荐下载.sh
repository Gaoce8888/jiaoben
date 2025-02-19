#!/bin/bash

# --------------------------
# 品牌Logo展示函数
# --------------------------
show_logo() {
    clear
    echo -e "\033[1;36m
    ██████╗  █████╗  ██████╗███████╗     █████╗ ██╗
    ██╔═══██╗██╔══██╗██╔════╝██╔════╝    ██╔══██╗██║
    ██║   ██║███████║██║     █████╗      ███████║██║
    ██║   ██║██╔══██║██║     ██╔══╝      ██╔══██║██║
    ╚██████╔╝██║  ██║╚██████╗███████╗    ██║  ██║███████╗
    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝    ╚═╝  ╚═╝╚══════╝
    \033[0m
    \033[32m──────────────────────────────────────────────
     gaoce.ai 极简AI \033[1;33mQQ: 260060440\033[0m
    \033[32m──────────────────────────────────────────────\033[0m
    "
}

# --------------------------
# 可编辑配置区
# --------------------------
MODEL_DIR="./modelscope_models"  # 模型存储目录

# 模型清单（名称|模型ID|文件路径|SHA256校验码）
MODEL_LIST=(
    "BERT中文模型|damo/nlp_bert_word-segmentation_chinese-base|pytorch_model.bin|a1b2c3d4..."
    "YOLOv6目标检测|damo/cv_yolov6_object-detection_keypoints|yolov6s.pt|e5f6g7h8..."
    "语音识别模型|damo/speech_paraformer-large_asr_nat-zh-cn|model.pb|i9j0k1l2..."
)

# --------------------------
# 功能函数
# --------------------------
# 带颜色输出
color_echo() {
    echo -e "\033[$1m$2\033[0m"
}

# 动态进度条
progress_bar() {
    local pid=$1
    local delay=0.5
    local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    
    while kill -0 $pid 2>/dev/null; do
        for i in "${spin[@]}"; do
            printf "\r[%s] 下载中..." "$i"
            sleep $delay
        done
    done
    printf "\r\033[K[✔] 下载完成\n"
}

# 文件校验
verify_hash() {
    local file_hash=$(sha256sum "$1" | awk '{print $1}')
    [[ "$file_hash" == "$2" ]]
}

# --------------------------
# 主程序逻辑
# --------------------------
show_logo  # 显示品牌Logo

# 显示模型菜单
color_echo "36" "\n🛒 可用模型列表："
for idx in "${!MODEL_LIST[@]}"; do
    IFS='|' read -r name id _ _ <<< "${MODEL_LIST[$idx]}"
    printf "  \033[1;35m%2d)\033[0m %-28s \033[2m(ID: %s)\033[0m\n" $((idx+1)) "$name" "$id"
done

# 用户输入处理
echo -e "\n\033[1;32m⌨ 输入选项（多个用空格分隔，0退出，a全选）:\033[0m"
read -p "> " choices

# 退出处理
[[ "$choices" == "0" ]] && exit 0

# 创建存储目录
mkdir -p "$MODEL_DIR" || { color_echo "31" "❌ 目录创建失败"; exit 1; }

# 处理全选
if [[ "$choices" == "a" ]]; then
    selected=($(seq 1 ${#MODEL_LIST[@]}))
else
    selected=($choices)
fi

# 下载主循环
for input in "${selected[@]}"; do
    # 输入验证
    if ! [[ "$input" =~ ^[0-9]+$ ]] || ((input < 1 || input > ${#MODEL_LIST[@]})); then
        color_echo "31" "⚠ 无效选项: $input"
        continue
    fi

    # 解析配置
    idx=$((input-1))
    IFS='|' read -r name model_id file_path expect_hash <<< "${MODEL_LIST[$idx]}"
    save_name="${model_id//\//_}_${file_path}"  # 处理特殊字符
    save_path="${MODEL_DIR}/${save_name}"
    model_url="https://modelscope.cn/api/v1/models/${model_id}/repo?Revision=master&FilePath=${file_path}"

    # 文件校验
    if [[ -f "$save_path" ]]; then
        if verify_hash "$save_path" "$expect_hash"; then
            color_echo "32" "✅ [$name] 文件已存在且通过校验"
            continue
        else
            color_echo "33" "🔄 [$name] 文件校验失败，重新下载..."
            rm -f "$save_path"
        fi
    fi

    # 下载执行
    color_echo "36" "🚀 开始下载: \033[1;37m${name}\033[0m"
    (wget -c -q --show-progress -O "$save_path" "$model_url" 2>&1 &)
    progress_bar $!

    # 最终校验
    if verify_hash "$save_path" "$expect_hash"; then
        color_echo "32" "✅ [$name] 下载校验通过"
    else
        color_echo "31" "❌ [$name] 文件损坏！已删除无效文件"
        rm -f "$save_path"
    fi
done

# 结束提示
echo -e "\n\033[32m──────────────────────────────────────────────
 感谢使用！遇到问题请联系：
 \033[1;33mQQ: 260060440\033[0m
\033[32m──────────────────────────────────────────────\033[0m\n"