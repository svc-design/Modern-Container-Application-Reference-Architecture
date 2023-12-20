{% for rule in vars.firewall_rules %}
resource "google_compute_firewall" "{{ rule.name }}" {
  name        = "{{ rule.name }}"
  network     = "{{ rule.network }}"
  allow {
    protocol = "{{ rule.allow[0].protocol }}"
    ports    = [{{ '"' + '", "'.join(rule.allow[0].ports) + '"' }}]
  }
  source_ranges = [{{ '"' + '", "'.join(rule.source_ranges) + '"' }}]
}
{% endfor %}
