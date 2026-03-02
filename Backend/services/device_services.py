from firebase_admin import db

def start_device(user_id, temperature):
    ref = db.reference(f"devices/{user_id}")
    ref.update({
        "status": "running",
        "temperature": temperature
    })

    return {"message": "Device started", "temperature": temperature}


def stop_device(user_id):
    ref = db.reference(f"devices/{user_id}")
    ref.update({
        "status": "stopped"
    })

    return {"message": "Device stopped"}