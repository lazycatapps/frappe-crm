# Frappe CRM 离线镜像构建
# 基于 frappe/bench 官方镜像,预装所有依赖和代码
FROM frappe/bench:latest

# 设置工作目录
WORKDIR /home/frappe

# 安装构建所需工具
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# 切换回 frappe 用户
USER frappe

# 预先初始化 bench 环境
RUN bench init --skip-redis-config-generation frappe-bench --version version-15

# 进入 bench 目录
WORKDIR /home/frappe/frappe-bench

# 配置使用容器服务
RUN bench set-mariadb-host mariadb && \
    bench set-redis-cache-host redis://redis:6379 && \
    bench set-redis-queue-host redis://redis:6379 && \
    bench set-redis-socketio-host redis://redis:6379

# 从 Procfile 中移除 redis 和 watch 进程
RUN sed -i '/redis/d' ./Procfile && \
    sed -i '/watch/d' ./Procfile

# 获取 CRM 应用
RUN bench get-app crm --branch main

# 复制语言设置脚本
COPY --chown=frappe:frappe set-chinese-lang.py /tmp/set-chinese-lang.py

# 设置全局默认语言为中文（在构建阶段）
RUN python3 /tmp/set-chinese-lang.py && rm /tmp/set-chinese-lang.py

# 构建前端资源
RUN cd /home/frappe/frappe-bench/apps/frappe && \
    yarn install --check-files && \
    bench build --app frappe

# 复制启动脚本和工具脚本
COPY --chown=frappe:frappe init.sh /home/frappe/init.sh
COPY --chown=frappe:frappe verify-chinese.sh /home/frappe/verify-chinese.sh
COPY --chown=frappe:frappe set-user-language.sh /home/frappe/set-user-language.sh

RUN chmod +x /home/frappe/init.sh && \
    chmod +x /home/frappe/verify-chinese.sh && \
    chmod +x /home/frappe/set-user-language.sh

# 设置工作目录
WORKDIR /home/frappe
ENV DATA_DIR=/home/frappe

# 默认启动命令
CMD ["/home/frappe/init.sh"]
