locals {
  ssh_keys_content = file("ssh_keys.pub")
}

resource "google_compute_project_metadata" "default" {
  metadata = {
    "ssh-keys" = <<EOF
ubuntu:${local.ssh_keys_content}
EOF
  }
}

output "metadata" {
  value = google_compute_project_metadata.default.metadata
}
