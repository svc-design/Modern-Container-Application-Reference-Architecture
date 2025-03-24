from confluent_kafka import Producer, Consumer

def get_kafka_producer():
    p = Producer({'bootstrap.servers': 'my-kafka-service:9092'})
    return p

def get_kafka_consumer():
    c = Consumer({
        'bootstrap.servers': 'my-kafka-service:9092',
        'group.id': 'mygroup',
        'auto.offset.reset': 'earliest'
    })
    c.subscribe(['mytopic'])
    return c
