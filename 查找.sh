#!/usr/bin/env bash
#
# 查找 Ubuntu 系统内文件脚本
# 使用: ./find_file.sh
#

# ========= 颜色定义 =========
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

# ============ 函数：显示提示信息 ============
show_usage() {
    echo -e "${GREEN}用法: ${RESET}"
    echo -e "  1) 脚本启动后，会提示输入要搜索的文件名或通配符，比如："
    echo -e "     - myfile.txt"
    echo -e "     - *.sh"
    echo -e "     - config* 等等\n"
    echo -e "  2) 是否区分大小写：若选择 'n'，将对大小写不敏感；否则精确匹配大小写。"
    echo -e "  3) 选择搜索方式：find（实时搜索）或 locate（数据库搜索）。"
    echo -e "  4) 选择搜索目录：默认为 /（根目录），可自定义。\n"
    echo -e "${YELLOW}注意: locate 使用前，若数据库过久未更新，可手动执行 'sudo updatedb'。${RESET}\n"
}

# ============ 开始脚本逻辑 ============
clear
echo -e "${BLUE}====================================="
echo -e "  欢迎使用系统文件查找脚本"
echo -e "  当前系统: $(lsb_release -d | awk -F'\t' '{print $2}')"
echo -e "=====================================${RESET}\n"

show_usage

# 1) 输入搜索关键字
read -rp "请输入要搜索的文件名(支持通配符): " PATTERN
if [ -z "$PATTERN" ]; then
    echo -e "${RED}未输入搜索关键字，脚本退出。${RESET}"
    exit 1
fi

# 2) 是否区分大小写
read -rp "是否区分大小写? (y/n, 默认 n): " CASE_SENSE
CASE_SENSE=${CASE_SENSE:-n}
if [[ "$CASE_SENSE" =~ ^[Yy]$ ]]; then
    IGNORE_CASE="OFF"
    echo -e "已选择【区分】大小写。"
else
    IGNORE_CASE="ON"
    echo -e "已选择【不区分】大小写。"
fi

# 3) 选择搜索方式: find / locate
echo -e "\n可以选择以下搜索方式:"
echo "  1) find   (系统实时搜索, 比较慢但准确)"
echo "  2) locate (基于数据库搜索, 速度快但需数据库更新)"
read -rp "请选择搜索方式 [1/2，默认1]: " SEARCH_METHOD
SEARCH_METHOD=${SEARCH_METHOD:-1}

# 4) 选择搜索目录
read -rp "请输入搜索目录(默认为 / ): " SEARCH_DIR
SEARCH_DIR=${SEARCH_DIR:-"/"}

echo -e "\n${YELLOW}>>> 开始搜索...${RESET}"

# ============ 核心搜索逻辑 ============
# 如果区分大小写为 OFF，则 find 添加 -iname / locate 添加 -i
# 如果区分大小写为 ON，则 find 添加 -name / locate 不添加 -i
case "$SEARCH_METHOD" in
    1)
        # 使用 find
        if [ "$IGNORE_CASE" = "ON" ]; then
            # 不区分大小写
            echo -e "${BLUE}[DEBUG] find ${SEARCH_DIR} -iname \"$PATTERN\"${RESET}"
            sudo find "$SEARCH_DIR" -iname "$PATTERN" 2>/dev/null
        else
            # 区分大小写
            echo -e "${BLUE}[DEBUG] find ${SEARCH_DIR} -name \"$PATTERN\"${RESET}"
            sudo find "$SEARCH_DIR" -name "$PATTERN" 2>/dev/null
        fi
        ;;
    2)
        # 使用 locate
        # locate 不同发行版可能有所差别，此处以常见配置为例
        if ! command -v locate &>/dev/null; then
            echo -e "${RED}系统未安装 locate，请先安装 (sudo apt-get install mlocate) 或使用 find。${RESET}"
            exit 1
        fi
        
        if [ "$IGNORE_CASE" = "ON" ]; then
            # 不区分大小写
            echo -e "${BLUE}[DEBUG] locate -i \"$PATTERN\"${RESET}"
            locate -i "$PATTERN"
        else
            # 区分大小写
            echo -e "${BLUE}[DEBUG] locate \"$PATTERN\"${RESET}"
            locate "$PATTERN"
        fi
        ;;
    *)
        echo -e "${RED}无效输入，请重新运行脚本并选择正确的搜索方式。${RESET}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}搜索完成！如结果过多，可通过 'grep' 等命令过滤。${RESET}"
