from flask import Flask,request,jsonify, Response
from collections import OrderedDict

print("file1 is exec")

app = Flask(__name__)
app.config['APP_NAME'] = 'MB Flask Website'
app.json.sort_keys = False

next_id = 4

contacts = [
            {"id": 1, "name": "One", "phone": "+91 0000000001", "email": "One@example.com"},
            {"id": 2, "name": "Two", "phone": "+91 0000000002", "email": "Two@example.com"},
            {"id": 3, "name": "Three", "phone": "+91 0000000003", "email": "Three@example.com"}
        ]

@app.context_processor
def inject_app_name():
    return dict(app_name=app.config['APP_NAME'])

@app.route('/')
def hello_route():

    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>{app.config['APP_NAME']}</title>
    </head>
    <body>
        <h1>Hello, World! We are learning Flask</h1>
    </body>
    </html>
    """
    return Response(html, mimetype='text/html')

#    print("Hello, World!, we are learning flask")
#    return "<h1> Hello, World!, we are learning flask </h1>"

@app.get("/contacts")
def list_contacts():
    return jsonify(contacts)

@app.get("/contacts/<contact_id>")
def get_contact(contact_id):
    for contact in contacts:
      if contact["id"] == int(contact_id):
        return jsonify(contacts)
    return {"error": "Contact not found"}, 404

@app.post("/contacts")
def new_contact():
    global next_id

    new_contact = OrderedDict([
        ("id", next_id),
        ("name", request.json["name"]),
        ("phone", request.json["phone"]),
        ("email", request.json["email"]),
    ])

    contacts.append(new_contact)
    next_id += 1

    return jsonify({
        "message": "New contact created successfully as below:",
        "data": new_contact
    }), 201

@app.put("/contacts/<contact_id>")
def update_contact(contact_id):
    for contact in contacts:
      if contact["id"] == int(contact_id):
            contact["name"] = request.json.get("name", contact["name"])
            contact["phone"] = request.json.get("phone", contact.get("phone"))
            contact["email"] = request.json.get("email", contact["email"])
        
            return jsonify({
            "message": "Contact updated successfully as below:",
            "data": contact
    }), 201
    return {"error": "Contact not found"}, 404

@app.delete("/contacts/<contact_id>")
def delete_contact(contact_id):
    for contact in contacts:
        if contact["id"] == int(contact_id):
            contacts.remove(contact)
            return {"message": "Contact deleted", "contact": contact}
    return {"error": "Contact not found"}, 404

if __name__ == "__main__":
    app.run(debug=True)

