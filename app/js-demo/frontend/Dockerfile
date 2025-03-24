# 构建阶段
FROM node:21.2.0-alpine as builder

WORKDIR /app
COPY package.json .
RUN apk add --no-cache git && npm install --prefer-offline
COPY . .
RUN npm run build

# 运行阶段
FROM nginx:1.21.5-alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
