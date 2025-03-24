# main.py
import connexion
from flask import Flask
from flask_cors import CORS
from example_pkg.core import index_view, create_user

app = Flask(__name__)
CORS(app, origins="*")

# Use Connexion to add OpenAPI support
connex_app = connexion.App(__name__, specification_dir='./')
connex_app.add_api('openapi.yaml', arguments={'title': 'Your API'})
connex_app.init_app(app)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
