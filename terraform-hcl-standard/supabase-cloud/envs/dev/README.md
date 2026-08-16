# Supabase Cloud dev workdir

This directory is a Terraform run directory. Render it from the resource
declaration instead of adding hand-written Terraform files here.

```bash
export SUPABASE_ACCESS_TOKEN="..."
export SUPABASE_PROJECT_REF="abcdefghijklmnopqrst"
export SUPABASE_ORGANIZATION_ID="your-org-slug"
export TF_VAR_database_password="..."

./scripts/init.sh
terraform -chdir=envs/dev plan
terraform -chdir=envs/dev apply
terraform -chdir=envs/dev output -raw database_uri
```

For an existing project, `init.sh` renders an import block from
`SUPABASE_PROJECT_REF`; `terraform plan` then imports and reconciles the
project. Omit that variable to create a new project. The direct URI is
optional and should be injected as `TF_VAR_database_uri` from Vault. Without
it, `database_uri` selects the configured Supavisor mode (`session` by
default).
