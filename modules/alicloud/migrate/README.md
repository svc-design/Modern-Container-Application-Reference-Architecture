# Alibaba Cloud resource import helper

Use the scripts in this directory to build an import manifest for existing
Alibaba Cloud OSS buckets and ECS instances. Run the generator and then feed
the resulting files to Pulumi.

```bash
./generate_import_spec.py --region cn-hangzhou
```

This produces `import-spec.json` and `import-commands.sh`. Update your Pulumi
program with resource definitions that use the generated logical names before
running any imports.
