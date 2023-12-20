#!/bin/bash
# 代码本地测试

sudo yum install python3-pip -y || echo true
sudo apt install python3-pip -y || echo true
pip3 install hvac python-hcl2 Jinja2
sudo wget https://mirrors.onwalk.net/tools/linux-amd64/gauth.tar.gz && sudo tar -xvpf gauth.tar.gz -C /usr/local/bin/
sudo chmod 755 /usr/local/bin/gauth
