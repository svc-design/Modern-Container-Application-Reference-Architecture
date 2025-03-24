// 在你的测试模块中添加以下代码

#[cfg(test)]
mod tests {
    use super::*;
    use actix_web::test;

    #[actix_rt::test]
    async fn test_query_handler() {
        // 模拟 GET 请求到 "/api/query"
        let req = test::TestRequest::get().uri("/api/query").to_request();
        
        // 调用处理程序函数并获取响应
        let resp = query_handler().await.respond_to(&req).await.unwrap();

        // 验证响应状态码为 200 OK
        assert_eq!(resp.status(), actix_web::http::StatusCode::OK);

        // 验证响应的内容
        let body = test::read_body(resp).await;
        let expected_response = r#"{"message":"Query successful"}"#;
        assert_eq!(body, expected_response);
    }

    #[actix_rt::test]
    async fn test_insert_handler() {
        // 模拟 POST 请求到 "/api/insert"
        let req = test::TestRequest::post().uri("/api/insert").to_request();
        
        // 调用处理程序函数并获取响应
        let resp = insert_handler().await.respond_to(&req).await.unwrap();

        // 验证响应状态码为 200 OK
        assert_eq!(resp.status(), actix_web::http::StatusCode::OK);

        // 验证响应的内容
        let body = test::read_body(resp).await;
        let expected_response = r#"{"message":"Insert successful"}"#;
        assert_eq!(body, expected_response);
    }

    // 添加其他测试...

}
