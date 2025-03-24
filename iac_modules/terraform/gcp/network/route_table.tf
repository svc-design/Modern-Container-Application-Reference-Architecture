resource "google_compute_route" "default_route" {
  name                  = "static-route"
  network               = google_compute_network.default.name
  dest_range            = "0.0.0.0/0"
  priority              = 1000
  next_hop_gateway      = "default-internet-gateway"  # 默认互联网网关

  tags = []             # 可选的标签，根据需要添加
}
