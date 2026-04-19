from flask import Flask, request, jsonify , render_template

app = Flask(__name__)
#app = Flask(__name__, template_folder='fullstackweb/templates')

@app.route('/')
def home_page():
    return render_template('index.html', first_name = 'Mueen')

@app.route('/about')
def about_page():
    return render_template('about.html')

@app.route('/contact')
def contact_page():
    return render_template('contact.html')

@app.route('/form')
def form_page():
    return render_template('form.html')

@app.post('/create-account')
def create_account():
    first_name = request.form.get('first_name')
    last_name = request.form.get('last_name')
    email = request.form.get('email')
    return render_template('createaccount.html', first_name = first_name, last_name = last_name, email = email)

if __name__ == '__main__':
    app.run(debug=True, host='127.0.0.1',port=4000)