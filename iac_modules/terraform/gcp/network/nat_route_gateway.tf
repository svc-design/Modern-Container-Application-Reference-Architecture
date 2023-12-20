# 创建 NAT 网关

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  region  = google_compute_subnetwork.nat_subnet.region
  network = google_compute_network.default.id
}

resource "google_compute_address" "nat_address" {
  count  = 1
  name   = "nat-manual-ip-${count.index}"
  region = google_compute_subnetwork.nat_subnet.region
}

resource "google_compute_router_nat" "nat_manual" {
  name   = "router-nat"
  router = google_compute_router.nat_router.name
  region = google_compute_router.nat_router.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.nat_address.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.nat_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
