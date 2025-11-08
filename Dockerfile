# 使用官方 Memos 镜像作为基础
FROM neosmemo/memos:stable

# 安装 rclone, inotify-tools, curl 并下载 cloudflared
# neosmemo/memos 基于 Alpine Linux
# 注意：此处下载的是 amd64 架构的 cloudflared，如果您的运行环境是 ARM，请修改为 cloudflared-linux-arm64
RUN apk add --no-cache rclone inotify-tools curl && \
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# 复制备份脚本和启动脚本
COPY backup.sh /usr/local/bin/backup.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 给予脚本执行权限并修复可能的 Windows 换行符问题
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/entrypoint.sh && \
    sed -i 's/\r$//' /usr/local/bin/backup.sh && \
    sed -i 's/\r$//' /usr/local/bin/entrypoint.sh

# 设置容器的入口点
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
