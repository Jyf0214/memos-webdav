#!/bin/bash

# =================================================================
# Rclone 自动备份与恢复脚本
# =================================================================
# 1. 如果本地数据目录为空，脚本会自动从远程拉取最新的备份进行恢复。
# 2. 如果本地数据目录不为空，脚本会执行版本化备份，并自动轮转，只保留最新的10个版本。
# =================================================================

# --- 配置与伪装日志 ---

# 从环境变量读取远程路径,如果未设置则使用默认值
# 注意：路径末尾添加了 /versions 以存放所有版本化备份
RCLONE_REMOTE_PATH=${RCLONE_REMOTE_PATH:-"memos_data:memos_backup/versions"}
MEMOS_DATA_DIR="/var/opt/memos"
MAX_BACKUPS=10
LOCK_FILE="/tmp/memos_backup.lock"

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

# --- 新增：恢复逻辑 ---
run_restore() {
    echo "--- 开始执行数据恢复 ---"

    # 检查 rclone 配置文件
    if ! rclone listremotes >/dev/null 2>&1; then
        echo "错误：rclone 配置不正确或不存在，无法恢复。" >&2
        exit 1
    fi

    echo "正在从远程 '${RCLONE_REMOTE_PATH}' 查找最新的备份..."
    # 查找最新的备份目录, 忽略 rclone 的错误输出（比如路径不存在）
    LATEST_BACKUP_DIR=$(rclone lsf --dirs-only "${RCLONE_REMOTE_PATH}" 2>/dev/null | sort | tail -n 1)

    if [ -z "$LATEST_BACKUP_DIR" ]; then
        echo "警告：在远程路径中没有找到任何备份版本。将以一个空的 Memos 实例开始。"
        # 确保本地目录存在，以便 Memos 可以正常启动
        mkdir -p "${MEMOS_DATA_DIR}"
        echo "--- 恢复过程结束（未找到备份） ---"
        return 0
    fi

    FULL_REMOTE_PATH="${RCLONE_REMOTE_PATH}/${LATEST_BACKUP_DIR}"
    echo "找到最新备份: ${FULL_REMOTE_PATH}"
    echo "正在将数据恢复到: ${MEMOS_DATA_DIR}"

    # 创建本地目录（如果不存在）
    mkdir -p "${MEMOS_DATA_DIR}"

    # 使用 'rclone copy' 恢复数据
    rclone copy "${FULL_REMOTE_PATH}" "${MEMOS_DATA_DIR}" --progress --transfers 4
    rc_status=$?

    if [ $rc_status -eq 0 ]; then
        echo "✅ 数据恢复成功！"
        echo "重要提示：如果 Memos 启动失败，请检查 '${MEMOS_DATA_DIR}' 的文件权限。"
    else
        echo "❌ 错误：数据恢复失败！请检查 rclone 日志。" >&2
    fi
    echo "--- 恢复过程结束 ---"
}

# --- 主要备份逻辑 (无重大修改) ---
run_backup() {
    # 检查 rclone 配置文件是否存在
    if ! rclone listremotes >/dev/null 2>&1; then
        if [ -n "$DEBUG" ]; then
            echo "错误：rclone 配置不正确或不存在。请检查 RCLONE_CONF_BASE64 环境变量。"
        fi
        exit 1
    fi

    # 创建当前备份的时间戳和路径
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    CURRENT_BACKUP_PATH="${RCLONE_REMOTE_PATH}/${TIMESTAMP}"

    # 根据 DEBUG 模式设置 rclone 参数
    local rclone_opts
    if [ -n "$DEBUG" ]; then
        echo "----------------------------------------"
        echo "DEBUG 模式：开始创建新的版本化备份"
        echo "时间: $(date)"
        echo "备份到: ${CURRENT_BACKUP_PATH}"
        echo "----------------------------------------"
        rclone_opts="--verbose --transfers 4"
    else
        rclone_opts="--quiet --transfers 4"
    fi

    # 使用 'rclone copy' 将数据备份到新的时间戳目录
    rclone copy "${MEMOS_DATA_DIR}" "${CURRENT_BACKUP_PATH}" ${rclone_opts}
    rc_status=$?

    # --- 日志与清理 ---

    if [ $rc_status -eq 0 ]; then
        # 备份成功
        if [ -z "$DEBUG" ] && [ -n "$SPACE_ID" ]; then
            # 非 DEBUG 模式，输出伪装日志
            if (( RANDOM % 10 == 0 )); then
                rand_index=$((RANDOM % ${#AI_LOGS[@]}))
                echo "${AI_LOGS[$rand_index]}"
            else
                rand_index=$((RANDOM % ${#FAKE_SUCCESS_LOGS[@]}))
                echo "${FAKE_SUCCESS_LOGS[$rand_index]}"
            fi
        else
            echo "备份成功！新的版本已创建于 ${CURRENT_BACKUP_PATH}"
        fi

        # 清理旧备份
        if [ -n "$DEBUG" ]; then
            echo "开始清理旧备份，保留最新的 ${MAX_BACKUPS} 个。"
        fi
        
        # 列出所有备份目录，按名称排序（即按时间排序），然后删除最旧的
        rclone lsf --dirs-only "${RCLONE_REMOTE_PATH}" | sort | head -n -${MAX_BACKUPS} | while read -r dir; do
            # 确保 dir 不是空的
            if [ -n "$dir" ]; then
                dir_to_delete="${RCLONE_REMOTE_PATH}/${dir}"
                if [ -n "$DEBUG" ]; then
                    echo "删除旧备份: ${dir_to_delete}"
                fi
                rclone purge "${dir_to_delete}" ${rclone_opts}
            fi
        done
        
        if [ -n "$DEBUG" ]; then
            echo "----------------------------------------"
            echo "备份与清理完成。"
            echo "----------------------------------------"
        fi
    else
        # 备份失败
        echo "备份失败！请检查 rclone 配置和日志。" >&2
        # 清理失败的备份目录
        if [ -n "$DEBUG" ]; then
            echo "正在清理失败的备份目录: ${CURRENT_BACKUP_PATH}"
        fi
        rclone purge "${CURRENT_BACKUP_PATH}" ${rclone_opts}
    fi
}

# --- 主执行逻辑 ---
# 使用 flock 确保脚本的单个实例运行，防止并发问题
(
  flock -n 9 || { echo "备份或恢复任务已在运行中，本次跳过。" >&2; exit 1; }

  # 决策逻辑：如果本地数据目录为空，则恢复；否则，备份。
  # 使用 `ls -A` 检查目录是否为空，这种方法直观且足够可靠。
  if [ ! -d "$MEMOS_DATA_DIR" ] || [ -z "$(ls -A "$MEMOS_DATA_DIR")" ]; then
    echo "本地数据目录 '${MEMOS_DATA_DIR}' 为空或不存在，将尝试从最新备份中恢复。"
    run_restore
  else
    echo "本地数据目录存在数据，将执行常规备份。"
    run_backup
  fi

) 9>"$LOCK_FILE"
