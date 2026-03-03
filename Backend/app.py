from flask import Flask

from .config import Config
from .extensions import init_firebase

from .routes.device_routes import device_bp
from .routes.session_routes import session_bp  


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize Firebase properly
    init_firebase(
        app.config["FIREBASE_CERT_PATH"],
        app.config["FIREBASE_DATABASE_URL"]
    )

    # Register Blueprints
    app.register_blueprint(device_bp, url_prefix="/device")
    app.register_blueprint(session_bp, url_prefix="/session")  # remove if unused

    return app


app = create_app()

if __name__ == "__main__":
    app.run(debug=app.config["DEBUG"])