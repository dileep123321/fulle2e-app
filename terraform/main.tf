terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "dileep-481002"
  region  = "us-central1"
}

resource "google_artifact_registry_repository" "backend_repo" {
  location      = "us-central1"
  repository_id = "backend-repo"
  format        = "DOCKER"
}

resource "google_service_account" "github_sa" {
  account_id   = "github-gke-sa"
  display_name = "GitHub Actions GKE Deploy SA"
}

resource "google_project_iam_member" "gke" {
  project = "dileep-481002"
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}

resource "google_project_iam_member" "artifact" {
  project = "dileep-481002"
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Pool"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  attribute_mapping = {
    "google.subject"        = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_bind" {
  service_account_id = google_service_account.github_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/271085679762/locations/global/workloadIdentityPools/github-pool/attribute.repository/dileep123321/fulle2e-app"
}
