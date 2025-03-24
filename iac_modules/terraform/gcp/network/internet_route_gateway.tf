# 创建互联网网关
resource "google_compute_router" "public_router" {
  name    = "public-router"
  network = google_compute_network.default.id
}
