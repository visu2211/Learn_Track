# blueprints/auth.py

from flask import Blueprint, request, jsonify
import hashlib
from database import get_connection

auth_bp = Blueprint('auth', __name__, url_prefix='/auth')

@auth_bp.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    age = data.get('age')

    if not name or not email or not password:
        return jsonify({'message': 'Missing required fields'}), 400

    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
            existing_user = cursor.fetchone()
    finally:
        connection.close()

    if existing_user:
        return jsonify({'message': 'User already exists'}), 400

    password_hash = hashlib.sha256(password.encode()).hexdigest()

    connection = get_connection()
    is_sqlite = hasattr(connection, 'db_path')
    user_id = None
    
    try:
        with connection.cursor() as cursor:
            sql = "INSERT INTO users (name, email, password, age) VALUES (%s, %s, %s, %s)"
            cursor.execute(sql, (name, email, password_hash, age))
            
            if is_sqlite:
                cursor.execute("SELECT last_insert_rowid()")
                user_id = cursor.fetchone()['last_insert_rowid()']
            else:
                cursor.execute("SELECT LAST_INSERT_ID()")
                user_id = cursor.fetchone()['LAST_INSERT_ID()']
                
        connection.commit()
    finally:
        connection.close()

    token = hashlib.sha256(f"{email}{password_hash}{name}{user_id}".encode()).hexdigest()

    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("UPDATE users SET token = %s WHERE id = %s", (token, user_id))
        connection.commit()
    finally:
        connection.close()

    return jsonify({
        'message': 'User created successfully',
        'uid': str(user_id),
        'email': email,
        'name': name,
        'token': token
    }), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'message': 'Missing email or password'}), 400

    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
            user = cursor.fetchone()
    finally:
        connection.close()

    if not user:
        return jsonify({'message': 'Invalid credentials'}), 401

    password_hash = hashlib.sha256(password.encode()).hexdigest()
    if password_hash != user['password']:
        return jsonify({'message': 'Invalid credentials'}), 401

    token = hashlib.sha256(f"{email}{password_hash}{user['name']}{user['id']}".encode()).hexdigest()

    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("UPDATE users SET token = %s WHERE id = %s", (token, user['id']))
        connection.commit()
    finally:
        connection.close()

    return jsonify({
        'message': 'Signed in successfully',
        'uid': str(user['id']),
        'email': email,
        'name': user['name'],
        'token': token
    }), 200

@auth_bp.route('/signin', methods=['POST'])
def signin():
    return login()

@auth_bp.route('/validate', methods=['GET'])
def validate_token():
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'message': 'Invalid token'}), 401
    
    token = auth_header.split(' ')[1]

    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users WHERE token = %s", (token,))
            user = cursor.fetchone()

            if user:
                return jsonify({
                    'uid': str(user['id']),
                    'email': user['email'],
                    'name': user['name']
                }), 200
            else:
                return jsonify({'message': 'Invalid token'}), 401
    finally:
        connection.close()
