from flask import Flask, request
import json
import redis
import mysql.connector
from confluent_kafka import Producer, Consumer, KafkaError

app = Flask(__name__)
cache = redis.Redis(host='redis-service', port=6379)

# Kafka producer configuration
p = Producer({'bootstrap.servers': 'my-kafka-service:9092'})  # replace 'my-kafka-service' with your Kafka service name

# Kafka consumer configuration
c = Consumer({
    'bootstrap.servers': 'my-kafka-service:9092',  # replace 'my-kafka-service' with your Kafka service name
    'group.id': 'mygroup',
    'auto.offset.reset': 'earliest'
})

c.subscribe(['mytopic'])

@app.route('/produce', methods=['POST'])
def produce():
    data = request.json
    p.produce('mytopic', json.dumps(data))
    return 'Message produced'

@app.route('/consume')
def consume():
    msg = c.poll(1.0)

    if msg is None:
        return 'No message'
    if msg.error():
        return 'Error: {}'.format(msg.error())

    data = json.loads(msg.value().decode('utf-8'))
    return data

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)

