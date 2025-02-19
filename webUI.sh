#!/bin/bash
# 全功能WebUI套件 v2.0
# 功能: 一键部署+接口绑定+可视化管理
# 官网: gaoce.ai | 技术支持: QQ 260060440

# ======================= 配置区 =======================
WEBUI_PORT=7860                 # 默认服务端口
INSTALL_DIR="/opt/gaoce_webui"  # 安装目录
GIT_REPO="https://github.com/your/repo.git"  # 项目仓库
# =====================================================

# 颜色定义
RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; BLUE="\033[34m"; RESET="\033[0m"

# --------------------- 核心函数 ---------------------
deploy_webui() {
    echo -e "${GREEN}>>> 开始系统环境检测...${RESET}"
    # 系统检测
    if ! command -v apt &>/dev/null && ! command -v yum &>/dev/null; then
        echo -e "${RED}✗ 仅支持Ubuntu/CentOS系统！${RESET}"
        exit 1
    fi

    # 安装依赖
    echo -e "${GREEN}>>> 安装系统依赖...${RESET}"
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y git curl nginx certbot python3-pip nodejs docker.io
    else
        sudo yum install -y epel-release && sudo yum install -y git curl nginx certbot python3-pip nodejs docker
    fi

    # 克隆仓库
    echo -e "${GREEN}>>> 部署项目文件到 $INSTALL_DIR ...${RESET}"
    sudo mkdir -p $INSTALL_DIR
    sudo git clone $GIT_REPO $INSTALL_DIR || { echo -e "${RED}✗ 仓库克隆失败！${RESET}"; exit 1; }

    # 构建项目
    echo -e "${GREEN}>>> 安装项目依赖...${RESET}"
    cd $INSTALL_DIR
    pip3 install -r requirements.txt || { echo -e "${RED}✗ Python依赖安装失败！${RESET}"; exit 1; }
    npm install && npm run build || { echo -e "${RED}✗ 前端构建失败！${RESET}"; exit 1; }

    # 创建服务
    echo -e "${GREEN}>>> 配置系统服务...${RESET}"
    sudo bash -c "cat > /etc/systemd/system/gaoce-webui.service" <<EOF
[Unit]
Description=Gaoce WebUI Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 app.py --port $WEBUI_PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now gaoce-webui.service
}

bind_domain() {
    read -p "请输入要绑定的域名: " domain
    if [[ ! $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}✗ 域名格式错误！${RESET}"
        return
    fi

    echo -e "${GREEN}>>> 为 $domain 配置SSL证书...${RESET}"
    sudo certbot certonly --nginx -d $domain --non-interactive --agree-tos -m admin@$domain

    echo -e "${GREEN}>>> 生成Nginx配置...${RESET}"
    sudo bash -c "cat > /etc/nginx/conf.d/gaoce-webui.conf" <<EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $domain;

    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:$WEBUI_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

    sudo nginx -t && sudo systemctl reload nginx
}

show_menu() {
    clear
    echo -e "${BLUE}
    ██████╗  █████╗  ██████╗  ██████╗███████╗
    ██╔════╝ ██╔══██╗██╔════╝ ██╔════╝██╔════╝
    ██║  ███╗███████║██║  ███╗██║     █████╗  
    ██║   ██║██╔══██║██║   ██║██║     ██╔══╝  
    ╚██████╔╝██║  ██║╚██████╔╝╚██████╗███████╗
     ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝
    ${RESET}"
    echo -e "${GREEN}=== 主菜单 ===${RESET}"
    echo -e "1. 一键完整部署"
    echo -e "2. 绑定域名接口"
    echo -e "3. 服务状态管理"
    echo -e "4. 查看实时日志"
    echo -e "0. 退出"
    echo -e "${GREEN}===============${RESET}"
}

# --------------------- 执行逻辑 ---------------------
while true; do
    show_menu
    read -p "请输入选项数字: " choice
    case $choice in
        1) deploy_webui ;;
        2) bind_domain ;;
        3) sudo systemctl status gaoce-webui.service ;;
        4) sudo tail -f $INSTALL_DIR/webui.log ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项！${RESET}" ;;
    esac
    read -p "按回车返回主菜单..."
done