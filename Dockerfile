# 使用官方 Memos 镜像作为基础
FROM neosmemo/memos:stable

# 安装 rclone 和 inotify-tools
# neosmemo/memos 基于 Alpine Linux
RUN apk add --no-cache rclone inotify-tools

# 复制备份脚本和启动脚本
COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 给予脚本执行权限
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh

# 设置容器的入口点
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
