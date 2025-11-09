# Frappe CRM - LZC 应用包

这是 Frappe CRM 的 LazyCAT 云服务(LZC)应用包实现。

## 项目简介

Frappe CRM 是一个功能完整的开源 CRM 系统，基于 Frappe Framework 构建。本项目将 Frappe CRM 打包为 LZC 应用，使其可以在懒猫微服上一键部署运行。

## 技术架构

### 服务组件

1. **Frappe 主应用** (`app`)
   - 镜像: `frappe/bench:latest`
   - 端口: 8000 (Web 界面)
   - 持久化: `/lzcapp/var/frappe-bench`

2. **MariaDB 数据库** (`mariadb`)
   - 镜像: `mariadb:10.8`
   - 持久化: `/lzcapp/var/mysql`
   - Root 密码: `123` (开发环境)

3. **Redis 缓存** (`redis`)
   - 镜像: `redis:alpine`
   - 用途: 缓存、队列、Socket.IO

### 初始化流程

首次启动时，`init.sh` 脚本会自动执行以下操作：

1. 初始化 Frappe Bench (version-15)
2. 配置数据库和 Redis 连接
3. 下载并安装 CRM 应用
4. 创建默认站点 `crm.localhost`
5. 配置开发者模式
6. 启动所有服务

默认管理员账号:
- 用户名: `Administrator`
- 密码: `admin`

### 语言支持

本应用**默认使用中文界面**：
- 自动配置中文为默认语言 (`language: zh`)
- 内置完整的中文翻译包 (`crm/locale/zh.po`)
- 支持 20+ 种语言切换

**⚠️ 首次访问提示**：
- 如果登录后界面显示英文，请**清除浏览器 Cookie** (Ctrl+Shift+Delete)
- 重新登录后即可看到中文界面

详细说明：
- [content/README-CHINESE.md](content/README-CHINESE.md) - 中文配置说明
- [LANGUAGE-SUPPORT.md](LANGUAGE-SUPPORT.md) - 多语言支持文档

## 快速开始

### 前置要求

- 已安装 lzc-cli: `npm install -g @lazycatcloud/lzc-cli`
- 已配置懒猫微服连接
- Git 和 Make

### 构建 LPK 包

```bash
# 方式 1: 使用 Make
make lpk

# 方式 2: 直接使用 lzc-cli
lzc-cli project build
```

### 安装到懒猫微服

```bash
# 方式 1: 使用 Make
make deploy

# 方式 2: 手动安装
lzc-cli app install ./cloud.lazycat.app.frappe-crm-*.lpk
```

### 访问应用

安装完成后，访问：
- URL: `https://frappe-crm.<你的微服域名>`
- 用户名: `Administrator`
- 密码: `admin`

## 开发指南

### 本地开发环境

```bash
# 启动开发环境
lzc-cli project devshell

# 在 devshell 中访问
http://localhost:8000
```

### 查看日志

```bash
# 查看主应用日志
lzc-cli app logs cloud.lazycat.app.frappe-crm

# 查看数据库日志
lzc-cli app logs cloud.lazycat.app.frappe-crm --service mariadb

# 查看 Redis 日志
lzc-cli app logs cloud.lazycat.app.frappe-crm --service redis
```

### 卸载应用

```bash
# 卸载但保留数据
make uninstall

# 卸载并删除所有数据
make uninstall-clean
```

## 文件结构

```
frappe-crm/
├── lzc-manifest.yml      # LZC 应用配置文件
├── lzc-build.yml         # LZC 构建配置文件
├── content/              # 打包内容目录
│   └── init.sh          # Frappe 初始化脚本
├── icon.png             # 应用图标
├── Makefile             # Make 构建脚本
├── base.mk              # 公共 Make 配置
└── README-LZC.md        # 本文件
```

## 配置说明

### 修改数据库密码

生产环境建议修改数据库密码：

1. 修改 `lzc-manifest.yml` 中的 `MYSQL_ROOT_PASSWORD`
2. 修改 `content/init.sh` 中的 `--mariadb-root-password`
3. 重新构建 LPK 包

### 修改管理员密码

修改 `content/init.sh` 中的 `--admin-password` 参数。

### 资源限制

可以在 `lzc-manifest.yml` 中调整资源限制：

```yaml
services:
  mariadb:
    mem_limit: 1G        # MariaDB 内存限制
    cpus: 1.0            # CPU 核心数

  redis:
    mem_limit: 256M      # Redis 内存限制
```

## 故障排查

### 应用无法启动

1. 检查服务状态:
   ```bash
   lzc-cli app status cloud.lazycat.app.frappe-crm
   ```

2. 查看启动日志:
   ```bash
   lzc-cli app logs cloud.lazycat.app.frappe-crm
   ```

### 数据库连接失败

确保 MariaDB 服务健康:
```bash
lzc-cli app logs cloud.lazycat.app.frappe-crm --service mariadb
```

### 初始化超时

Frappe 初始化需要较长时间（可能超过 2 分钟），请耐心等待。可以通过日志监控进度。

## 注意事项

1. **首次启动时间**: Frappe 初始化需要下载依赖和创建数据库，首次启动可能需要 5-10 分钟
2. **数据持久化**: 所有数据存储在 `/lzcapp/var` 目录，卸载应用时可选择保留或删除
3. **网络要求**: 初始化时需要从 GitHub 下载 CRM 应用，确保网络连接正常
4. **资源需求**: 建议至少分配 2GB 内存和 10GB 存储空间

## 参考资源

- [Frappe CRM 官方仓库](https://github.com/frappe/crm)
- [Frappe Framework 文档](https://frappeframework.com/docs)
- [LZC 开发者文档](https://docs.lazycat.cloud)

## 许可证

- Frappe CRM: AGPL-3.0
- 本 LZC 适配: MIT

## 贡献

欢迎提交 Issue 和 Pull Request！
