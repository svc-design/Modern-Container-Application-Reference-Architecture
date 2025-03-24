use serde::Serialize;
use actix_web::{web, App, HttpServer, HttpResponse, Responder};

#[derive(Serialize)]
struct Response {
    message: String,
}

async fn query_handler() -> impl Responder {
    let response = Response { message: "Query successful".to_string() };
    HttpResponse::Ok().json(response)
}

async fn insert_handler() -> impl Responder {
    let response = Response { message: "Insert successful".to_string() };
    HttpResponse::Ok().json(response)
}

pub async fn run_server() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .route("/api/query", web::get().to(query_handler))
            .route("/api/insert", web::post().to(insert_handler))
    })
    .bind("127.0.0.1:80")?
    .run()
    .await
}
