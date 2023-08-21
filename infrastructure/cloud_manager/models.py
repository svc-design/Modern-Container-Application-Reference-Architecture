from pydantic import BaseModel

class ResourceConfig(BaseModel):
    provider: str
    resource_type: str
    config: dict

class CloudManager:
    def __init__(self, provider, resource_type, resource_config):
        self.provider = provider
        self.resource_type = resource_type
        self.resource_config = resource_config

    def create_resources(self):
        self.provider.create_resources(self.resource_type, self.resource_config)

    def delete_resources(self):
        self.provider.delete_resources()

    def update_resources(self):
        self.provider.update_resources()

    def query_resources(self):
        return self.provider.query_resources()

    def migrate_resources(self, to_provider):
        resources = self.query_resources()
        to_provider.create_resources(resources)
        self.delete_resources()

