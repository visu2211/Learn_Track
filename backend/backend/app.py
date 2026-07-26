# app.py

import os
from flask import Flask, jsonify, request
from config import Config
from blueprints.auth import auth_bp
from blueprints.users import users_bp
from blueprints.learning import learning_bp
from flask_cors import CORS
from init_db import init_database

app = Flask(__name__)
# Enable CORS for all routes with proper settings for web
CORS(app, resources={r"/*": {"origins": "*", "allow_headers": "*", "expose_headers": "*"}})
app.config.from_object(Config)

# Create tables (and the SQLite fallback DB) on startup if they don't exist
# yet. Safe to call on every boot - this is how a fresh deploy (e.g. Render)
# ends up with a working database without a separate manual setup step.
init_database()

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
    # CORS headers are handled by flask_cors (see CORS(app, ...) above).
    # Do not add them here too - duplicate/conflicting header values cause
    # browsers to reject custom request headers like X-User-ID, silently
    # breaking every /courses, /paths, and /streak request from the app.
    return response

if __name__ == '__main__':
    # This block only runs for local dev (`python app.py`). In production,
    # gunicorn (see Procfile) imports `app` directly and never calls
    # app.run(), so debug mode / the Flask dev server are never reachable
    # there regardless of FLASK_DEBUG - the two entrypoints are mutually
    # exclusive on purpose.
    port = int(os.environ.get('PORT', 8000))
    debug = os.environ.get('FLASK_DEBUG', '1') == '1'
    print(f"Starting server on http://0.0.0.0:{port} (debug={debug})")
    app.run(debug=debug, host='0.0.0.0', port=port)
