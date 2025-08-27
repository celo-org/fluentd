terraform {
  backend "gcs" {
    bucket = "tfstate-fluentd"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}
provider "google" {
  project = var.gcp_provider_project
  region  = var.gcp_provider_region
}


