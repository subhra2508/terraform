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

