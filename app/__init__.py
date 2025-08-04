from flask import Flask
from flask_socketio import SocketIO
from . import routes as app_routes

import os

# Redis como message queue
socketio = SocketIO(cors_allowed_origins="*", message_queue=os.getenv("REDIS_URL", "redis://localhost:6379/0"))

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'useless-secret-key'

    socketio.init_app(app)

    with app.app_context():
        from . import routes as app_routes
        from . import socket_events
        app.register_blueprint(app_routes.bp)

    return app
