locals {
  bootstrap_config_path = abspath(var.bootstrap_config_path)
  config_root           = dirname(dirname(dirname(local.bootstrap_config_path)))
  bootstrap             = yamldecode(file(local.bootstrap_config_path))

  github_actions_oidc_config_path_input = coalesce(
    var.github_actions_oidc_config_path,
    try(local.bootstrap.github_actions_oidc.config_path, null),
  )
  github_actions_oidc_config_path = local.github_actions_oidc_config_path_input == null ? null : abspath(
    startswith(local.github_actions_oidc_config_path_input, "/")
    ? local.github_actions_oidc_config_path_input
    : "${dirname(local.bootstrap_config_path)}/${local.github_actions_oidc_config_path_input}"
  )
  # null is type-compatible with the decoded GitOps object. Using {} here
  # makes Terraform try to unify an empty object with the declaration's full
  # schema and fails before lifecycle preconditions can report a useful error.
  github_actions_oidc_config  = local.github_actions_oidc_config_path == null ? null : yamldecode(file(local.github_actions_oidc_config_path))
  github_actions_oidc_spec    = try(local.github_actions_oidc_config.spec, {})
  github_actions_provider_url = try(local.github_actions_oidc_spec.provider_url, null)
  github_actions_audience     = try(local.github_actions_oidc_spec.audience, null)
  github_actions_subjects     = try(tolist(local.github_actions_oidc_spec.subjects), [])
  github_actions_account_id   = try(tostring(local.github_actions_oidc_spec.aws.account_id), null)
  github_actions_role_name    = try(local.github_actions_oidc_spec.aws.role_name, null)
  github_actions_role_arn     = try(local.github_actions_oidc_spec.aws.role_arn, null)

  config_account_name   = local.bootstrap.account_name
  config_region         = local.bootstrap.region
  config_role_name      = local.bootstrap.iam.role_name
  config_terraform_user = local.bootstrap.iam.terraform_user_name
  environment           = coalesce(try(local.bootstrap.environment, null), try(local.bootstrap.iam.environment, null), "bootstrap")
  extra_tags            = try(local.bootstrap.tags, {})

  create_role        = try(local.bootstrap.iam.create_role, true)
  existing_role_name = try(local.bootstrap.iam.existing_role_name, null)
  existing_role_arn  = try(local.bootstrap.iam.existing_role_arn, null)
  role_name          = coalesce(local.existing_role_name, local.config_role_name)

  create_user         = try(local.bootstrap.iam.create_user, true)
  existing_user_name  = try(local.bootstrap.iam.existing_user_name, null)
  terraform_user_name = coalesce(local.existing_user_name, local.config_terraform_user)

  state_bucket_name   = try(local.bootstrap.state.bucket_name, null)
  lock_table_name     = try(local.bootstrap.state.dynamodb_table_name, null)
  managed_policy_arns = try(local.bootstrap.iam.managed_policy_arns, ["arn:aws:iam::aws:policy/AdministratorAccess"])
}

locals {
  account_file_path = "${local.config_root}/config/accounts/${local.config_account_name}.yaml"
  account = fileexists(local.account_file_path) ? yamldecode(file(local.account_file_path)) : {
    account_id  = local.bootstrap.account_id
    environment = local.environment
    tags        = local.extra_tags
  }
}
