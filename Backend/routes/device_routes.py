from flask import Blueprint, request, jsonify
from ..middleware.auth_middleware import firebase_required
from ..services.device_service import start_device
from ..utils.validators import validate_temperature
from ..utils.responses import success, error

device_bp = Blueprint("device", __name__)

@device_bp.route("/start", methods=["POST"])
@firebase_required
def start():
    data = request.json
    temperature = data.get("temperature")

    valid, message = validate_temperature(temperature)
    if not valid:
        return jsonify(error(message)), 400

    result = start_device(request.user_id, temperature)
    return jsonify(success(result))


@device_bp.route("/stop", methods=["POST"])
@firebase_required
def stop():
    result = stop_device(request.user_id)
    return jsonify(success(result))