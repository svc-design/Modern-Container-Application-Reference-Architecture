locals {
  ssh_keys_content = file("ssh_keys.pub")
}

{% for instance in vars.instances %}
resource "google_compute_address" "{{ instance.name | lower }}" {
  name    = "{{ instance.name }}"
  project = "{{ vars.project_id }}"
  region  = "{{ vars.region }}"
}

resource "google_compute_instance" "{{ instance.name | lower }}" {
  name         = "{{ instance.name }}"
  machine_type = "{{ instance.type }}"
  zone         = "{{ instance.zone }}"

  boot_disk {
    initialize_params {
      image = "{{ instance.image }}"
      size  = {{ instance.disk_size_gb }}
    }
  }

  network_interface {
    network = "{{ instance.network }}"
    subnetwork = "{{ instance.subnetwork }}"

    access_config {
      nat_ip = google_compute_address.{{ instance.name | lower }}.address
    }
  }

  metadata = {
    "ssh-keys" = <<EOF
ubuntu:${local.ssh_keys_content}
EOF
  }

  depends_on = [google_compute_address.{{ instance.name | lower }}]
}

output "{{ instance.name | lower }}" {
  value = google_compute_address.{{ instance.name | lower }}.address
}

{% endfor %}
