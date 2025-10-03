# AWS resource import helper

This directory provides automation to bulk-import existing AWS resources into
Pulumi state. The workflow is:

1. Ensure you can access the target account with the AWS CLI.
2. Run `./generate_import_spec.py` to create `import-spec.json` and
   `import-commands.sh`.
3. Review the generated files and update your Pulumi program with matching
   logical resource names.
4. Execute `./import-commands.sh` or use the JSON file with your own tooling to
   perform the imports.

The generated JSON file has the following shape:

```json
{
  "resources": [
    {"type": "aws:s3/bucket:Bucket", "name": "s3-example", "id": "example"}
  ]
}
```

Each entry maps directly to a `pulumi import` invocation.
