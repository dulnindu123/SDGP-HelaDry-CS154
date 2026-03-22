import firebase_admin
from firebase_admin import credentials

def init_firebase(cert_path, database_url):
    if not firebase_admin._apps:
        cred = credentials.Certificate(cert_path)

        firebase_admin.initialize_app(cred, {
            "databaseURL": database_url
        })