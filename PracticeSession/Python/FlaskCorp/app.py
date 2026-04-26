from flask import Flask, request, redirect, url_for, render_template
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"]="sqlite:///db.sqlite3"
db=SQLAlchemy(app)

class User(db.Model):
    id = db.Column(db.Integer,primary_key=True)
    name = db.Column(db.String(100))
    date_joined = db.Column(db.DateTime)

@app.shell_context_processor
def make_shell_context():
    return {"db": db, "User": User}

@app.route("/")
def home():
    return "Flask Running"
if  __name__ =="__main__":
    app.run(debug=True,port=5005)