from flask import Blueprint, render_template, session, Response
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

import uuid

bp = Blueprint("main", __name__)

@bp.route("/")
def index():
    if "player_id" not in session:
        session["player_id"] = str(uuid.uuid4())
    return render_template("index.html", player_id=session["player_id"])

@bp.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)