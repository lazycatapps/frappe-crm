# 中文配置说明

## 概述

本镜像已在**构建阶段**预先配置中文为默认语言，确保离线环境下也能正常使用中文界面。

## 配置方式

### 1. 构建阶段配置（Dockerfile）

在镜像构建时，通过 [set-chinese-lang.py](set-chinese-lang.py) 脚本设置全局语言：

```dockerfile
# 复制语言设置脚本
COPY --chown=frappe:frappe set-chinese-lang.py /tmp/set-chinese-lang.py

# 设置全局默认语言为中文（在构建阶段）
RUN python3 /tmp/set-chinese-lang.py && rm /tmp/set-chinese-lang.py
```

这会修改 `/home/frappe/frappe-bench/sites/common_site_config.json`：
```json
{
  "language": "zh"
}
```

### 2. 运行时配置（init.sh）

在站点创建后，脚本会设置站点级别的语言配置：

```bash
# 修改 site_config.json
config['language'] = 'zh'
```

## 验证配置

### 在容器中验证

```bash
# 运行验证脚本
docker exec -it crm-frappe-1 bash /home/frappe/verify-chinese.sh
```

### 通过界面验证

1. 访问 Frappe CRM 网页 (http://127.0.0.1:8000)
2. 登录后界面应显示中文
3. 菜单、按钮、表单都应该是中文

**首次访问提示**：
- 如果界面仍显示英文，请清除浏览器 Cookie (Ctrl+Shift+Delete)
- 重新登录后即可看到中文界面

## 故障排查

### 问题：界面仍显示英文

**最常见原因：浏览器 Cookie 缓存**

解决方法：
1. 清除浏览器 Cookie (Ctrl+Shift+Delete)
2. 或使用隐私模式/无痕模式访问
3. 重新登录

**如果清除 Cookie 后仍显示英文**：

1. **验证配置**
   ```bash
   docker exec -it crm-frappe-1 bash /home/frappe/verify-chinese.sh
   ```

2. **清除服务器缓存**
   ```bash
   docker exec -it crm-frappe-1 bash -c "cd /home/frappe/frappe-bench && bench --site crm.localhost clear-cache"
   ```

3. **重启容器**
   ```bash
   docker restart crm-frappe-1
   ```

## 文件说明

- [Dockerfile](Dockerfile) - 包含构建阶段的语言配置
- [set-chinese-lang.py](set-chinese-lang.py) - 设置中文语言的 Python 脚本
- [init.sh](init.sh) - 运行时初始化脚本，包含站点级别的语言配置
- [verify-chinese.sh](verify-chinese.sh) - 验证中文配置的脚本

## 配置流程

```
构建镜像
  ↓
执行 set-chinese-lang.py
  ↓
设置 common_site_config.json ["language": "zh"]
  ↓
镜像就绪（包含中文配置）
  ↓
容器启动
  ↓
复制镜像内容到持久化存储
  ↓
创建站点
  ↓
设置站点 site_config.json ["language": "zh"]
  ↓
中文界面生效
```

## 支持的语言

除了中文（zh），还支持：
- en - 英语
- fr - 法语
- de - 德语
- es - 西班牙语
- it - 意大利语
- ja - 日语
- ar - 阿拉伯语
- 等 20+ 种语言

查看所有支持的语言：
```bash
ls /lzcapp/var/frappe-bench/apps/crm/crm/locale/
```

---

**更新时间**: 2025-11-09
**适用版本**: Frappe CRM v15
