from functools import wraps
from flask import request, jsonify, g
from firebase_admin import auth
from ..utils.responses import error


def firebase_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization")

        if not auth_header:
            return jsonify(error("Authorization token missing")), 401

        parts = auth_header.split(" ")

        if len(parts) != 2 or parts[0] != "Bearer":
            return jsonify(error("Invalid Authorization header format")), 401

        token = parts[1]

        try:
            decoded_token = auth.verify_id_token(token)
            g.user_id = decoded_token["uid"]

        except Exception:
            return jsonify(error("Invalid or expired Firebase token")), 401

        return f(*args, **kwargs)

    return wrapper