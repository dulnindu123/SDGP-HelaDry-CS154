from flask import Blueprint, request, jsonify
from ..middleware.auth_middleware import firebase_required
from ..services.device_services import start_device, stop_device
from ..utils.validators import validate_temperature
from ..utils.responses import success, error

device_bp = Blueprint("device", __name__)

@device_bp.route("/start", methods=["POST"])
@firebase_required
def start():
    data = request.json
    device_id = data.get("device_id")
    temperature = data.get("temperature")

    if not device_id:
        return jsonify(error("device_id is required")), 400

    valid, message = validate_temperature(temperature)
    if not valid:
        return jsonify(error(message)), 400

    result = start_device(request.user_id, device_id, temperature)
    return jsonify(success(result))


@device_bp.route("/stop", methods=["POST"])
@firebase_required
def stop():
    data = request.json
    device_id = data.get("device_id")

    if not device_id:
        return jsonify(error("device_id is required")), 400

    result = stop_device(request.user_id, device_id)
    return jsonify(success(result))