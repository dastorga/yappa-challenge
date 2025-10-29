# Firestore Database en modo nativo (compatible v3.22.0) 
# App Engine no es necesario para Firestore nativo en versiones modernas

resource "google_app_engine_application" "app_engine_application" {
  project     = var.project_id
  location_id = var.firestore_location

  depends_on = [
    google_project_service.firestore
  ]
}

# Firestore se habilita directamente via google_project_service.firestore
