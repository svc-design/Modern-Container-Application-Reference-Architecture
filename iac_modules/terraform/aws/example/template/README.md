# Module Prep

1. create terraform backend s3
create dir: ec2, vpc, key, sg 
2. create dynamodb_table
```
name = "LockID"
type = "S"
```

3. setup aws-cli and terraform
```
sudo apt install -y jq python3-pip
pip3 install python-hcl2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt-get install terraform -y
```

4. cat > ~/.terraformrc << EOF
plugin_cache_dir   = /root/.terraform.d/plugin-cache"
disable_checkpoint = true
disable_checkpoint_signature = true
host "registry.terraform.io" {
    services = {
      "providers.v1" = "https://mirrors.onwalk.net/terraform/v1/providers/"
    }
  }
EOF

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
export region=cn-northwest-1
export ak=<ak-token-xxxxx>
export sk=<sk-token-xxxxx>
export tf_key='dir/<key_name>/terraform-state'
export tf_s3=<s3-name>
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
