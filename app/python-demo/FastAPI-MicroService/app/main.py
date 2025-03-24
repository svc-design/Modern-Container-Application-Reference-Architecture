from grpclib.server import Server
from routes.main import AppService

async def main():
    server = Server([AppService()])
    await server.start('127.0.0.1', 50051)
    print('Serving on localhost:50051')

if __name__ == '__main__':
    import asyncio
    asyncio.run(main())
