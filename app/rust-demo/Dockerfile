# 第一个阶段：构建 Rust 二进制文件
FROM rust:1.72.1-slim-buster as builder

WORKDIR /app
COPY . .
RUN cargo build --release

# 第二个阶段：将 Rust 二进制文件复制到最终镜像
FROM scratch
COPY --from=builder /app/target/release/my_rust_server /app
CMD ["/app/my_rust_server"]
