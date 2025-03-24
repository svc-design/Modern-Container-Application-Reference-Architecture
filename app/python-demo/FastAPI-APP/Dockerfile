FROM python:3.7-alpine
WORKDIR /app
COPY . /app
RUN pip install fastapi uvicorn mysql-connector-python redis confluent-kafka
EXPOSE 80
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "80"]
