import os


class Config:
    DEBUG = os.getenv("FLASK_DEBUG", "True") == "True"

    FIREBASE_CERT_PATH = os.getenv(
        "FIREBASE_CERT_PATH",
        os.path.join(os.path.dirname(__file__), "firebase_key.json")
    )

    FIREBASE_DATABASE_URL = os.getenv(
        "FIREBASE_DATABASE_URL",
        "https://solar-dryer-iot-default-rtdb.asia-southeast1.firebasedatabase.app/"
    )