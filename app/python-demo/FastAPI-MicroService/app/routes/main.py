from bali.core import Service
from db.mysql import get_db_connection
from cache.redis import get_cache_connection
from messaging.kafka import get_kafka_producer, get_kafka_consumer
from app_pb2 import ProduceRequest, ProduceResponse, ConsumeRequest, ConsumeResponse
from app_grpc import AppBase

class AppService(AppBase, Service):
    def __init__(self):
        super().__init__()
        self.producer = get_kafka_producer()
        self.consumer = get_kafka_consumer()
        self.cache = get_cache_connection()
        self.db = get_db_connection()

    async def Produce(self, stream):
        request = await stream.recv_message()
        data = request.data
        self.producer.produce('mytopic', data)
        await stream.send_message(ProduceResponse(message='Message produced'))

    async def Consume(self, stream):
        await stream.recv_message()
        msg = self.consumer.poll(1.0)
        if msg is None:
            data = 'No message'
        elif msg.error():
            data = 'Error: {}'.format(msg.error())
        else:
            data = msg.value().decode('utf-8')
        await stream.send_message(ConsumeResponse(data=data))
