terraform {
  required_version = ">= 1.5.0"

  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}

# The provider reads SUPABASE_ACCESS_TOKEN from the environment. Keeping the
# block argument-free prevents the token from being copied into tfvars/state.
provider "supabase" {}
