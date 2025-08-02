from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class PlayerScore(db.Model):
    id = db.Column(db.String(36), primary_key=True)
    score = db.Column(db.Float, default=0.0)
