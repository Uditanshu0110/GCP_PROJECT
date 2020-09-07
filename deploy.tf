provider "google" {
  credentials = file("ac.json")
  project     = "developmentproject-287207"
  region      = "asia-southeast1"

}
provider "google" {
    alias  = "udit"
  credentials = file("prod.json")
  project     = "prod-0506"
  region      = "us-west1"

}
resource "google_compute_network" "vpc_network" {
  name = "vpc-network"
  auto_create_subnetworks = "false"

}
resource "google_compute_subnetwork" "vpc_first_subnet" {
 name          = "vpcfirstsubnet"
 ip_cidr_range = "10.0.2.0/24"
 network       = google_compute_network.vpc_network.id
 depends_on    = [google_compute_network.vpc_network]
 region      = "asia-southeast1"
}

resource "google_compute_firewall" "vpc_firewall" {
  name    = "vpc-firewall"
  network = google_compute_network.vpc_network.name


  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges =  ["0.0.0.0/0"]
}


resource "google_container_cluster" "wpcluster" {
  name     = "my-wp-cluster"
  location = "asia-southeast1"
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "asia-southeast1"
  cluster    = google_container_cluster.wpcluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"

    metadata = {
      disable-legacy-endpoints = "true"
    }

   
  }
}
resource "google_compute_network_peering" "devpeering" {
  name         = "devpeering"
  network      = google_compute_network.vpc_network.id
  peer_network = google_compute_network.prod_vpc.id
}



resource "google_compute_network" "prod_vpc" {
  name = "prodvpc"
  auto_create_subnetworks = "false"
  provider = google.udit

}
resource "google_compute_subnetwork" "prod_subnet" {
 name          = "prodfirstsubnet"
 ip_cidr_range = "10.0.1.0/24"
 network       = google_compute_network.prod_vpc.id
 depends_on    = [google_compute_network.prod_vpc]
 region      = "us-west1"
 provider = google.udit
}

resource "google_compute_firewall" "prod_firewall" {
  name    = "prod-firewall"
  network = google_compute_network.prod_vpc.name
  provider = google.udit


  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges =  ["0.0.0.0/0"]
}
resource "google_compute_network_peering" "prod_peering" {
  name         = "prodpeering"
  network      = google_compute_network.prod_vpc.id
  peer_network = google_compute_network.vpc_network.id
  provider = google.udit
}

resource "google_sql_database" "mydatabase" {
  name     = "my-database"
  instance = google_sql_database_instance.sqlinstance.name
  provider = google.udit
}

resource "google_sql_database_instance" "sqlinstance" {
  name   = "my-database-instance4"
  region = "us-west1"
  provider = google.udit
  //database_version = "MYSQL_5.7"
  settings {
    tier = "db-f1-micro"
    
  }
}
resource "google_sql_user" "users" {
  name     = "me"
  instance = google_sql_database_instance.sqlinstance.name
  password = "changeme"
  provider = google.udit
}

