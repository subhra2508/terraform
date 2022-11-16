 variable "project" {
   type = string
   default = "gcpsubhrajyoti-test-project"
 }
 
 variable "group1_region" {
  type = string
  default = "us-west1"
}

variable "group2_region" {
  type = string
  default = "us-east1"
}

variable "network_prefix" {
  type = string
  default = "multi-mig-lb-http"
}

variable "target_size" {
  type = number
  default = 2
}