import os
import time
import json
import logging
import requests
import redis
import pymysql
import psycopg2
import pymongo
import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
from sklearn.cluster import DBSCAN
from flask import Flask, request

# 配置日志
logging.basicConfig(filename='ub_advanced_check.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# 连接 Redis 缓存
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

# MySQL 连接
db_mysql = pymysql.connect(host="localhost", user="root", password="password", database="ub_db")
cursor_mysql = db_mysql.cursor()

# PostgreSQL 连接
db_postgres = psycopg2.connect(host="localhost", user="postgres", password="password", database="ub_db")
cursor_postgres = db_postgres.cursor()

# MongoDB 连接
db_mongo = pymongo.MongoClient("mongodb://localhost:27017/")
mongo_collection = db_mongo["ub_db"]["ub_logs"]

# Flask API 监控
app = Flask(__name__)

@app.route("/health", methods=["GET"])
def health_check():
    return json.dumps({"status": "OK"}), 200

# **智能数据一致性检查**
def check_database_consistency():
    logging.info(">>> 开始数据库一致性检查...")

    cursor_mysql.execute("SELECT COUNT(*) FROM user_behavior")
    mysql_count = cursor_mysql.fetchone()[0]

    cursor_postgres.execute("SELECT COUNT(*) FROM user_behavior")
    postgres_count = cursor_postgres.fetchone()[0]

    mongo_count = mongo_collection.count_documents({})

    logging.info(f"MySQL: {mysql_count}, PostgreSQL: {postgres_count}, MongoDB: {mongo_count}")

    if abs(mysql_count - postgres_count) > 10 or abs(mysql_count - mongo_count) > 10:
        logging.warning("❌ 数据库数据不一致！可能有数据丢失")
        return False
    else:
        logging.info("✅ 数据一致")
        return True

# **AI 异常行为检测**
def detect_abnormal_behavior():
    logging.info(">>> AI 异常行为检测...")
    cursor_mysql.execute("SELECT user_id, action, timestamp FROM user_behavior")
    data = cursor_mysql.fetchall()
    df = pd.DataFrame(data, columns=['user_id', 'action', 'timestamp'])

    df['timestamp'] = pd.to_datetime(df['timestamp'])
    df['hour'] = df['timestamp'].dt.hour
    action_counts = df.groupby(['user_id', 'hour']).size().reset_index(name='count')

    # **Isolation Forest 识别异常行为**
    model = IsolationForest(contamination=0.02, random_state=42)
    action_counts['anomaly'] = model.fit_predict(action_counts[['count']])

    # **DBSCAN 发现异常群体**
    dbscan = DBSCAN(eps=5, min_samples=2)
    action_counts['cluster'] = dbscan.fit_predict(action_counts[['count']])

    anomalies = action_counts[action_counts['anomaly'] == -1]
    
    if not anomalies.empty:
        logging.warning(f"❌ 发现异常行为: \n{anomalies}")
        return False
    else:
        logging.info("✅ 用户行为正常")
        return True

# **日志智能分析**
def analyze_logs():
    logging.info(">>> 分析 UB 系统日志...")
    error_count = 0
    with open("ub_system.log", "r") as log_file:
        for line in log_file:
            if "ERROR" in line or "Exception" in line:
                error_count += 1
    
    logging.info(f"检测到 {error_count} 条错误日志")
    if error_count > 5:
        logging.warning("❌ 日志错误率过高，请检查 UB 系统")
        return False
    return True

# **UB API 健康检查**
def test_ub_api():
    logging.info(">>> UB API 健康检查...")
    try:
        response = requests.get("http://localhost:5000/health")
        if response.status_code == 200:
            logging.info("✅ UB API 正常")
            return True
        else:
            logging.warning(f"❌ UB API 返回异常状态码: {response.status_code}")
            return False
    except Exception as e:
        logging.error(f"❌ UB API 连接失败: {e}")
        return False

# **服务器资源负载监控**
def check_system_performance():
    logging.info(">>> 监控 CPU/内存/磁盘...")
    cpu_usage = os.popen("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'").read().strip()
    mem_usage = os.popen("free -m | awk 'NR==2{printf \"%s/%sMB (%.2f%%)\", $3,$2,$3*100/$2 }'").read().strip()
    disk_usage = os.popen("df -h / | awk 'NR==2 {print $5}'").read().strip()

    logging.info(f"CPU: {cpu_usage}%, 内存: {mem_usage}, 磁盘: {disk_usage}")

    if float(cpu_usage) > 80:
        logging.warning("⚠️ CPU 过高！")
    if "100%" in mem_usage:
        logging.warning("⚠️ 内存满载！")
    if int(disk_usage.replace("%", "")) > 90:
        logging.warning("⚠️ 磁盘即将满！")

# **自动修复机制**
def auto_fix():
    logging.info(">>> 触发自动修复...")
    redis_client.flushall()
    logging.info("✅ 清理 Redis 缓存")
    
    if not test_ub_api():
        logging.info("🔄 重启 UB API 服务...")
        os.system("systemctl restart ub_service")
        time.sleep(5)
        if test_ub_api():
            logging.info("✅ UB API 已恢复")
        else:
            logging.error("❌ UB API 仍不可用")

# **运行深度优化 UB 检测**
def run_ub_advanced_check():
    logging.info("====== UB 深度优化检测开始 ======")
    db_check = check_database_consistency()
    behavior_check = detect_abnormal_behavior()
    log_check = analyze_logs()
    api_check = test_ub_api()
    check_system_performance()

    # 触发修复机制
    if not db_check or not behavior_check or not log_check or not api_check:
        auto_fix()

    logging.info("====== UB 系统检测完成 ======")

# **启动检测**
if __name__ == "__main__":
    run_ub_advanced_check()
