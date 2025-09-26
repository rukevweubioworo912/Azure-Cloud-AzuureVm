from flask import Flask, render_template, jsonify, request

app = Flask(__name__)
leaderboard = []

@app.route('/')
def game():
    
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)
