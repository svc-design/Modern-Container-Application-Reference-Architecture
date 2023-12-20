# Create a VPC network
resource "google_compute_network" "default" {
  name                    = "custom"
  project                 = local.config.project_id
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
  description             = "My custom network"
}

# 子网1：路由到互联网网关出口的子网
resource "google_compute_subnetwork" "public_subnet" {
  name          = "internet-subnet"
  ip_cidr_range = "10.0.1.0/24"  # 请根据实际需要调整 IP 范围
  network       = google_compute_network.default.id
}

# 子网2：路由到 NAT 网关出口的子网
resource "google_compute_subnetwork" "nat_subnet" {
  name          = "nat-subnet"
  ip_cidr_range = "10.0.2.0/24"  # 请根据实际需要调整 IP 范围
  network       = google_compute_network.default.id
}

# 子网3：私有的安全子网
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.3.0/24"  # 请根据实际需要调整 IP 范围
  network       = google_compute_network.default.id
}


