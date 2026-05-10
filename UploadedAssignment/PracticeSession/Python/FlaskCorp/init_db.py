from database import get_db_connection

connection = get_db_connection()

connection.execute("""
CREATE TABLE IF NOT EXISTS students (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   name TEXT NOT NULL,
                   email TEXT NOT NULL,
                   course TEXT NOT NULL)
                   """)
connection.commit()
connection.close()

print("Database and table created successfully")