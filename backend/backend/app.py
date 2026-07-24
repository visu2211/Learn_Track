# app.py

from flask import Flask, jsonify, request
from config import Config
from blueprints.auth import auth_bp
from blueprints.users import users_bp
from blueprints.learning import learning_bp
from flask_cors import CORS

app = Flask(__name__)
# Enable CORS for all routes with proper settings for web
CORS(app, resources={r"/*": {"origins": "*", "allow_headers": "*", "expose_headers": "*"}})
app.config.from_object(Config)

# Create a root API blueprint
from flask import Blueprint
api_bp = Blueprint('api', __name__, url_prefix='/api')

# Register blueprints with the API blueprint
api_bp.register_blueprint(auth_bp)
api_bp.register_blueprint(users_bp)
api_bp.register_blueprint(learning_bp)

# Register the API blueprint with the app
app.register_blueprint(api_bp)

@app.route('/')
def index():
    return jsonify({"message": "LearnTrack API is running"})

@app.route('/healthcheck')
def healthcheck():
    # Don't parse JSON for a GET request
    return jsonify({"status": "ok", "service": "LearnTrack API"})

@app.before_request
def log_request_info():
    print(f"Request: {request.method} {request.path} {request.headers}")
    # Only try to get JSON data if the content type is application/json and there's actually data
    if request.is_json and request.get_data(as_text=True):
        print(f"JSON Data: {request.get_json()}")

@app.after_request
def log_response_info(response):
    print(f"Response: {response.status_code} {response.get_data()}")
    # Add CORS headers for web requests
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

if __name__ == '__main__':
    print("Starting server on http://0.0.0.0:8000")
    app.run(debug=True, host='0.0.0.0', port=8000)
