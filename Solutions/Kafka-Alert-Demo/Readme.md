# 方案设计概述

以下是基于 Kafka 和 Python 实现的告警系统方案，其中 Kafka 集群用于接收告警消息，消费者处理消息并根据需求去重或直接发送邮件通知。

- Kafka 集群：作为消息的推送和消费端点。
- 生产者：模拟告警消息写入 Kafka 的 alarm_topic。
- 消费者：从 Kafka 消费告警消息，执行去重逻辑（基于 Redis），然后发送邮件。
- 邮件通知：通过 SMTP 发送告警邮件。

# 环境需求

- Kafka 集群 (至少 1 个 broker)
- Python (3.x)
- Kafka-Python 库
- Redis (可选，用于去重)
- smtplib (Python 标准库)

# Install

apt install python3-pip python3.12-venv -y

# Create a virtual environment
python3 -m venv kafka-env

# Activate the virtual environment
source kafka-env/bin/activate
pip install kafka-python-ng
