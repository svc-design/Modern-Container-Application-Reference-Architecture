import redis

def get_cache_connection():
    cache = redis.Redis(host='redis-service', port=6379)
    return cache
