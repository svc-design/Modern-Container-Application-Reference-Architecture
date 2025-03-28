from fastapi import APIRouter, Request
from db.mysql import get_db_connection
from cache.redis import get_cache_connection
from messaging.kafka import get_kafka_producer, get_kafka_consumer
import json

router = APIRouter()

@router.get('/')
async def read_root():
    cache = get_cache_connection()
    data = cache.get('mydata')
    if data is not None:
        return data

    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM your_table")
    results = cursor.fetchall()
    data = json.dumps(results)
    
    cache.set('mydata', data)
    return data

@router.post('/produce')
async def produce(request: Request):
    data = await request.json()
    p = get_kafka_producer()
    p.produce('mytopic', json.dumps(data))
    return {'message': 'Message produced'}

@router.get('/consume')
async def consume():
    c = get_kafka_consumer()
    msg = c.poll(1.0)

    if msg is None:
        return 'No message', 200
    if msg.error():
        return 'Error: {}'.format(msg.error()), 500
    
    data = json.loads(msg.value().decode('utf-8'))
    return json.dumps(data), 200

