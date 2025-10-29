# Firestore Database en modo nativo (compatible v3.22.0)
# En versiones anteriores, Firestore se habilitaba via App Engine

resource "google_app_engine_application" "app" {
  project     = var.project_id
  location_id = var.firestore_location

  depends_on = [
    google_project_service.firestore,
    google_project_service.appengine
  ]
}
