module "gce-container" {
  source = "terraform-google-modules/container-vm/google"
  version = "~> 3.2"

  container = {
    image=var.fluentd-image
  }
  restart_policy = "Always"
  
}
