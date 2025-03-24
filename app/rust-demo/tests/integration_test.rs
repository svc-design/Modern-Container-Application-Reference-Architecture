use actix_web::web;
use actix_web::App;
use actix_web::test;
use actix_web::http::StatusCode;
use actix_web::test::TestRequest;
use crate::StatusCode;

#[cfg(test)]
mod tests {
    use super::*;

    #[actix_web::test]
    async fn test_query_handler() {
        // 创建一个用于测试的请求
        let req = TestRequest::with_uri("/api/query").to_http_request();

        // 调用处理函数
        let resp = test::call_service(&mut App::new().route("/api/query", web::get().to(query_handler)), req).await;

        // 验证响应
        assert_eq!(resp.status(), HttpResponse::StatusCode::OK);
        assert_eq!(resp.content_type(), "application/json");

        let body: Response = resp.json().await.unwrap();
        assert_eq!(body.message, "Query successful");
    }

    #[actix_web::test]
    async fn test_insert_handler() {
        // 创建一个用于测试的请求
        let req = TestRequest::with_uri("/api/insert").to_http_request();

        // 调用处理函数
        let resp = test::call_service(&mut App::new().route("/api/insert", web::post().to(insert_handler)), req).await;

        // 验证响应
        assert_eq!(resp.status(), HttpResponse::StatusCode::OK);
        assert_eq!(resp.content_type(), "application/json");

        let body: Response = resp.json().await.unwrap();
        assert_eq!(body.message, "Insert successful");
    }
}
