from flask import Flask, render_template, request, jsonify
import time

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/chat', methods=['POST'])
def chat():
    data = request.json
    user_message = data.get('message', '').strip()
    
    if not user_message:
        return jsonify({"error": "Message is required"}), 400
        
    # Simulate AI thinking delay
    time.sleep(1)
    
    # Simple simulated AI response logic
    msg = user_message.lower()
    if "hello" in msg or "hi" in msg:
        reply = "Hello! I am a simulated AI running on your Python Flask backend. How can I assist you today?"
    elif "help" in msg:
        reply = "I can currently echo your messages or have simple predefined interactions. This is a functional boilerplate for you to connect an LLM API!"
    elif "joke" in msg:
        reply = "Why do programmers prefer dark mode? Because light attracts bugs!"
    elif "weather" in msg:
        reply = "I'm not connected to a weather API yet, but it's always sunny in the cloud!"
    else:
        reply = f"You said: '{user_message}'. I am processing this locally on Flask!"

    return jsonify({"reply": reply})

if __name__ == '__main__':
    print("Starting AI Chat Web App Backend on http://127.0.0.1:5000")
    app.run(debug=True, port=5000)