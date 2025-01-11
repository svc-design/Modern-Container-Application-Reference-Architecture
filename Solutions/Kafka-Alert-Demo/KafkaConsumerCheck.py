from kafka import KafkaConsumer
import json
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)

# Kafka 配置
KAFKA_SERVER = '10.43.16.127:9092'
ALARM_TOPIC = 'your_topic_name'
KAFKA_GROUP_ID = 'your_consumer_group'  # 消费者组 ID

# Kafka Consumer 配置
def create_kafka_consumer():
    return KafkaConsumer(
        ALARM_TOPIC,  # 订阅的 Kafka topic
        bootstrap_servers=KAFKA_SERVER,  # Kafka 集群地址
        group_id=KAFKA_GROUP_ID,  # 消费者组 ID
        value_deserializer=lambda x: json.loads(x.decode('utf-8')),  # 反序列化消息
        sasl_mechanism='PLAIN',  # SASL 认证机制
        sasl_plain_username='user1',  # Kafka 认证用户名
        sasl_plain_password='test',  # Kafka 认证密码
        security_protocol='SASL_PLAINTEXT',  # 安全协议
        auto_offset_reset='earliest'  # 从最早的消息开始消费
    )

# 消费 Kafka 消息并打印
def consume_messages(consumer):
    """
    消费 Kafka 消息并打印，每接收到一条新消息，就打印到日志。
    """
    for message in consumer:
        try:
            # 打印日志，显示接收到的消息
            logging.info(f"Consumed message: {message.value}")
        except Exception as e:
            logging.error(f"Error processing message: {e}")

# 主函数
def main():
    # 创建 Kafka 消费者
    consumer = create_kafka_consumer()
    # 开始消费 Kafka 消息并打印
    consume_messages(consumer)

# 启动应用
if __name__ == "__main__":
    main()
