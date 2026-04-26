from flaskcorp import Flask,render_template, request, redirect
from database import get_db_connection

app = Flask(__name__)

@app.route("/")
def index():
    connection = get_db_connection()

    students = connection.execute(
        "SELECT * FROM students"
    ).fetchall()
    connection.close()

    return render_template("index.html",students=students)


@app.route("/add",methods = ["GET","POST"])

def add_student():
    if request.method == "POST":
        name = request.form["name"]
        email = request.form["email"]
        course = request.form["course"]

        connection = get_db_connection()

        connection.execute(
            "INSERT INTO students (name,email,course) values (?,?,?)",
            (name,email,course)
        )
        connection.commit()
        connection.close()

        return redirect("/")
    return render_template("add_student.html")


@app.route("/delete/<int:id>")
def delete_student(id):
    connection = get_db_connection()

    connection.execute(
        "DELETE FROM students where id = ?",(id,)
    )

    connection.commit()
    connection.close

    return redirect("/")

if __name__ == "__main__":
    app.run(debug=True)