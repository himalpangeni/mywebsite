from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return 'AI Chat Web App Interface'

if __name__ == '__main__':
    app.run()