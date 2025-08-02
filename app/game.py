import time
from threading import Lock
from .models import db, PlayerScore

class Game:
    def __init__(self):
        self.light_on = False
        self.owner_id = None
        self.light_on_since = None
        self.lock = Lock()

    def toggle_light(self, player_id):
        from flask import current_app
        with current_app.app_context(), self.lock:
            now = time.time()
            if self.light_on:
                if self.owner_id:
                    duration = now - self.light_on_since
                    self._add_score(self.owner_id, duration)
                self.light_on = False
                self.owner_id = None
                self.light_on_since = None
            else:
                self.light_on = True
                self.owner_id = player_id
                self.light_on_since = now

            return self.get_state()

    def _add_score(self, player_id, duration):
        score = PlayerScore.query.get(player_id)
        if not score:
            score = PlayerScore(id=player_id, score=0)
            db.session.add(score)
        score.score += duration
        db.session.commit()

    def get_state(self):
        return {
            "light_on": self.light_on,
            "owner_id": self.owner_id,
            "scoreboard": self.get_scoreboard()
        }

    def get_scoreboard(self):
        scores = PlayerScore.query.order_by(PlayerScore.score.desc()).all()
        return [{"player_id": s.id, "score": round(s.score, 2)} for s in scores]
