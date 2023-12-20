#!/bin/bash
# 遍历输出行并设置 GitHub Actions 输出变量

terraform_output=`terraform output`

# Loop through output lines and set GitHub Actions output variables
printf "%s" "$terraform_output" | while IFS= read -r line; do
    key=$(printf "%s" "$line" | awk -F= '{print $1}')
    value=$(printf "%s" "$line" | awk -F= '{print $2}')
    printf "%s\n" "$key=$value" >> "$GITHUB_OUTPUT"
done
