from flask import Flask, jsonify

from .config import Config
from .extensions import init_firebase

from .routes.device_routes import device_bp
from .routes.session_routes import session_bp


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    try:
        # Initialize Firebase
        init_firebase(
            app.config["FIREBASE_CERT_PATH"],
            app.config["FIREBASE_DATABASE_URL"]
        )
    except Exception as e:
        raise RuntimeError(f"Failed to initialize Firebase: {str(e)}")

    # Register Blueprints
    app.register_blueprint(device_bp, url_prefix="/device")
    app.register_blueprint(session_bp, url_prefix="/session")

    # Health check route
    @app.route("/")
    def health_check():
        return jsonify({
            "status": "running",
            "service": "HelaDry Backend"
        }), 200

    # Global error handler
    @app.errorhandler(Exception)
    def handle_exception(e):
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

    return app


app = create_app()


if __name__ == "__main__":
    app.run(debug=app.config["DEBUG"])