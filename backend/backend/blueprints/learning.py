# blueprints/learning.py
#
# Courses / learning paths / streak data, all stored in ONE generic table:
# user_data(user_id, data_type, data JSON). data_type is 'courses' | 'paths'
# | 'streak'. Rather than a dedicated SQL table+columns per feature, each
# row's `data` column just holds whatever JSON blob the Flutter app already
# sends - the backend doesn't need to understand the shape of a "learning
# path," it just stores and returns it per user. This keeps the schema simple
# and means adding a new piece of trackable state doesn't require a migration,
# at the cost of not being able to query/filter on its contents in SQL.

import json
from flask import Blueprint, request, jsonify
from database import get_connection

learning_bp = Blueprint('learning', __name__, url_prefix='/users')

DEFAULT_STREAK = {
    'currentStreak': 0,
    'longestStreak': 0,
    'totalDays': 0,
    'weekProgress': 0.0,
    'days': [
        {'day': 'Mon', 'completed': False},
        {'day': 'Tue', 'completed': False},
        {'day': 'Wed', 'completed': False},
        {'day': 'Thu', 'completed': False},
        {'day': 'Fri', 'completed': False},
    ],
}


def _require_auth():
    auth_header = request.headers.get('Authorization')
    return bool(auth_header and auth_header.startswith('Bearer '))


def _get_data(user_id, data_type, default):
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT data FROM user_data WHERE user_id = %s AND data_type = %s",
                (user_id, data_type),
            )
            row = cursor.fetchone()
            if row and row.get('data'):
                return json.loads(row['data'])
            return default
    finally:
        connection.close()


def _save_data(user_id, data_type, value):
    connection = get_connection()
    is_sqlite = hasattr(connection, 'db_path')
    payload = json.dumps(value)
    try:
        with connection.cursor() as cursor:
            if is_sqlite:
                cursor.execute(
                    """INSERT INTO user_data (user_id, data_type, data)
                       VALUES (%s, %s, %s)
                       ON CONFLICT(user_id, data_type) DO UPDATE SET data = excluded.data""",
                    (user_id, data_type, payload),
                )
            else:
                cursor.execute(
                    """INSERT INTO user_data (user_id, data_type, data)
                       VALUES (%s, %s, %s)
                       ON DUPLICATE KEY UPDATE data = VALUES(data)""",
                    (user_id, data_type, payload),
                )
        connection.commit()
    finally:
        connection.close()


@learning_bp.route('/<user_id>/courses', methods=['GET'])
def get_courses(user_id):
    if not _require_auth():
        return jsonify({'message': 'Unauthorized access'}), 401
    return jsonify(_get_data(user_id, 'courses', [])), 200


@learning_bp.route('/<user_id>/courses', methods=['POST'])
def save_courses(user_id):
    if not _require_auth():
        return jsonify({'message': 'Unauthorized access'}), 401
    body = request.get_json(silent=True) or {}
    courses = body.get('courses', [])
    _save_data(user_id, 'courses', courses)
    return jsonify({'message': 'Courses saved'}), 200


@learning_bp.route('/<user_id>/paths', methods=['GET'])
def get_paths(user_id):
    if not _require_auth():
        return jsonify({'message': 'Unauthorized access'}), 401
    return jsonify(_get_data(user_id, 'paths', [])), 200


@learning_bp.route('/<user_id>/paths', methods=['POST'])
def save_paths(user_id):
    if not _require_auth():
        return jsonify({'message': 'Unauthorized access'}), 401
    body = request.get_json(silent=True) or {}
    if 'paths' in body:
        # Bulk replace (LearningService.saveLearningPaths)
        paths = body.get('paths', [])
        _save_data(user_id, 'paths', paths)
    else:
        # Single new path (LearningService._saveLearningPath)
        paths = _get_data(user_id, 'paths', [])
        paths.append(body)
        _save_data(user_id, 'paths', paths)
    return jsonify({'message': 'Paths saved'}), 201


@learning_bp.route('/<user_id>/streak', methods=['GET'])
def get_streak(user_id):
    if not _require_auth():
        return jsonify({'message': 'Unauthorized access'}), 401
    return jsonify(_get_data(user_id, 'streak', DEFAULT_STREAK)), 200


@learning_bp.route('/<user_id>/streak', methods=['POST'])
def save_streak(user_id):
    if not _require_auth():
        return jsonify({'message': 'Unauthorized access'}), 401
    body = request.get_json(silent=True) or {}
    streak_data = body.get('streak_data')
    if streak_data is None:
        return jsonify({'message': 'Missing streak_data'}), 400
    _save_data(user_id, 'streak', streak_data)
    return jsonify({'message': 'Streak updated'}), 200
