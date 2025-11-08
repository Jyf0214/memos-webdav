#!/bin/sh

# =================================================================
# Rclone 加密说明
# =================================================================
# 本脚本使用 rclone 进行数据备份。为了实现数据库加密，您需要
# 在 rclone 的配置文件 (rclone.conf) 中设置一个 "crypt" 远端。
#
# entrypoint.sh 脚本会根据 RCLONE_CONF_BASE64 环境变量
# 自动创建 rclone.conf 文件。请确保您的配置中包含加密设置。
# =================================================================

# 从环境变量读取远程路径
# 如果环境变量未设置，则使用默认路径
if [ -z "$RCLONE_REMOTE_PATH" ]; then
  echo "警告：环境变量 RCLONE_REMOTE_PATH 未设置，使用默认路径 memos_data:memos_backup"
  RCLONE_REMOTE_PATH="memos_data:memos_backup"
fi

MEMOS_DATA_DIR="/var/opt/memos"

echo "----------------------------------------"
echo "开始备份 Memos 数据到 ${RCLONE_REMOTE_PATH}"
echo "时间: $(date)"
echo "----------------------------------------"

# 使用 rclone 同步数据
rclone sync "${MEMOS_DATA_DIR}" "${RCLONE_REMOTE_PATH}" --update --verbose --transfers 4

if [ $? -eq 0 ]; then
  echo "备份成功！"
else
  echo "备份失败！请检查 rclone 配置和日志。"
fi

echo "----------------------------------------"
echo "备份完成。"
echo "----------------------------------------"
