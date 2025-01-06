from kafka import KafkaProducer
import json
import time
import random

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

alarm_levels = ["INFO", "WARNING", "CRITICAL"]

def generate_alarm():
    return {
        "alarm_id": random.randint(1000, 9999),
        "timestamp": int(time.time()),
        "level": random.choice(alarm_levels),
        "message": "System load high",
        "source": "Server-01"
    }

while True:
    alarm = generate_alarm()
    producer.send('alarm_topic', alarm)
    print(f"Produced: {alarm}")
    time.sleep(5)
