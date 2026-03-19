from firebase_admin import db


def delete_user_data(user_id):
    """
    Delete all sessions and devices belonging to a user from Firebase RTDB.
    """
    try:
        deleted_sessions = 0
        deleted_devices = 0

        # 1. Delete all sessions belonging to the user
        sessions_ref = db.reference("sessions")
        all_sessions = sessions_ref.order_by_child("user_id").equal_to(user_id).get()

        if all_sessions:
            for session_id in all_sessions:
                db.reference(f"sessions/{session_id}").delete()
                deleted_sessions += 1

        # 2. Delete all devices owned by the user
        devices_ref = db.reference("devices")
        all_devices = devices_ref.get()

        if all_devices:
            for device_id, device_data in all_devices.items():
                if device_data.get("owner") == user_id:
                    db.reference(f"devices/{device_id}").delete()
                    deleted_devices += 1

        return {
            "message": "User data deleted successfully",
            "deleted_sessions": deleted_sessions,
            "deleted_devices": deleted_devices
        }

    except Exception as e:
        return {"error": f"Failed to delete user data: {str(e)}"}
