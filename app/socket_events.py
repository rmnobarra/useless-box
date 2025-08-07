from flask import session
from flask_socketio import emit, join_room
from . import socketio
from .metrics import toggle_light_counter, players_connected_gauge

from .game import Game

game = Game()

@socketio.on('connect')
def handle_connect():
    players_connected_gauge.inc()
    player_id = session.get("player_id")
    join_room("players")
    emit("game_state", game.get_state(), broadcast=True)
    
@socketio.on("toggle_light")
def handle_toggle_light():
    player_id = session.get("player_id")
    state = game.toggle_light(player_id)
    emit("game_state", state, broadcast=True)

@socketio.on('disconnect')
def handle_disconnect():
    players_connected_gauge.dec()

@socketio.on("toggle_light")
def handle_toggle_light():
    player_id = session.get("player_id")
    toggle_light_counter.inc()
    state = game.toggle_light(player_id)
    emit("game_state", state, broadcast=True)
