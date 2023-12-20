#!/bin/bash

# 设置 ~/.ssh/ 目录的权限
sudo chmod 700 ~/.ssh

# 设置 ~/.ssh/authorized_keys 文件的权限
sudo chmod 600 ~/.ssh/authorized_keys

# 使用 chattr +i 确保 authorized_keys 文件不能被删除
sudo chattr +i ~/.ssh/authorized_keys || true

