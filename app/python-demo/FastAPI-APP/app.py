from fastapi import FastAPI
from starlette.requests import Request
import mysql.connector
import redis
import json
from confluent_kafka import Producer, Consumer, KafkaError

app = FastAPI()
cache = redis.Redis(host='redis-service', port=6379)

# Kafka producer configuration
p = Producer({'bootstrap.servers': 'my-kafka-service:9092'})

# Kafka consumer configuration
c = Consumer({
    'bootstrap.servers': 'my-kafka-service:9092',
    'group.id': 'mygroup',
    'auto.offset.reset': 'earliest'
})
c.subscribe(['mytopic'])

@app.get('/')
async def read_root():
    data = cache.get('mydata')
    if data is not None:
        return data

    db = mysql.connector.connect(
        host="mysql-service",
        user="username",
        password="password",
        database="mydb"
    )
    cursor = db.cursor()
    cursor.execute("SELECT * FROM your_table")
    results = cursor.fetchall()
    data = json.dumps(results)

    cache.set('mydata', data)
    return data

@app.post('/produce')
async def produce(request: Request):
    data = await request.json()
    p.produce('mytopic', json.dumps(data))
    return {'message': 'Message produced'}

@app.get('/consume')
async def consume():
    msg = c.poll(1.0)

    if msg is None:
        return {'message': 'No message'}
    if msg.error():
        return {'error': str(msg.error())}

    data = json.loads(msg.value().decode('utf-8'))
    return data
