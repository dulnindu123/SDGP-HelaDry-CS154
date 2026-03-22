from firebase_admin import db
from datetime import datetime, timezone
import uuid


def create_session(user_id, device_id, target_temperature, batch_details=None):
    try:
        session_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()

        ref = db.reference(f"sessions/{session_id}")

        # Start with required fields
        session_data = {
            "session_id": session_id,
            "user_id": user_id,
            "device_id": device_id,
            "target_temperature": target_temperature,
            "start_time": timestamp,
            "end_time": None,
            "status": "active"
        }

        # Add extra batch details if provided
        if batch_details:
            for key in [
                "crop_name", "crop_emoji", "weight_kg", "trays", "duration", "start_date", "status", "batch_name"
            ]:
                if key in batch_details:
                    session_data[key] = batch_details[key]

        ref.set(session_data)

        return {
            "session_id": session_id,
            "start_time": timestamp
        }

    except Exception:
        return {"error": "Failed to create session"}


def end_session(user_id, device_id):
    try:
       
        sessions_ref = db.reference("sessions")
        sessions = sessions_ref.order_by_child("device_id").equal_to(device_id).get()

        if not sessions:
            return {"error": "Active session not found"}

        for session_id, session_data in sessions.items():
            if (
                session_data.get("user_id") == user_id
                and session_data.get("status") == "active"
            ):
                timestamp = datetime.now(timezone.utc).isoformat()

                db.reference(f"sessions/{session_id}").update({
                    "end_time": timestamp,
                    "end_date": timestamp,
                    "status": "completed"
                })

                # Fetch and return the updated session
                updated_session = db.reference(f"sessions/{session_id}").get()
                
                return {
                    "session_id": session_id,
                    "end_time": timestamp,
                    "session": updated_session
                }

        return {"error": "Active session not found"}

    except Exception:
        return {"error": "Failed to end session"}