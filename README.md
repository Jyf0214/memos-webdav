# Memos-WebDAV 增强版

> **注意：这不是官方的 Memos 版本，而是第三方开发的增强版本，集成了自动备份功能。**

这是一个基于官方 Memos 项目的第三方增强版本，添加了 WebDAV 自动备份功能。该版本通过 Docker 容器化部署，支持将 Memos 数据自动备份到 WebDAV 或其他支持的远程存储服务。

## 功能特性

- 基于官方 Memos (`neosmemo/memos:stable`) 的完整功能
- 自动备份到 WebDAV 或其他 rclone 支持的存储服务
- 文件系统监控 - 当数据发生变更时自动触发备份
- Rclone 加密支持 - 数据在传输前进行加密
- 环境变量配置 - 便于部署和管理
- **伪装日志 (Hugging Face Spaces)**: 当应用部署在 Hugging Face Spaces 时，成功的备份日志会显示为伪装的系统或AI模型日志。此功能默认开启，可通过设置 `DEBUG` 环境变量禁用。

## 架构说明

本项目包含以下核心组件：

- **Dockerfile** - 基于官方 Memos 镜像 (`neosmemo/memos:stable`) 构建，集成了 rclone 和 inotify-tools
- **entrypoint.sh** - 容器启动脚本，负责初始化 rclone 配置并启动备份监控
- **backup.sh** - 备份脚本，通过 rclone 将数据同步到远程存储
- **filter_script.py** - Git 提交过滤脚本（用于维护目的）

## 快速开始

### 环境变量配置

在部署前需要配置以下环境变量：

- `RCLONE_CONF_BASE64`: **必需**。Base64 编码的 rclone 配置文件内容。
- `RCLONE_REMOTE_PATH`: 可选。远程备份路径（格式如：`remote_name:path/to/backup`）。此路径也用于在容器首次启动且数据目录为空时恢复数据。默认为 `memos_data:memos_backup`。
- `TUNNEL_TOKEN`: 可选。从 Cloudflare Zero Trust 获取的 Tunnel 令牌。提供此令牌后，容器将自动为您创建一个到 Memos 服务的公共访问隧道。
- `DEBUG`: 可选。设置为任意值 (例如 `true`) 可禁用伪装日志，并显示详细的 `rclone` 备份过程，方便调试。
- `SPACE_ID`: 由 Hugging Face 自动提供。此环境变量用于检测是否在 HF Space 环境中运行，以激活伪装日志功能。

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
  -e TUNNEL_TOKEN="your_cloudflare_tunnel_token" \
  memos-webdav
```

## 内网穿透 (Cloudflare Tunnel)

本项目集成了 `cloudflared`，可以轻松地将您的 Memos 服务暴露到公网，而无需公网 IP 或复杂的端口转发。

### 如何使用

1.  **获取 Tunnel 令牌**:
    - 登录到您的 [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) 仪表板。
    - 在左侧菜单中，找到并点击 **Access** -> **Tunnels**。
    - 点击 **Create a tunnel**，类型选择 **Cloudflared**。
    - 为您的 Tunnel 命名（例如 `memos-tunnel`）并保存。
    - 在下一个页面，复制您的 Tunnel 令牌（`--token` 后面的长字符串）。

2.  **配置公共主机名**:
    - 创建 Tunnel 后，在 Tunnel 列表中找到您刚创建的 Tunnel，点击 **Configure**。
    - 选择 **Public Hostname** 标签页，然后点击 **Add a public hostname**。
    - **Subdomain**: 输入您想要的子域名（例如 `memos`）。
    - **Domain**: 选择您在 Cloudflare 托管的域名。
    - **Service**: Type 选择 `HTTP`，URL 填入 `localhost:5230`。
    - 点击 **Save hostname**。

3.  **启动容器**:
    - 在 `docker run` 命令中，通过 `-e TUNNEL_TOKEN="<您的令牌>"` 传入您的令牌。
    - 容器启动后，`cloudflared` 会自动在后台运行，并将您配置的域名指向 Memos 服务。

## 备份说明

- 备份会在检测到 `/var/opt/memos` 目录中的文件变更后 10 秒触发
- 使用 `rclone sync` 命令同步数据，确保远程存储与本地数据一致
- 支持 rclone 的加密功能，数据在传输前会被加密

## 存储后端支持

本容器使用 `rclone` 作为核心备份工具，因此理论上支持 `rclone` 支持的所有存储后端。以下是一些常见后端的配置示例。

### S3 兼容存储 (例如 AWS S3, MinIO)

要备份到 S3 或其他 S3 兼容的对象存储，您需要在 `rclone.conf` 文件中配置一个 S3 remote。

1.  **创建 `rclone.conf` 文件**:
    下面是一个连接到 AWS S3 的示例配置。对于 MinIO 或其他提供商，请相应修改 `provider`, `endpoint` 等字段。

    ```ini
    [my-s3-remote]
    type = s3
    provider = AWS
    # 建议使用 IAM 角色或 EC2 实例配置文件，因此 env_auth = true
    # 如果使用 access_key_id 和 secret_access_key，请设置 env_auth = false
    env_auth = true 
    region = us-east-1
    ```

2.  **配置环境变量**:
    - 将上述 `rclone.conf` 文件内容进行 Base64 编码，并设置为 `RCLONE_CONF_BASE64` 环境变量的值。
    - 将 `RCLONE_REMOTE_PATH` 设置为您的 S3 remote 名称和路径，例如 `my-s3-remote:my-memos-bucket/backups`。

### WebDAV

1.  **创建 `rclone.conf` 文件**:
    ```ini
    [my-webdav-remote]
    type = webdav
    url = https://webdav.example.com
    vendor = other
    user = your_username
    pass = your_encrypted_password 
    ```
    *注意*: 推荐使用 `rclone config` 命令创建配置，它会自动加密密码。

2.  **配置环境变量**:
    - 将 `rclone.conf` 文件内容进行 Base64 编码，并设置为 `RCLONE_CONF_BASE64`。
    - 将 `RCLONE_REMOTE_PATH` 设置为 `my-webdav-remote:path/to/backup`。

> 更多关于 `rclone` 的配置信息，请参考 [rclone 官方文档](https://rclone.org/docs/)。

## 工作流

项目包含一个 GitHub Actions 工作流，当推送到 `main` 分支时自动构建并推送到 GitHub Container Registry。

## 许可证

本项目使用 MIT 许可证，与原始 Memos 项目保持一致。

## 免责声明

- 这是一个第三方增强版本，与官方 Memos 团队无关
- 使用本版本产生的任何后果由用户自行承担
- 建议在使用前充分测试备份功能的可靠性
