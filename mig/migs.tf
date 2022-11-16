
//instance-template for mig - 1
resource "google_compute_instance_template" "mig-template-1" {
  name = "mig-template-group-1"
  description = "This template is used to create the group1 instance template"
  machine_type = "e2-medium"
  can_ip_forward = false
  
  disk {
      source_image = "debian-cloud/debian-11"
      auto_delete =  true 
      boot = true 
      // backup the disk
  }

  network_interface {
    network = google_compute_network.vpc-network.name
    subnetwork = google_compute_subnetwork.group1.name
  }

  metadata = {
    "startup-script" = "${file("./myscript.sh")}"
  }
}


//health check for mig - 1
resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/"
    port         = "8080"
  }
}
//mig-1 auto scaler 

resource "google_compute_autoscaler" "autoscaler-mig-1" {
  name = "autoscaler-mig-group-1"
  target = google_compute_instance_group_manager.mig1.id 
  //region = var.group1_region

  autoscaling_policy {
    max_replicas = 5
    min_replicas = 1
    cooldown_period = 60

    metric {
      name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
      //filter                     = "resource.type = pubsub_subscription AND resource.label.subscription_id = our-subscription"
      //single_instance_assignment = 65535
    }
  }
}




//mig-1
resource "google_compute_instance_group_manager" "mig1" {
    name = "mig-group-1"
    base_instance_name = "mig-group-1"

    version {
        instance_template = google_compute_instance_template.mig-template-1.id
    }
    named_port {
      name = "custom"
      port = 8888
    }
    auto_healing_policies {
      health_check = google_compute_health_check.autohealing.id 
      initial_delay_sec = 300
    }
}


//-----------------------
//group - 2 instance template
//---------------------------

resource "google_compute_instance_template" "mig-template-2" {
  name = "mig-template-group-2"
  description = "This template is used to create the group1 instance template"
  machine_type = "e2-medium"
  can_ip_forward = false
  
  disk {
      source_image = "debian-cloud/debian-11"
      auto_delete =  true 
      boot = true 
      // backup the disk
  }

  network_interface {
    network = google_compute_network.vpc-network.name
    subnetwork = google_compute_subnetwork.group2.name
  }

  metadata = {
    "startup-script" = "${file("./myscript.sh")}"
  }
}

//-----------------------
//group - 2 - mig auto scaler
//---------------------------

resource "google_compute_autoscaler" "autoscaler-mig-2" {
  name = "autoscaler-mig-group-2"
  target = google_compute_instance_group_manager.mig2.id 
  //region = var.group2_region

  autoscaling_policy {
    max_replicas = 5
    min_replicas = 1
    cooldown_period = 60

    metric {
      name                       = "pubsub.googleapis.com/subscription/num_undelivered_messages"
      //filter                     = "resource.type = pubsub_subscription AND resource.label.subscription_id = our-subscription"
      //single_instance_assignment = 65535
    }
  }
}


//-----------------------
//group - 2 - mig
//---------------------------

resource "google_compute_instance_group_manager" "mig2" {
    name = "mig-group-2"
    base_instance_name = "mig-group-2"
    //region = var.group2_region
    //distribution_policy_zones = ["us-west1-a", "us-west1-b"]

    version {
        instance_template = google_compute_instance_template.mig-template-2.id
    }
    named_port {
      name = "custom"
      port = 8888
    }
    auto_healing_policies {
      health_check = google_compute_health_check.autohealing.id 
      initial_delay_sec = 300
    }
}
