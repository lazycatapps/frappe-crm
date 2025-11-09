#!/usr/bin/env python3
"""设置 Frappe CRM 默认语言为中文"""

import json
import os

def set_language(config_file, language='zh'):
    """设置语言配置"""
    if os.path.exists(config_file):
        with open(config_file, 'r') as f:
            config = json.load(f)
    else:
        config = {}

    # 设置语言
    config['language'] = language

    # 保存配置
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=1)

    print(f"Language set to '{language}' in {config_file}")

if __name__ == '__main__':
    # 设置全局配置
    set_language('sites/common_site_config.json', 'zh')
