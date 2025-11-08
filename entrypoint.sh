#!/bin/sh

# =================================================================
# 动态创建 rclone 配置文件
# =================================================================
if [ -n "$RCLONE_CONF_BASE64" ]; then
  echo "正在从 RCLONE_CONF_BASE64 环境变量创建 rclone 配置文件..."
  # 确保配置目录存在
  mkdir -p /root/.config/rclone
  # 解码环境变量并写入配置文件
  echo "$RCLONE_CONF_BASE64" | base64 -d > /root/.config/rclone/rclone.conf
  echo "rclone.conf 文件已成功创建。"
else
  # 如果没有设置环境变量，备份将无法工作
  echo "警告：未找到 RCLONE_CONF_BASE64 环境变量。备份功能将无法使用。"
fi
# =================================================================

# 启动 Memos 应用（在后台运行）
/usr/local/memos/memos --mode prod --port 5230 &

echo "Memos 服务已启动..."

# 启动文件变更监控
echo "启动文件变更监控..."
while true; do
  inotifywait -rq -e modify,create,delete,move /var/opt/memos

  echo "检测到文件变更，将在10秒后开始备份..."
  sleep 10
  
  # 调用备份脚本
  /usr/local/bin/backup.sh
done &

# 等待所有后台进程
wait -n
