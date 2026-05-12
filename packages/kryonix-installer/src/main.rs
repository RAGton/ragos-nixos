use axum::{
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::process::Command;
use tower_http::cors::CorsLayer;

#[derive(Serialize, Deserialize)]
struct Status {
    status: String,
    version: String,
    phase: String,
}

#[derive(Serialize, Deserialize)]
struct ErrorResponse {
    error: String,
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/health", get(health))
        .route("/version", get(version))
        .route("/probe", get(probe))
        .route("/plan", post(generate_plan))
        .route("/plan/validate", post(validate_plan))
        .route("/dry-run", post(dry_run))
        .route("/apply", post(apply_blocked))
        .layer(CorsLayer::permissive());

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    println!("Kryonix Installer API listening on {}", listener.local_addr().unwrap());
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<Status> {
    Json(Status {
        status: "ok".to_string(),
        version: "0.1.0".to_string(),
        phase: "1".to_string(),
    })
}

async fn version() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "installer": "0.1.0",
        "api_version": 1,
        "supported_hosts": ["inspiron", "glacier"]
    }))
}

async fn probe() -> Json<serde_json::Value> {
    let output = Command::new("kryonix-hardware-probe").output();
    match output {
        Ok(o) => {
            let json: serde_json::Value = serde_json::from_slice(&o.stdout).unwrap_or(serde_json::json!({"error": "Parse error"}));
            Json(json)
        }
        Err(e) => Json(serde_json::json!({"error": format!("Failed to run probe: {}", e)})),
    }
}

async fn generate_plan(Json(payload): Json<serde_json::Value>) -> Json<serde_json::Value> {
    // Em uma implementação real, isso passaria o payload para o disk-planner
    let output = Command::new("kryonix-disk-planner").output();
    match output {
        Ok(o) => {
            let json: serde_json::Value = serde_json::from_slice(&o.stdout).unwrap_or(serde_json::json!({"error": "Parse error"}));
            Json(json)
        }
        Err(e) => Json(serde_json::json!({"error": format!("Failed to run planner: {}", e)})),
    }
}

async fn validate_plan(Json(payload): Json<serde_json::Value>) -> Json<serde_json::Value> {
    // Stub de validação
    Json(serde_json::json!({
        "valid": true,
        "warnings": [],
        "message": "Plan matches schema (stub)"
    }))
}

async fn dry_run(Json(payload): Json<serde_json::Value>) -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "simulation": "ok",
        "steps": [
            "Detecting hardware...",
            "Validating install-plan.json...",
            "Simulating disk partitioning (dry-run)...",
            "Simulating NixOS install (dry-run)..."
        ],
        "message": "Dry-run completed successfully. No changes were made."
    }))
}

async fn apply_blocked() -> Json<ErrorResponse> {
    Json(ErrorResponse {
        error: "destructive_action_disabled_in_phase_1".to_string(),
    })
}
