from flask import Flask, jsonify, render_template
import random
import threading
import time

app = Flask(__name__)

# State of the light
light_on = False

def random_turn_off():
    global light_on
    while True:
        if light_on:
            time.sleep(random.randint(5, 15))  # Random delay between 5 to 15 seconds
            light_on = False
            print("Light turned off by the service")

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/toggle', methods=['POST'])
def toggle_light():
    global light_on
    light_on = not light_on
    return jsonify({'light_on': light_on})

@app.route('/status', methods=['GET'])
def get_status():
    return jsonify({'light_on': light_on})

if __name__ == '__main__':
    # Start the random turn off thread
    threading.Thread(target=random_turn_off, daemon=True).start()
    app.run(debug=True, host='0.0.0.0') 