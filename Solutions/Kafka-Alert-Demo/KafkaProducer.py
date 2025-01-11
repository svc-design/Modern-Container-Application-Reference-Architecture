from kafka import KafkaProducer
import json
import logging
import time

# 配置日志
logging.basicConfig(level=logging.INFO)

# Kafka Producer 配置
producer = KafkaProducer(
    bootstrap_servers='10.43.16.127:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    sasl_mechanism='PLAIN',
    sasl_plain_username='user1',
    sasl_plain_password='test',
    security_protocol='SASL_PLAINTEXT',
)

# 目标 topic
topic = 'your_topic_name'

# 循环次数不限制，直到手动停止
attempt = 0

# 模拟持续发送不同消息
while True:
    message = {"key": f"value_{attempt}", "status": "success", "attempt": attempt}
    
    try:
        # 发送消息并等待确认
        future = producer.send(topic, value=message)
        
        # 等待确认并获取结果
        record_metadata = future.get(timeout=10)
        
        # 输出消息成功写入的元数据
        logging.info(f"Message sent to topic {record_metadata.topic} partition {record_metadata.partition} with offset {record_metadata.offset}")

    except Exception as e:
        logging.error(f"Error sending message: {e}")
    
    # 增加尝试次数
    attempt += 1
    
    # 暂停 1 秒钟，确保每次发送的间隔为 1 秒
    time.sleep(1)  # 每次发送后暂停 1 秒钟

# 关闭 Kafka 生产者连接（如果手动停止程序时才会关闭）
producer.close()
