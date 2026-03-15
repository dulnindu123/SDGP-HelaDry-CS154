from firebase_admin import db
from datetime import datetime, timezone
from .session_service import create_session, end_session


def start_device(user_id, device_id, temperature):
    try:
        device_ref = db.reference(f"devices/{device_id}")
        device = device_ref.get()

        # Check device exists
        if not device:
            return {"error": "Device not found"}

        # Check ownership
        if device.get("owner") != user_id:
            return {"error": "Unauthorized access to device"}

        # Prevent multiple active sessions
        sessions_ref = db.reference("sessions")
        existing_sessions = sessions_ref.order_by_child("device_id").equal_to(device_id).get()

        if existing_sessions:
            for session in existing_sessions.values():
                if (
                    session.get("user_id") == user_id
                    and session.get("status") == "active"
                ):
                    return {"error": "Device already has an active session"}

        timestamp = datetime.now(timezone.utc).isoformat()

        # Send start command to device
        device_ref.update({
            "command": {
                "type": "start",
                "target_temperature": temperature,
                "timestamp": timestamp,
                "source": "cloud"
            },
            "updated_at": timestamp
        })

        # Create session
        session_result = create_session(user_id, device_id, temperature)

        if "error" in session_result:
            return session_result

        return {
            "message": "Start command sent",
            "device_id": device_id,
            "session": session_result
        }

    except Exception:
        return {"error": "Failed to send start command"}


def stop_device(user_id, device_id):
    try:
        device_ref = db.reference(f"devices/{device_id}")
        device = device_ref.get()

        # Check device exists
        if not device:
            return {"error": "Device not found"}

        # Check ownership
        if device.get("owner") != user_id:
            return {"error": "Unauthorized access to device"}

        timestamp = datetime.now(timezone.utc).isoformat()

        # Send stop command to device
        device_ref.update({
            "command": {
                "type": "stop",
                "timestamp": timestamp,
                "source": "cloud"
            },
            "updated_at": timestamp
        })

        # End active session
        session_result = end_session(user_id, device_id)

        if "error" in session_result:
            return session_result

        return {
            "message": "Stop command sent",
            "device_id": device_id,
            "session": session_result
        }

    except Exception:
        return {"error": "Failed to send stop command"}
    
def get_user_devices(user_id):
    try:
        devices_ref = db.reference("devices")
        devices = devices_ref.get()

        if not devices:
            return []

        user_devices = []

        for device_id, device_data in devices.items():
            if device_data.get("owner") == user_id:
                user_devices.append({
                    "device_id": device_id,
                    "status": device_data.get("status", "unknown"),
                    "last_updated": device_data.get("updated_at"),
                    "last_seen": device_data.get("last_seen")
                })

        return user_devices

    except Exception:
        return {"error": "Failed to fetch devices"}
    

def register_device(user_id, device_id, device_name=None):
    try:
        device_ref = db.reference(f"devices/{device_id}")
        device = device_ref.get()

        # Check if device already exists
        if device:
            return {"error": "Device already registered"}

        timestamp = datetime.now(timezone.utc).isoformat()

        device_ref.set({
            "device_id": device_id,
            "name": device_name if device_name else "HelaDry Device",
            "owner": user_id,
            "status": "idle",
            "created_at": timestamp,
            "updated_at": timestamp,
            "command": None,
            "last_seen": None
        })

        return {
            "message": "Device registered successfully",
            "device_id": device_id
        }

    except Exception:
        return {"error": "Failed to register device"}