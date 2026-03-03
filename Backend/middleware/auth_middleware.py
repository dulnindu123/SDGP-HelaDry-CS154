from functools import wraps
from flask import request, jsonify
from firebase_admin import auth

def firebase_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization")

        if not auth_header:
            return jsonify({"error": "Token missing"}), 403

        # safer header validation
        parts = auth_header.split(" ")

        if len(parts) != 2 or parts[0] != "Bearer":
            return jsonify({"error": "Invalid Authorization header"}), 403

        token = parts[1]

        try:
            decoded_token = auth.verify_id_token(token)
            request.user_id = decoded_token["uid"]
        except Exception:
            return jsonify({"error": "Invalid Firebase token"}), 403

        return f(*args, **kwargs)

    return wrapper