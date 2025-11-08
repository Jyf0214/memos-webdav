# Memos-WebDAV 增强版

> **注意：这不是官方的 Memos 版本，而是第三方开发的增强版本，集成了自动备份功能。**

这是一个基于官方 Memos 项目的第三方增强版本，添加了 WebDAV 自动备份功能。该版本通过 Docker 容器化部署，支持将 Memos 数据自动备份到 WebDAV 或其他支持的远程存储服务。

## 功能特性

- 基于官方 Memos (`neosmemo/memos:stable`) 的完整功能
- 自动备份到 WebDAV 或其他 rclone 支持的存储服务
- 文件系统监控 - 当数据发生变更时自动触发备份
- Rclone 加密支持 - 数据在传输前进行加密
- 环境变量配置 - 便于部署和管理

## 架构说明

本项目包含以下核心组件：

- **Dockerfile** - 基于官方 Memos 镜像 (`neosmemo/memos:stable`) 构建，集成了 rclone 和 inotify-tools
- **entrypoint.sh** - 容器启动脚本，负责初始化 rclone 配置并启动备份监控
- **backup.sh** - 备份脚本，通过 rclone 将数据同步到远程存储
- **filter_script.py** - Git 提交过滤脚本（用于维护目的）

## 快速开始

### 环境变量配置

在部署前需要配置以下环境变量：

- `RCLONE_CONF_BASE64` - Base64 编码的 rclone 配置文件内容
- `RCLONE_REMOTE_PATH` - 远程备份路径（格式如：`remote_name:path/to/backup`）

### Docker 部署

```bash
# 构建镜像
docker build -t memos-webdav .

# 运行容器
docker run -d \
  --name memos-webdav \
  -p 5230:5230 \
  -v memos-data:/var/opt/memos \
  -e RCLONE_CONF_BASE64="your_base64_encoded_config" \
  -e RCLONE_REMOTE_PATH="your_remote_path" \
  memos-webdav
```

## 备份说明

- 备份会在检测到 `/var/opt/memos` 目录中的文件变更后 10 秒触发
- 使用 `rclone sync` 命令同步数据，确保远程存储与本地数据一致
- 支持 rclone 的加密功能，数据在传输前会被加密

## Rclone 配置

您需要创建一个包含 WebDAV 或其他存储服务配置的 rclone.conf 文件，然后将其转换为 Base64 编码：

```bash
# 1. 编辑配置文件
vim rclone.conf

# 2. 转换为 Base64 编码
base64 -w 0 rclone.conf
```

## 工作流

项目包含一个 GitHub Actions 工作流，当推送到 `main` 分支时自动构建并推送到 GitHub Container Registry。

## 许可证

本项目使用 MIT 许可证，与原始 Memos 项目保持一致。

## 免责声明

- 这是一个第三方增强版本，与官方 Memos 团队无关
- 使用本版本产生的任何后果由用户自行承担
- 建议在使用前充分测试备份功能的可靠性