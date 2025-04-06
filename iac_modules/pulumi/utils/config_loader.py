import os
import glob
import yaml
from collections.abc import Mapping

def deep_merge(dict1, dict2):
    result = dict1.copy()
    for k, v in dict2.items():
        if k in result and isinstance(result[k], dict) and isinstance(v, Mapping):
            result[k] = deep_merge(result[k], v)
        elif k in result and isinstance(result[k], list) and isinstance(v, list):
            result[k] += v
        else:
            result[k] = v
    return result

def load_merged_config(config_dir=None, ignore_files=None):
    config_dir = config_dir or os.environ.get("CONFIG_PATH", "config")
    ignore_files = set(ignore_files or ['vpn-keys.yaml'])  # 默认忽略敏感 key 文件

    if not os.path.isdir(config_dir):
        raise FileNotFoundError(f"❌ 配置目录不存在: {config_dir}")

    merged = {}
    files = sorted(
        glob.glob(os.path.join(config_dir, "*.yaml")) + glob.glob(os.path.join(config_dir, "*.yml"))
    )

    if not files:
        raise FileNotFoundError(f"⚠️ 未找到任何 YAML 配置文件于: {config_dir}")

    for file in files:
        filename = os.path.basename(file)
        if filename in ignore_files:
            continue

        with open(file) as f:
            part = yaml.safe_load(f) or {}
            merged = deep_merge(merged, part)

    merged["__config_path__"] = config_dir
    return merged
