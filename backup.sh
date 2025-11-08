#!/bin/sh

# =================================================================
# Rclone 加密与备份脚本
# =================================================================
# 本脚本使用 rclone 进行数据备份。entrypoint.sh 会根据
# RCLONE_CONF_BASE64 环境变量自动创建 rclone.conf 文件。
# =================================================================

# --- 配置 ---

# 从环境变量读取远程路径,如果未设置则使用默认值
RCLONE_REMOTE_PATH=${RCLONE_REMOTE_PATH:-"memos_data:memos_backup"}
MEMOS_DATA_DIR="/var/opt/memos"

# --- 主要备份逻辑 ---

# 检查 rclone 配置文件是否存在，仅在非 DEBUG 模式下静默检查
if ! rclone listremotes >/dev/null 2>&1; then
  if [ -n "$DEBUG" ]; then
    echo "错误：rclone 配置不正确或不存在。请检查 RCLONE_CONF_BASE64 环境变量。"
  fi
  # 在非 DEBUG 模式下，不输出任何信息，静默失败
  exit 1
fi

# 根据是否设置 DEBUG 环境变量来决定 rclone 的输出模式
if [ -n "$DEBUG" ]; then
    echo "----------------------------------------"
    echo "DEBUG 模式：开始备份 Memos 数据到 ${RCLONE_REMOTE_PATH}"
    echo "时间: $(date)"
    echo "----------------------------------------"
    # 在 DEBUG 模式下，使用详细输出
    rclone sync "${MEMOS_DATA_DIR}" "${RCLONE_REMOTE_PATH}" --update --verbose --transfers 4
    rc_status=$?
else
    # 在非 DEBUG 模式下，静默运行 rclone
    rclone sync "${MEMOS_DATA_DIR}" "${RCLONE_REMOTE_PATH}" --update --quiet --transfers 4
    rc_status=$?
fi

# --- 日志输出 ---

if [ $rc_status -eq 0 ]; then
    # 备份成功
    if [ -z "$DEBUG" ]; then
        # 非 DEBUG 模式，输出简单成功日志
        echo "INFO: Data synchronization complete."
    else
        # DEBUG 模式，输出真实日志
        echo "备份成功！"
        echo "----------------------------------------"
        echo "备份完成。"
        echo "----------------------------------------"
    fi
else
    # 备份失败，总是输出错误信息以便排查
    echo "备份失败！请检查 rclone 配置和日志。" >&2
fi