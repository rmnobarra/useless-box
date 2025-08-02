from flask import Flask
from flask_socketio import SocketIO
from .models import db
from . import routes as app_routes

import os

# Redis como message queue
socketio = SocketIO(cors_allowed_origins="*", message_queue=os.getenv("REDIS_URL", "redis://localhost:6379/0"))

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'useless-secret-key'
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///useless.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)
    socketio.init_app(app)

    with app.app_context():
        from . import routes as app_routes
        from . import socket_events
        db.create_all()
        app.register_blueprint(app_routes.bp)

    return app
