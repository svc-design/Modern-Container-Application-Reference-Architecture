import json
import unittest
from unittest.mock import patch
from flask import Flask
from example_pkg.core import create_user

class TestCreateUser(unittest.TestCase):
    def setUp(self):
        # 创建一个测试 Flask 应用
        self.app = Flask(__name__)

    def test_create_user_valid_input(self):
        with self.app.test_request_context('/user', method='POST', json={"username": "test_user", "age": 25}):
            response = create_user()
            data = json.loads(response.get_data(as_text=True))

            self.assertEqual(response.status_code, 200)
            self.assertEqual(data["username"], "test_user")
            self.assertEqual(data["age"], 25)


if __name__ == '__main__':
    unittest.main()
