import mysql.connector

def get_db_connection():
    db = mysql.connector.connect(
        host="mysql-service",
        user="username",
        password="password",
        database="mydb"
    )
    return db

