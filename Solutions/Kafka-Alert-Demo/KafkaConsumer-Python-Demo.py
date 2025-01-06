from kafka import KafkaConsumer
import redis
import json
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Kafka 和 Redis 配置
KAFKA_SERVER = 'localhost:9092'
REDIS_HOST = 'localhost'
REDIS_PORT = 6379
ALARM_TOPIC = 'alarm_topic'

# 邮件配置
SMTP_SERVER = 'smtp.example.com'
SMTP_PORT = 587
EMAIL_ADDRESS = 'alert@example.com'
EMAIL_PASSWORD = 'your_password'
RECIPIENT_EMAIL = 'recipient@example.com'

# 初始化 Kafka 消费者和 Redis 客户端
consumer = KafkaConsumer(ALARM_TOPIC, bootstrap_servers=KAFKA_SERVER)
redis_client = redis.StrictRedis(host=REDIS_HOST, port=REDIS_PORT, db=0)

# 邮件发送函数
def send_email(alarm):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = RECIPIENT_EMAIL
    msg['Subject'] = f"Alarm Notification - {alarm['level']}"
    body = f"""
    Alarm ID: {alarm['alarm_id']}
    Level: {alarm['level']}
    Message: {alarm['message']}
    Source: {alarm['source']}
    Timestamp: {alarm['timestamp']}
    """
    msg.attach(MIMEText(body, 'plain'))
    with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
        server.starttls()
        server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        server.sendmail(EMAIL_ADDRESS, RECIPIENT_EMAIL, msg.as_string())
        print(f"Email sent for alarm: {alarm['alarm_id']}")

# 告警处理函数
def process_alarm(message, deduplication=True):
    alarm_data = json.loads(message.value)
    alarm_id = alarm_data['alarm_id']
    timestamp = alarm_data['timestamp']
    key = f"{alarm_id}:{timestamp}"

    # 去重逻辑
    if deduplication:
        if not redis_client.exists(key):
            redis_client.setex(key, 3600, "1")  # 设置1小时过期
            send_email(alarm_data)
        else:
            print(f"Duplicate alarm discarded: {alarm_id}")
    else:
        send_email(alarm_data)

# 消费 Kafka 消息
for message in consumer:
    process_alarm(message, deduplication=True)  # 控制去重
