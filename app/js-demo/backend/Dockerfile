FROM node:21.2.0-alpine

WORKDIR /app
COPY . .
RUN rm -f Dockerfile && npm install --prefer-offline

EXPOSE 80

CMD ["node", "index.js"]
