resource "google_compute_network" "mynetwork" {
  name = "mynetwork"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "test-subnetwork" {
    name = "test-subnetwork"
    ip_cidr_range = var.ip_cidr_range
    region = var.region
    network = google_compute_network.mynetwork.self_link   
}

resource "google_compute_instance" "instance-1" {
    name = "vm-instance"
    machine_type = "f1-micro"
    zone = "us-central1-a"

    boot_disk {
      initialize_params {
          image = "debian-cloud/debian-11"
      }
    }

    network_interface {
      network = "mynetwork"
      subnetwork = "test-subnetwork"
      access_config {
        
      }
    }

}