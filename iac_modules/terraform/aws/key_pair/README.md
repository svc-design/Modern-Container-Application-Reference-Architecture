# Module Prep

1. create terraform backend s3
create dir: ec2, vpc, key, sg 
2. create dynamodb_table
```
name = "LockID"
type = "S"
```

# Module Dev

cat >> variables.tf <<EOF 
locals {
  data = yamldecode(file("./input-variables.yaml"))
}
EOF

# Module Test

## input env vars

example:

```
export region=ap-east-1
export az=ap-east-1a
export ak=<ak-token-xxxxx>
export sk=<sk-token-xxxxx>
export tf_key='dir/<key_name>/terraform-state'
export tf_s3=<s3-name>

export vpc_cidr='10.0.0.0/16'
```

# run command

```
make apply
make output
make destroy
```

# ouput file

filename: build.env

example:
```
```
