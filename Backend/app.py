import sqlite3
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_bcrypt import Bcrypt
import jwt
import datetime
from functools import wraps
import smtplib
from email.mime.text import MIMEText

def get_db():
    conn = sqlite3.connect("database.db")
    conn.row_factory = sqlite3.Row
    return conn

def create_user_table():
    db = get_db()
    cursor = db.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        is_verified INTEGER DEFAULT 0
    )
    """)

    db.commit()
    db.close()

create_user_table()

app = Flask(__name__)
CORS(app)
bcrypt = Bcrypt(app)

SECRET_KEY = "supersecretkey"
EMAIL_SENDER = "@gmail.com"
EMAIL_PASSWORD = ""

#Sending verification Email

def send_verification_email(email, link):
    msg = MIMEText(f"Click this link to verify your account:\n\n{link}")
    msg["Subject"] = "Verify Your Account"
    msg["From"] = EMAIL_SENDER
    msg["To"] = email

    server = smtplib.SMTP("smtp.gmail.com", 587)
    server.starttls()
    server.login(EMAIL_SENDER, EMAIL_PASSWORD)
    server.sendmail(EMAIL_SENDER, email, msg.as_string())
    server.quit()


#registering a new user 

@app.route("/register", methods=["POST"])
def register():
    data = request.json

    name = data["name"]
    email = data["email"]
    password = data["password"]

    hashed_password = bcrypt.generate_password_hash(password).decode("utf-8")

    db = get_db()
    cursor = db.cursor()

    try:
        cursor.execute(
            "INSERT INTO users (name, email, password) VALUES (?, ?, ?)",
            (name, email, hashed_password)
        )
        db.commit()

        # Generate verification token
        verification_token = jwt.encode({
            "email": email,
            "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
        }, SECRET_KEY, algorithm="HS256")

        verification_link = f"http://127.0.0.1:5000/verify/{verification_token}"

        # Send email
        send_verification_email(email, verification_link)

        return jsonify({
            "message": "Registration successful. Check your email to verify account."
        })

    except:
        return jsonify({"error": "Email already exists"}), 400
    
#Verifying the email

@app.route("/verify/<token>")
def verify_email(token):
    try:
        data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        email = data["email"]

        db = get_db()
        cursor = db.cursor()

        cursor.execute("UPDATE users SET is_verified=1 WHERE email=?", (email,))
        db.commit()

        return """
        <h2>Email Verified Successfully!</h2>
        <p>You can now login using the mobile app.</p>
        """

    except:
        return jsonify({"error": "Invalid or expired verification link"}), 400


    


@app.route("/login", methods=["POST"])
def login():
    data = request.json

    email = data["email"]
    password = data["password"]

    db = get_db()
    cursor = db.cursor()

    cursor.execute("SELECT * FROM users WHERE email=?", (email,))
    user = cursor.fetchone()

    if user and bcrypt.check_password_hash(user["password"], password):

        token = jwt.encode({
            "user_id": user["id"],
            "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        }, SECRET_KEY, algorithm="HS256")

        return jsonify({
            "token": token,
            "user": {
                "id": user["id"],
                "name": user["name"],
                "email": user["email"]
            }
        })

    return jsonify({"error": "Invalid credentials"}), 401

def token_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):

        auth_header = request.headers.get("Authorization")

        if not auth_header:
            return jsonify({"error": "Token missing"}), 403

        try:
            # Remove "Bearer " from token
            token = auth_header.split(" ")[1]

            jwt.decode(token, SECRET_KEY, algorithms=["HS256"])

        except Exception as e:
            return jsonify({"error": "Invalid token"}), 403

        return f(*args, **kwargs)

    return wrapper

@app.route("/profile")
@token_required
def profile():
    return jsonify({"message": "Access granted"})

if __name__ == "__main__":
    app.run(debug=True)