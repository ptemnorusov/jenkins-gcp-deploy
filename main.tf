# Configure the Google Cloud provider to use the GOOGLE_APPLICATION_CREDENTIALS environment variable
provider "google" {
  project = var.project_id
  region  = var.region
}

# terraform state could be saved remotely on S3 for security and convenience.

# Define Google Cloud Storage Bucket for hosting static content
resource "google_storage_bucket" "static_site_bucket" {
  name     = "my-static-site-bucket-${var.project_id}"
  location = var.region
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# Make the bucket publicly accessible
resource "google_storage_bucket_iam_member" "all_users_object_viewer" {
  bucket = google_storage_bucket.static_site_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload your static files to the bucket
resource "google_storage_bucket_object" "index_html" {
  name   = "index.html"
  bucket = google_storage_bucket.static_site_bucket.name
  source = "site/index.html"
}

# Reserve a global IP address for the load balancer
resource "google_compute_global_address" "default" {
  name = "global-address"
}

# Backend bucket for serving content from GCS
resource "google_compute_backend_bucket" "static_content" {
  name        = "static-content-backend"
  bucket_name = google_storage_bucket.static_site_bucket.name
  enable_cdn  = false
}

# URL map to route incoming requests to the backend bucket
resource "google_compute_url_map" "bucket_url_map" {
  name            = "bucket-url-map"
  default_service = google_compute_backend_bucket.static_content.id
}

# Target HTTP proxy to handle HTTP requests
resource "google_compute_target_http_proxy" "bucket_http_proxy" {
  name    = "bucket-http-proxy"
  url_map = google_compute_url_map.bucket_url_map.id
}

# Global forwarding rule to route traffic to the HTTP proxy
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name       = "http-forwarding-rule"
  target     = google_compute_target_http_proxy.bucket_http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

# Outputs
output "bucket_url" {
  description = "URL of the Google Cloud Storage bucket website"
  value       = "http://${google_storage_bucket.static_site_bucket.name}.storage.googleapis.com"
}

output "global_address" {
  description = "IP address of the global load balancer"
  value       = google_compute_global_address.default.address
}

output "load_balancer_url" {
  description = "Load balancer URL for the static site"
  value       = "http://${google_compute_global_address.default.address}"
}
