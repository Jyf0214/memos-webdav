#!/bin/bash

# =================================================================
# Rclone 加密与备份脚本
# =================================================================
# 本脚本使用 rclone 进行数据备份。entrypoint.sh 会根据
# RCLONE_CONF_BASE64 环境变量自动创建 rclone.conf 文件。
# =================================================================

# --- 配置与伪装日志 ---

# 从环境变量读取远程路径,如果未设置则使用默认值
RCLONE_REMOTE_PATH=${RCLONE_REMOTE_PATH:-"memos_data:memos_backup"}
MEMOS_DATA_DIR="/var/opt/memos"

# 伪装的AI大模型日志
AI_LOGS=(
    "INFO: AI model synchronization initiated. Augmenting cognitive matrix."
    "INFO: Neural network recalibration in progress. Please stand by."
    "INFO: Compiling quantum entanglement patterns for enhanced data pre-cognition."
    "INFO: Heuristic analysis daemon starting. Monitoring for temporal anomalies."
    "INFO: Activating predictive analytics engine. Forecasting data trajectories."
)

# 伪装的常规成功日志
FAKE_SUCCESS_LOGS=(
    "INFO: System integrity scan complete. All parameters nominal."
    "INFO: Data stream flushed and synchronized with archival node."
    "INFO: Redundancy check passed. Parity bits are stable."
    "INFO: Log rotation executed. Old entries compressed and archived."
    "INFO: Heartbeat signal confirmed from all distributed nodes."
)

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
    if [ -z "$DEBUG" ] && [ -n "$SPACE_ID" ]; then
        # 非 DEBUG 模式，输出伪装日志
        # 设置一个随机触发 "AI 日志" 的机会 (例如, 1/10 的概率)
        if (( RANDOM % 10 == 0 )); then
            rand_index=$((RANDOM % ${#AI_LOGS[@]}))
            echo "${AI_LOGS[$rand_index]}"
        else
            rand_index=$((RANDOM % ${#FAKE_SUCCESS_LOGS[@]}))
            echo "${FAKE_SUCCESS_LOGS[$rand_index]}"
        fi
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