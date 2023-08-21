from fastapi import FastAPI
from cloud_manager.models import ResourceConfig, CloudManager
from cloud_manager.providers.aws_provider import AWSProvider

app = FastAPI()

@app.post("/resources")
async def create_resource(resource: ResourceConfig):
    if resource.provider == 'aws':
        provider = AWSProvider()
    else:
        return {"error": "Unsupported provider"}

    manager = CloudManager(provider, resource.resource_type, resource.config)
    manager.create_resources()
    return {"message": "Resource created successfully"}
