# Frappe CRM 离线优化迁移总结

## 概述

本次修改将 Frappe CRM 从"运行时下载代码"模式改造为"预构建离线镜像"模式，使其能够在离线环境中快速部署和启动。

## 迁移历史

- **初始迁移**: 2025-11-09 - 从 Docker Compose 迁移到 LZC
- **离线优化**: 2025-11-09 - 改造为预构建镜像模式

## 核心改动

### 1. 新增自定义 Dockerfile ([content/Dockerfile](content/Dockerfile))

**目的**: 在构建阶段预先下载和编译所有依赖，避免运行时网络请求。

**主要步骤**:
- 基于 `frappe/bench:latest` 官方镜像
- 预先初始化 bench 环境（`bench init`）
- 配置连接容器化的数据库和 Redis 服务
- 预先下载 CRM 应用代码（`bench get-app crm`）
- 预先构建前端资源（`yarn install` + `bench build`）
- 移除 Procfile 中的 redis 和 watch 进程

**优势**:
- ✅ 所有代码在镜像中，无需运行时 git clone
- ✅ 所有依赖已安装，无需运行时 pip install 和 yarn install
- ✅ 前端资源已编译，启动更快
- ✅ 适合离线环境部署

### 2. 重构初始化脚本 ([content/init.sh](content/init.sh))

**原有逻辑**:
```bash
检查 /home/frappe/frappe-bench 是否存在
  ↓ 不存在
下载代码 → 初始化环境 → 创建站点 → 启动服务
```

**新逻辑**:
```bash
检查持久化目录 /lzcapp/var/frappe-bench/sites/crm.localhost 是否存在
  ↓ 不存在
从镜像复制预构建内容到持久化目录
  ↓
创建站点（仅首次）→ 启动服务
```

**关键优化**:
- 使用 `cp -a` 从镜像内的 `/home/frappe/frappe-bench` 复制到 `/lzcapp/var/frappe-bench`
- 只在首次启动时创建站点和数据库
- 后续启动直接使用已有站点配置
- 添加数据库就绪检查，避免连接失败

### 3. 更新构建配置 ([lzc-build.yml](lzc-build.yml))

**原构建脚本**:
```bash
chmod +x ./content/init.sh
```

**新构建脚本**:
```bash
cd ./content
docker build -t frappe-crm-offline:latest .
chmod +x ./init.sh
```

**改进**:
- 在打包阶段就构建自定义镜像
- 镜像标签为 `frappe-crm-offline:latest`
- 确保脚本可执行权限

### 4. 更新服务配置 ([lzc-manifest.yml](lzc-manifest.yml))

**主要变更**:

```yaml
# 原配置
frappe-crm:
  image: frappe/bench:latest
  command: bash /lzcapp/pkg/content/init.sh

# 新配置
frappe-crm:
  image: frappe-crm-offline:latest
  command: bash /home/frappe/init.sh
```

**原因**:
- 使用预构建的镜像替代官方镜像
- init.sh 脚本现在在镜像内部（`/home/frappe/init.sh`）
- 持久化存储仍然使用 `/lzcapp/var/frappe-bench`

## 启动流程对比

### 原流程（在线模式）
1. 启动容器（官方镜像）
2. 执行 init.sh
3. **git clone frappe** ⏱️ ~2 分钟
4. **pip install 依赖** ⏱️ ~3 分钟
5. **yarn install 前端依赖** ⏱️ ~1 分钟
6. **bench build 构建资源** ⏱️ ~2 分钟
7. **git clone crm** ⏱️ ~1 分钟
8. 创建站点并初始化数据库 ⏱️ ~2 分钟
9. 启动服务

**总耗时**: 首次 ~11+ 分钟

### 新流程（离线模式）
1. 启动容器（预构建镜像）
2. 执行 init.sh
3. **复制预构建内容到持久化存储** ⏱️ ~30 秒
4. 创建站点并初始化数据库 ⏱️ ~2 分钟（仅首次）
5. 启动服务

