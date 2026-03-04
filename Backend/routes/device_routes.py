from flask import Blueprint, request, jsonify,g
from ..middleware.auth_middleware import firebase_required
from ..services.device_service import start_device, stop_device
from ..utils.validators import validate_temperature
from ..utils.responses import success, error
from ..services.device_service import start_device, stop_device, get_user_devices, register_device

device_bp = Blueprint("device", __name__)


@device_bp.route("/register", methods=["POST"])
@firebase_required
def register():
    try:
        data = request.get_json()

        if not data:
            return jsonify(error("Request body is required")), 400

        device_id = data.get("device_id")
        device_name = data.get("device_name")

        if not device_id:
            return jsonify(error("device_id is required")), 400

        result = register_device(g.user_id, device_id, device_name)

        if "error" in result:
            return jsonify(error(result["error"])), 400

        return jsonify(success(result)), 201

    except Exception as e:
        return jsonify(error(str(e))), 500


@device_bp.route("/start", methods=["POST"])
@firebase_required
def start():
    try:
        data = request.get_json()

        if not data:
            return jsonify(error("Request body is required")), 400

        device_id = data.get("device_id")
        temperature = data.get("temperature")

        if not device_id:
            return jsonify(error("device_id is required")), 400

        valid, message = validate_temperature(temperature)
        if not valid:
            return jsonify(error(message)), 400

        result = start_device(g.user_id, device_id, temperature)

        if "error" in result:
            return jsonify(error(result["error"])), 403

        return jsonify(success(result)), 200

    except Exception as e:
        return jsonify(error(str(e))), 500


@device_bp.route("/stop", methods=["POST"])
@firebase_required
def stop():
    try:
        data = request.get_json()

        if not data:
            return jsonify(error("Request body is required")), 400

        device_id = data.get("device_id")

        if not device_id:
            return jsonify(error("device_id is required")), 400

        result = stop_device(g.user_id, device_id)

        if "error" in result:
            return jsonify(error(result["error"])), 403

        return jsonify(success(result)), 200

    except Exception as e:
        return jsonify(error(str(e))), 500
    

@device_bp.route("/list", methods=["GET"])
@firebase_required
def list_devices():
    try:
        result = get_user_devices(g.user_id)

        if isinstance(result, dict) and "error" in result:
            return jsonify(error(result["error"])), 500

        return jsonify(success(result)), 200

    except Exception:
        return jsonify(error("Failed to fetch devices")), 500