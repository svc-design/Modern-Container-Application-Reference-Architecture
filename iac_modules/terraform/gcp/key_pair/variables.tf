locals {
  config = yamldecode(file("config.yaml"))
}

locals {
  ssh_keys_content = file("ssh_keys.pub")
}
