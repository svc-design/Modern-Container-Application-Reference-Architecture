from kafka import KafkaConsumer
import json
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# 配置日志
logging.basicConfig(level=logging.INFO)

# Kafka 配置
KAFKA_SERVER = '10.43.16.127:9092'
ALARM_TOPIC = 'your_topic_name'
KAFKA_GROUP_ID = 'your_consumer_group'  # 消费者组 ID

# 邮件配置
SMTP_SERVER = 'smtp.qq.com'
SMTP_PORT = 465  # 465端口支持SSL加密
EMAIL_ADDRESS = 'manbuzhe2009@qq.com'
EMAIL_PASSWORD = 'xxxxxxxxxxxxxxxxxx'  # QQ授权码
RECIPIENT_EMAIL = '156405189@qq.com'

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

# 消费 Kafka 消息并发送邮件
def consume_messages_and_send_email(consumer):
    """
    消费 Kafka 消息并发送邮件，每接收到一条新消息，就发送邮件。
    """
    for message in consumer:
        try:
            # 打印日志，显示接收到的消息
            logging.info(f"Consumed message: {message.value}")

            # 构建邮件主题和正文
            subject = f"Kafka Alert - New message at offset {message.offset}"
            body = (
                f"A new message was received in topic '{ALARM_TOPIC}' "
                f"at offset {message.offset}.\n\n"
                f"Message Content:\n{json.dumps(message.value, indent=2)}"
            )

            # 发送邮件
            send_email(subject, body)
        except Exception as e:
            logging.error(f"Error processing message: {e}")



# 发送邮件
def send_email(subject, body):
    try:
        # 设置邮件内容
        msg = MIMEMultipart()
        msg['From'] = EMAIL_ADDRESS
        msg['To'] = RECIPIENT_EMAIL
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        # 连接 SMTP 服务器并发送邮件
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.sendmail(EMAIL_ADDRESS, RECIPIENT_EMAIL, msg.as_string())

        logging.info(f"Email sent to {RECIPIENT_EMAIL}")
    except Exception as e:
        logging.error(f"Failed to send email: {e}")

# 主函数
def main():
    # 创建 Kafka 消费者
    consumer = create_kafka_consumer()
    # 开始消费 Kafka 消息并发送邮件
    consume_messages_and_send_email(consumer)

# 启动应用
if __name__ == "__main__":
    main()
