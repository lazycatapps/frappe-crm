#!/bin/bash
# 设置 Administrator 用户语言为中文

cd /home/frappe/frappe-bench

echo "正在设置 Administrator 用户语言为中文..."

bench --site crm.localhost console << 'PYTHON_EOF'
import frappe
frappe.connect()

# 获取 Administrator 用户
user = frappe.get_doc('User', 'Administrator')

print(f"当前用户语言: {user.language or '(未设置)'}")

# 设置语言为中文
user.language = 'zh'
user.save(ignore_permissions=True)

frappe.db.commit()

print("✅ Administrator 用户语言已设置为中文")
print("请清除浏览器 Cookie 并重新登录")
PYTHON_EOF

echo ""
echo "完成！请执行以下操作："
echo "1. 清除浏览器 Cookie (Ctrl+Shift+Delete)"
echo "2. 重新登录"
