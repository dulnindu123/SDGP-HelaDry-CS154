from flask import Blueprint, jsonify, g
from ..middleware.auth_middleware import firebase_required
from ..utils.responses import success, error
from firebase_admin import db

session_bp = Blueprint("session", __name__)


@session_bp.route("/my-sessions", methods=["GET"])
@firebase_required
def get_user_sessions():
    try:
        sessions_ref = db.reference("sessions")
        sessions = sessions_ref.get()

        if not sessions:
            return jsonify(success([])), 200

        user_sessions = [
            session
            for session in sessions.values()
            if session.get("user_id") == g.user_id
        ]

        return jsonify(success(user_sessions)), 200

    except Exception:
        return jsonify(error("Failed to fetch sessions")), 500