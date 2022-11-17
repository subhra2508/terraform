resource "google_compute_network" "vpc-network" {
  name = var.network_prefix
  auto_create_subnetworks = false
}

# subnetwork - group 1
resource "google_compute_subnetwork" "group1" {
  name = "${var.network_prefix}-group1"
  ip_cidr_range = "10.126.0.0/20"
  network = google_compute_network.vpc-network.self_link
  region = var.group1_region
  private_ip_google_access = true
}


## cloud router - group 1

resource "google_compute_router" "group1" {
    name = "${var.network_prefix}-gw-group1"
    network = google_compute_network.vpc-network.self_link
    region = var.group1_region
}

# cloud nat - group 1
resource "google_compute_router_nat" "cloud-nat-1" {
    name = "${var.network_prefix}-cloud-nat-group1"
    router = google_compute_router.group1.name
    region = google_compute_router.group1.region
    nat_ip_allocate_option = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

    log_config {
      enable = true
      filter = "ERRORS_ONLY"
    }
}

# subnetwork - group 2
resource "google_compute_subnetwork" "group2"{
    name = "${var.network_prefix}-group2"
    ip_cidr_range = "10.127.0.0/20"
    network = google_compute_network.vpc-network.self_link
    region = var.group2_region
    private_ip_google_access = true
}

#cloud router - group 2

resource "google_compute_router" "group2" {
    name = "${var.network_prefix}-gw-group2"
    network = google_compute_network.vpc-network.self_link
    region = var.group2_region
}

#cloud nat - group 2

resource "google_compute_router_nat" "cloud-nat-2" {
    name = "${var.network_prefix}-cloud-nat-group2"
    router = google_compute_router.group2.name
    region = google_compute_router.group2.region
    nat_ip_allocate_option = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

    log_config {
      enable = true
      filter = "ERRORS_ONLY"
    }
}

# cloud load balancing - backends
resource "google_compute_firewall" "default" {
  name          = "${var.network_prefix}-fw-allow-hc"
  direction     = "INGRESS"
  network       = google_compute_network.vpc-network.id
  source_ranges = ["10.126.0.0/20", "10.127.0.0/20"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}


# reserved IP address
resource "google_compute_global_address" "static-ip" {
  name     = "${var.network_prefix}-static-ip"
}

# url map
resource "google_compute_url_map" "default" {
  name            = "${var.network_prefix}-url-map"
  default_service = google_compute_backend_service.default.id
}

# http proxy
resource "google_compute_target_http_proxy" "default" {
  name     = "${var.network_prefix}-target-http-proxy"
  url_map  = google_compute_url_map.default.id
}

# forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "${var.network_prefix}-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.static-ip.id
}


# backend service with custom request and response headers
resource "google_compute_backend_service" "default" {
  name                    = "${var.network_prefix}-backend-service"
  protocol                = "HTTP"
  port_name               = "http"
  load_balancing_scheme   = "EXTERNAL"
  timeout_sec             = 10
  enable_cdn              = true
  custom_request_headers  = ["X-Client-Geo-Location: {client_region_subdivision}, {client_city}"]
  custom_response_headers = ["X-Cache-Hit: {cdn_cache_status}"]
  health_checks           = [google_compute_health_check.autohealing.id]
  backend {
    group = google_compute_instance_group_manager.mig1.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
    backend {
    group = google_compute_instance_group_manager.mig2.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

}