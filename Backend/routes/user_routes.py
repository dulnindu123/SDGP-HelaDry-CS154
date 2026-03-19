from flask import Blueprint, jsonify, g
from firebase_admin import auth

from ..middleware.auth_middleware import firebase_required
from ..services.user_service import delete_user_data
from ..utils.responses import success, error


user_bp = Blueprint("user", __name__)


@user_bp.route("/delete-account", methods=["DELETE"])
@firebase_required
def delete_account():
    """
    Permanently delete the authenticated user's data and Firebase Auth account.
    """
    user_id = g.user_id

    try:
        # 1. Delete all user data from Realtime Database (sessions, devices)
        result = delete_user_data(user_id)

        if "error" in result:
            return jsonify(error(result["error"])), 500

        # 2. Delete the Firebase Auth account
        auth.delete_user(user_id)

        return jsonify(success(
            data={
                "deleted_sessions": result["deleted_sessions"],
                "deleted_devices": result["deleted_devices"]
            },
            message="Account and all associated data deleted successfully"
        )), 200

    except Exception as e:
        return jsonify(error(f"Failed to delete account: {str(e)}")), 500
