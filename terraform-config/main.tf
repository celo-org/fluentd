/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  instance_name = format("%s-%s", var.instance_name, substr(md5(module.gce-container.container.image), 0, 8))
}

module "gce-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "~> 3.0"

  container = {
    image = var.image


    # Declare volumes to be mounted
    # This is similar to how Docker volumes are mounted
    volumeMounts = [
      {
        mountPath = "/fluentd/logs"
        name      = "fluentd-logs"
        readOnly  = false
      },
    ]
  }

  # Declare the volumes
  volumes = [
    {
      name = "fluentd-logs"

      gcePersistentDisk = {
        pdName = "fluentd-logs"
        fsType = "ext4"
      }
    },
  ]

  restart_policy = "Always"
}

resource "google_compute_disk" "pd" {
  project = "logging-468916"
  name    = "${local.instance_name}-data-disk"
  type    = "pd-ssd"
  zone    = "us-central1-a"
  size    = 10
}

resource "google_compute_instance" "vm" {
  project      = "logging-468916"
  name         = local.instance_name
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = module.gce-container.source_image
    }
  }

  attached_disk {
    source      = google_compute_disk.pd.self_link
    device_name = "fluentd-logs"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork_project = "logging-468916"
    network = "default"
    access_config {}
  }

  metadata = { "gce-container-declaration" = module.gce-container.metadata_value }

  labels = {
    container-vm = module.gce-container.vm_container_label
  }

  tags = ["container-vm-example", "container-vm-test-disk-instance"]

  service_account {
    email = "fluentd-ingest@logging-468916.iam.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

