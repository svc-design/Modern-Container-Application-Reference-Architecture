#第一阶段：编译阶段
FROM golang:1.21-alpine as builder

WORKDIR /app
COPY . .
RUN go build -o main

# 第二阶段：运行阶段
FROM alpine:3.15 as runner

WORKDIR /app
COPY --from=builder /app/main .
EXPOSE 80
CMD ["./main"]
