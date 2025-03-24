import pytest
from example_pkg.core import index_view, create_user

def test_index_view():
    response = index_view()
    assert response.status_code == 200
    assert response.headers["Content-Type"] == "application/json"
    assert response.get_data() == b'{"message": "Hello, world!"}'