**总耗时**:
- 首次 ~3 分钟
- 后续 ~10 秒（跳过站点创建）

## 构建与部署

### 构建镜像

```bash
# 在项目根目录执行
make build

# 或手动构建
cd content
docker build -t frappe-crm-offline:latest .
```

### 验证镜像

```bash
# 检查镜像是否包含预构建内容
docker run --rm frappe-crm-offline:latest ls -la /home/frappe/frappe-bench/apps

# 应该能看到:
# - frappe (Frappe Framework)
# - crm (CRM 应用)
```

### 部署

```bash
# 使用 LZC 工具链打包和部署
make lpk    # 构建 LPK 包
make deploy # 部署到 LZC 平台
```

## 持久化存储说明

### 数据目录结构

```
/lzcapp/var/
├── frappe-bench/          # Frappe bench 工作目录（从镜像复制）
│   ├── apps/              # 应用代码（frappe + crm）
│   ├── sites/             # 站点配置和数据
│   │   └── crm.localhost/ # 默认站点
│   ├── env/               # Python 虚拟环境
│   └── ...
└── mysql/                 # MariaDB 数据目录
```

### 首次启动流程

1. 检查 `/lzcapp/var/frappe-bench/sites/crm.localhost/site_config.json` 是否存在
2. 如不存在，从 `/home/frappe/frappe-bench` 复制全部内容到 `/lzcapp/var/frappe-bench`
3. 创建新站点 `crm.localhost`
4. 安装 CRM 应用到站点
5. 启动服务

### 后续启动流程

1. 检测到站点配置已存在
2. 直接切换到 `/lzcapp/var/frappe-bench` 并启动服务

## 离线使用优势

✅ **无需网络连接**: 所有代码和依赖已打包在镜像中
✅ **快速启动**: 跳过下载和编译步骤，启动时间减少 70%+
✅ **版本锁定**: 镜像固化特定版本，确保环境一致性
✅ **易于分发**: 单一镜像文件包含完整应用栈
✅ **适合内网部署**: 无需配置代理或镜像源

## 注意事项

1. **镜像大小**: 预构建镜像约 2-3 GB（包含 Python 环境、Node.js 依赖、前端资源）
2. **版本更新**: 需要重新构建镜像以获取最新代码
3. **首次站点创建**: 仍需数据库连接，确保 MariaDB 服务正常
4. **磁盘空间**: 持久化目录需要至少 5 GB 空间

## 测试建议

### 测试离线能力

```bash
# 构建镜像后，断开网络
sudo ifconfig en0 down  # macOS
# 或
sudo ip link set eth0 down  # Linux

# 启动容器，验证能否正常初始化
make deploy
```

### 验证启动速度

```bash
# 清空持久化目录
rm -rf /lzcapp/var/frappe-bench

# 计时启动
time make deploy
```

## 回滚方案

如需回退到原在线模式:

1. 恢复 [lzc-manifest.yml](lzc-manifest.yml) 使用 `image: frappe/bench:latest`
2. 恢复原 [init.sh](content/init.sh) 脚本（包含 git clone 步骤）
3. 更新 [lzc-build.yml](lzc-build.yml) 移除 docker build 步骤

## 未来改进

- [ ] 多阶段构建进一步减小镜像体积
- [ ] 缓存 Python 和 Node.js 包层，加快重复构建
- [ ] 支持自定义 Frappe/CRM 版本参数
- [ ] 添加健康检查脚本验证镜像完整性
- [ ] 集成自动化测试验证离线部署

## 相关文件

- [content/Dockerfile](content/Dockerfile) - 自定义镜像构建文件
- [content/init.sh](content/init.sh) - 优化后的启动脚本
- [lzc-build.yml](lzc-build.yml) - LZC 构建配置
- [lzc-manifest.yml](lzc-manifest.yml) - LZC 服务清单

---

**修改完成时间**: 2025-11-09
**改进类型**: 离线优化、启动加速
