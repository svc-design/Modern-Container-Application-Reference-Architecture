from .aws import ec2, s3, rds, iam, vpc, eks

class AWSProvider:
    def __init__(self):
        self.resources = {}

    def create_resources(self, resource_type, resource_config):
        if resource_type == 's3':
            self.resources['s3'] = s3.create(resource_config)
        elif resource_type == 'ec2':
            self.resources['ec2'] = ec2.create(resource_config)
        # ...其他服务的创建逻辑...

    def delete_resources(self):
        for resource in self.resources.values():
            resource.delete()

    def update_resources(self):
        for resource in self.resources.values():
            resource.update()

    def query_resources(self):
        resources = {}
        for name, resource in self.resources.items():
            resources[name] = resource.query()
        return resources

