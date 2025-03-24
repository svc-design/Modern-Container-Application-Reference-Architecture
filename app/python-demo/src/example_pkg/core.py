import json
from flask import Flask, request, Response
from pydantic import BaseModel

class User(BaseModel):
    username: str
    age: int

def index_view():
    response = Response(json.dumps({"message": "Hello, world!"}))
    response.headers["Content-Type"] = "application/json"
    response.status_code = 200
    return response

def create_user():
    user_info = request.get_json()
    if user_info is not None:
        response = Response(json.dumps(user_info))
        response.headers["Content-Type"] = "application/json"
        response.status_code = 200
        return response
    else:
        raise HTTPException(status_code=400, detail="用户信息不能为空")
