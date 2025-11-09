#!/bin/bash
# Frappe CRM 初始化脚本（离线优化版本）
# 使用预构建的镜像，跳过代码下载和编译步骤

set -e

# 切换到 frappe 用户的 home 目录
cd /home/frappe

# 数据持久化目录 (挂载在 /lzcapp/var/frappe-bench)
PERSISTENT_BENCH="${DATA_DIR}/frappe-bench"
TEMPLATE_BENCH="/home/frappe/frappe-bench"

# 检查持久化目录是否已经包含完整的 bench 环境
if [ -f "$PERSISTENT_BENCH/sites/crm.localhost/site_config.json" ]; then
    echo "Site already initialized, starting services..."
    cd "$PERSISTENT_BENCH"
    bench start
    exit 0
fi

echo "First-time initialization from pre-built image..."

# 如果持久化目录不存在或为空，从镜像中复制预构建的内容
if [ ! -d "$PERSISTENT_BENCH/apps/frappe" ]; then
    echo "Copying pre-built bench to persistent storage..."

    # 确保目标目录存在
    mkdir -p "$PERSISTENT_BENCH"

    # 复制预构建的 bench 环境到持久化存储
    # 注意：这里使用 cp -a 保留所有属性和权限
    cp -a "$TEMPLATE_BENCH/"* "$PERSISTENT_BENCH/" || {
        echo "Failed to copy bench files"
        exit 1
    }

    echo "Bench files copied successfully"
fi

# 切换到持久化的 bench 目录
cd "$PERSISTENT_BENCH"

# 检查站点是否存在
if [ ! -d "sites/crm.localhost" ]; then
    echo "Creating new site..."

    # 等待数据库服务就绪
    echo "Waiting for database..."
    for i in {1..30}; do
        if mariadb-admin ping -h mariadb -u root -p123 &>/dev/null; then
            echo "Database is ready!"
            break
        fi
        echo "Waiting for database... ($i/30)"
        sleep 2
    done

    # 验证全局语言配置（应该已经在镜像中设置好了）
    echo "Verifying global language configuration..."
    if [ -f "sites/common_site_config.json" ]; then
        echo "Global config exists, checking language setting..."
        cat sites/common_site_config.json
    fi

    # 创建新站点
    bench new-site crm.localhost \
        --force \
        --mariadb-root-password 123 \
        --admin-password admin \
        --no-mariadb-socket

    # 安装 CRM 应用
    echo "Installing CRM app..."
    bench --site crm.localhost install-app crm

    # 设置默认站点（必须在配置前设置）
    bench use crm.localhost

    # 配置开发模式和中文语言
    echo "Configuring site..."

    # 直接编辑 site_config.json 文件来设置配置
    cd sites/crm.localhost

    # 使用 Python 修改配置文件
    python3 << 'EOF'
import json
import os

config_file = 'site_config.json'
if os.path.exists(config_file):
    with open(config_file, 'r') as f:
        config = json.load(f)
else:
    config = {}

# 设置配置项
config['developer_mode'] = 1
config['mute_emails'] = 1
config['server_script_enabled'] = 1
config['language'] = 'zh'

# 保存配置
with open(config_file, 'w') as f:
    json.dump(config, f, indent=1)

print("Configuration updated successfully")
EOF

    # 返回 bench 目录
    cd ../..

    # 清除缓存
    bench --site crm.localhost clear-cache

    # 设置 Administrator 用户的语言为中文
    echo "Setting Administrator user language to Chinese..."
    bench --site crm.localhost console << 'PYTHON_EOF'
import frappe
frappe.connect()

# 获取 Administrator 用户
user = frappe.get_doc('User', 'Administrator')

# 设置语言为中文
user.language = 'zh'
user.save(ignore_permissions=True)

frappe.db.commit()

print("✅ Administrator 用户语言已设置为中文")
PYTHON_EOF

    echo "Site created successfully!"
fi

echo "Starting Frappe CRM..."

# 启动服务
bench start
