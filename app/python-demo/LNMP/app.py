from flask import Flask
import mysql.connector

app = Flask(__name__)

@app.route('/')
def hello_world():
    db = mysql.connector.connect(
        host="mysql-service",  # Kubernetes service name for your MySQL service
        user="username",
        password="password",
        database="mydb"
    )
    cursor = db.cursor()
    cursor.execute("SELECT * FROM your_table")  # Replace 'your_table' with your table name
    results = cursor.fetchall()
    return str(results)  # Convert results to string to return as HTTP response

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
