from flaskcorp import Flask,request,redirect,url_for

app = Flask (__name__)

@app.route("/")
def index():
    return"<h1>Hello</h1>"

@app.route("/home", methods=["GET", "POST"])
def home():
    return "<h1>Welcome to the Home Page</h1>"

@app.route("/loginrd", methods = ["GET", "POST"])
def loginrd():
    if request.method == "POST":
        username: str | None = request.form.get("username")
        if username:
            return redirect(url_for("home"))

@app.route("/loginform", methods = ["GET", "POST"])
def loginform():
    if request.method == "POST":
        username = request.form.get("username")
        if username:
            return redirect(url_for("home")) 
    return """
<h1> Login Page</h1>
<form method="POST">
<input type="text" name="username" placeholder="Enter your username"
<button type="submit">Login</button>
</form>
"""
                        
@app.route("/json")
def json():
    return {"mykey":"myvalue","mylist":[1, 2, 3]}

@app.route("/dynamic",defaults={"user_input":"default"})

@app.route("/dynamic/<user_input>")
def dynamic(user_input):
    return f"<h1> The user entered : {user_input}</h1>"

@app.route("/query")
def query() :
    hello = request.args.get("hello")
    world = request.args.get("world")
    help = request.args.get("help")
    return f"<h1> The query string contains : {hello} and {world}</h1>"
app.run()