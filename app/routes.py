from flask import Blueprint, render_template, session
import uuid

bp = Blueprint("main", __name__)

@bp.route("/")
def index():
    if "player_id" not in session:
        session["player_id"] = str(uuid.uuid4())
    return render_template("index.html", player_id=session["player_id"])
