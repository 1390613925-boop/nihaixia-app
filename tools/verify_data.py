#!/usr/bin/env python3
"""Recursively compare arbitrary JSON record structures for data regressions."""

import json
import sys

TRUNC = 40


def trunc(v):
    s = str(v)
    return s if len(s) <= TRUNC else s[:TRUNC] + "…"


def top_level_list(obj):
    if isinstance(obj, list):
        return obj
    if isinstance(obj, dict):
        for v in obj.values():
            if isinstance(v, list) and v and isinstance(v[0], dict):
                return v
        for v in obj.values():
            if isinstance(v, list):
                return v
    raise ValueError("没找到可比较的列表字段，请检查文件顶层结构")


def item_key(item, fallback):
    if isinstance(item, dict):
        return item.get("id") or item.get("name") or fallback
    return fallback


def diff_scalar(label, ov, nv, errors, improvements):
    ov_s = ov.strip() if isinstance(ov, str) else ov
    nv_s = nv.strip() if isinstance(nv, str) else nv
    ov_empty = ov_s in (None, "", [], {})
    nv_empty = nv_s in (None, "", [], {})
    if not ov_empty and nv_empty:
        errors.append(f"[属性丢失] {label} 从「{trunc(ov_s)}」变成了空")
    elif not ov_empty and not nv_empty and ov_s != nv_s:
        errors.append(
            f"[属性被改] {label} 从「{trunc(ov_s)}」改成了「{trunc(nv_s)}」（确认是否有意为之）"
        )
    elif ov_empty and not nv_empty:
        improvements.append(f"[新增] {label} 补上了：「{trunc(nv_s)}」")


def diff_scalar_list(label, ov, nv, errors, improvements):
    old_set = set(map(str, ov or []))
    new_set = set(map(str, nv or []))
    missing = old_set - new_set
    added = new_set - old_set
    if missing:
        errors.append(f"[属性丢失] {label} 少了：{sorted(missing)}")
    if added:
        improvements.append(f"[新增] {label} 多了：{sorted(added)}")


def diff_dict(label, old, new, errors, improvements):
    keys = set(old.keys()) | set(new.keys())
    for k in sorted(keys):
        ov, nv = old.get(k), new.get(k)
        sub = f"{label}.{k}"
        if isinstance(ov, dict) or isinstance(nv, dict):
            diff_dict(sub, ov or {}, nv or {}, errors, improvements)
        elif isinstance(ov, list) or isinstance(nv, list):
            sample = (ov or nv or [None])[0]
            if isinstance(sample, dict):
                diff_list_of_dicts(sub, ov or [], nv or [], errors, improvements)
            else:
                diff_scalar_list(sub, ov or [], nv or [], errors, improvements)
        else:
            diff_scalar(sub, ov, nv, errors, improvements)


def diff_list_of_dicts(label, old_list, new_list, errors, improvements):
    old_idx = {item_key(it, f"#{i}"): it for i, it in enumerate(old_list)}
    new_idx = {item_key(it, f"#{i}"): it for i, it in enumerate(new_list)}
    for k, ov in old_idx.items():
        if k not in new_idx:
            errors.append(f"[条目丢失] {label} 里的「{k}」在新版本里消失")
            continue
        diff_dict(f"{label}[{k}]", ov, new_idx[k], errors, improvements)
    for k in new_idx:
        if k not in old_idx:
            improvements.append(f"[新增条目] {label} 新增了「{k}」")


def main(old_path, new_path):
    old_raw = json.load(open(old_path, encoding="utf-8"))
    new_raw = json.load(open(new_path, encoding="utf-8"))
    errors, improvements = [], []

    # Compare the complete JSON root so metadata and dict-only roots (for example
    # formula_oral_hints.json) are covered as well as list-based datasets.
    if isinstance(old_raw, dict) and isinstance(new_raw, dict):
        diff_dict("记录", old_raw, new_raw, errors, improvements)
    elif isinstance(old_raw, list) and isinstance(new_raw, list):
        sample = (old_raw or new_raw or [None])[0]
        if isinstance(sample, dict):
            diff_list_of_dicts("记录", old_raw, new_raw, errors, improvements)
        else:
            diff_scalar_list("记录", old_raw, new_raw, errors, improvements)
    else:
        diff_scalar("记录", old_raw, new_raw, errors, improvements)

    def record_count(raw):
        if isinstance(raw, list):
            return len(raw)
        if isinstance(raw, dict):
            for value in raw.values():
                if isinstance(value, list):
                    return len(value)
            return len(raw)
        return 1

    old_count = record_count(old_raw)
    new_count = record_count(new_raw)

    print(f"=== 数据对比：{old_path}  ->  {new_path} ===")
    print(f"记录总数：旧版 {old_count} / 新版 {new_count}")
    print(f"问题 {len(errors)} 处；新增/改进 {len(improvements)} 处\n")

    if errors:
        print("--- 需要人工核查的问题 ---")
        for error in errors:
            print(" -", error)
    else:
        print("没有发现任何字段被清空、条目丢失。")

    if improvements:
        print("\n--- 新增/改进（信息性） ---")
        for improvement in improvements:
            print(" -", improvement)

    return 1 if errors else 0


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))
