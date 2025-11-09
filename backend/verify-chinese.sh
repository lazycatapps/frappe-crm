#!/bin/bash
# 验证中文语言配置脚本

echo "================================"
echo "Frappe CRM 中文配置验证"
echo "================================"
echo ""

# 检查全局配置
echo "1. 检查全局配置 (common_site_config.json):"
if [ -f "/home/frappe/frappe-bench/sites/common_site_config.json" ]; then
    cat /home/frappe/frappe-bench/sites/common_site_config.json
    echo ""

    # 检查是否包含中文配置
    if grep -q '"language": "zh"' /home/frappe/frappe-bench/sites/common_site_config.json; then
        echo "✅ 全局语言已设置为中文"
    else
        echo "❌ 全局语言未设置为中文"
    fi
else
    echo "❌ 全局配置文件不存在"
fi

echo ""
echo "2. 检查站点配置 (site_config.json):"
if [ -f "/home/frappe/frappe-bench/sites/crm.localhost/site_config.json" ]; then
    cat /home/frappe/frappe-bench/sites/crm.localhost/site_config.json
    echo ""

    # 检查是否包含中文配置
    if grep -q '"language": "zh"' /home/frappe/frappe-bench/sites/crm.localhost/site_config.json; then
        echo "✅ 站点语言已设置为中文"
    else
        echo "❌ 站点语言未设置为中文"
    fi
else
    echo "❌ 站点配置文件不存在（站点可能尚未创建）"
fi

echo ""
echo "3. 检查中文翻译文件:"
if [ -f "/home/frappe/frappe-bench/apps/crm/crm/locale/zh.po" ]; then
    echo "✅ 中文翻译文件存在"
    echo "   路径: /home/frappe/frappe-bench/apps/crm/crm/locale/zh.po"
    echo "   文件大小: $(du -h /home/frappe/frappe-bench/apps/crm/crm/locale/zh.po | cut -f1)"

    # 显示翻译文件前几行
    echo ""
    echo "   翻译文件信息:"
    head -20 /home/frappe/frappe-bench/apps/crm/crm/locale/zh.po | grep -E "(Project-Id-Version|Language-Team|PO-Revision-Date|Language:)"
else
    echo "❌ 中文翻译文件不存在"
fi

echo ""
echo "================================"
echo "验证完成"
echo "================================"
