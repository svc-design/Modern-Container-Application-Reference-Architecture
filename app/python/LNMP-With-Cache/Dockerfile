FROM python:3.7-alpine
WORKDIR /app
COPY . /app
RUN pip install flask mysql-connector-python redis
EXPOSE 80
CMD ["python", "app.py"]
