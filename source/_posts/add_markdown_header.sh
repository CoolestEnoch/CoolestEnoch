#!/bin/bash

# 提示用户输入 y 来继续
read -p "此操作无法撤销, 如果你要继续, 输入 'y' 继续执行脚本: " input

# 判断输入是否为 'y'
if [[ "$input" != "y" ]]; then
  echo "Abort."
  exit 1
fi


# 查找所有符合要求的日记文件并处理特殊字符
find . -type f -regextype posix-extended -regex '.*/[0-9]{4}-[0-9]{2}-[0-9]{2}\.md' -print0 | while IFS= read -r -d '' file; do
    # 提取基础文件名
    filename=$(basename "$file" .md)
    
    # 分解日期成分
    IFS='-'
    read -r year month day <<< "$filename"
    unset IFS

    # 创建frontmatter内容
    title="${year}年${month}月${day}日"
    date_str="${year}-${month}-${day} 18:00:00"
    frontmatter="---
title: ${title}
date: ${date_str}
tags:
---
"

    # 检查是否已存在frontmatter
    if [ "$(head -n 1 "$file" 2>/dev/null)" = "---" ]; then
        echo "跳过 $file (已存在frontmatter)"
        continue
    fi

    # 创建临时文件并写入内容
    tmpfile=$(mktemp)
    echo "$frontmatter" > "$tmpfile"
    cat "$file" >> "$tmpfile"
    mv "$tmpfile" "$file"
    
    echo "已为 $file 添加frontmatter"
done