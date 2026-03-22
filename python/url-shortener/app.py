from flask import Flask
app = Flask(__name__)

@app.route('/<short_url>')
def redirect_url(short_url):
    return 'Redirecting and tracking clicks...'

if __name__ == '__main__':
    app.run()