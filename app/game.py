import time
import redis
import os

from .metrics import light_duration_histogram

class Game:
    def __init__(self):
        self.redis = redis.from_url(os.getenv("REDIS_URL", "redis://localhost:6379"))

    def toggle_light(self, player_id):
        now = time.time()
        light_on = self.redis.get("light_on") == b"True"

        if light_on:
            owner_id = self.redis.get("owner_id").decode()
            light_on_since = float(self.redis.get("light_on_since"))
            duration = now - light_on_since
            self._add_score(owner_id, duration)
            light_duration_histogram.observe(duration)
            self.redis.set("light_on", "False")
            self.redis.delete("owner_id")
            self.redis.delete("light_on_since")
        else:
            self.redis.set("light_on", "True")
            self.redis.set("owner_id", player_id)
            self.redis.set("light_on_since", now)

        return self.get_state()

    def _add_score(self, player_id, duration):
        self.redis.zincrby("scoreboard", duration, player_id)

    def get_state(self):
        owner_id = self.redis.get("owner_id")
        return {
            "light_on": self.redis.get("light_on") == b"True",
            "owner_id": owner_id.decode() if owner_id else None,
            "scoreboard": self.get_scoreboard()
        }

    def get_scoreboard(self):
        scores = self.redis.zrevrange("scoreboard", 0, -1, withscores=True)
        return [{"player_id": player.decode(), "score": round(score, 2)} for player, score in scores]
