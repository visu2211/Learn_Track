from database import get_connection
import os
import sqlite3

def init_database():
    connection = get_connection()
    is_sqlite = hasattr(connection, 'db_path')
    
    try:
        with connection.cursor() as cursor:
            if is_sqlite:
                sql = """
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password TEXT NOT NULL,
                    age INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            else:
                sql = """
                CREATE TABLE IF NOT EXISTS users (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(255) NOT NULL,
                    email VARCHAR(255) NOT NULL UNIQUE,
                    password VARCHAR(255) NOT NULL,
                    age INT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            cursor.execute(sql)

            if is_sqlite:
                user_data_sql = """
                CREATE TABLE IF NOT EXISTS user_data (
                    user_id INTEGER NOT NULL,
                    data_type TEXT NOT NULL,
                    data TEXT,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (user_id, data_type)
                )
                """
            else:
                user_data_sql = """
                CREATE TABLE IF NOT EXISTS user_data (
                    user_id INT NOT NULL,
                    data_type VARCHAR(20) NOT NULL,
                    data LONGTEXT,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (user_id, data_type)
                )
                """
            cursor.execute(user_data_sql)

        connection.commit()
        print("Database initialized successfully")
        
        if is_sqlite:
            with connection.cursor() as cursor:
                cursor.execute("SELECT * FROM users WHERE email = 'test@example.com'")
                if not cursor.fetchone():
                    cursor.execute(
                        "INSERT INTO users (name, email, password, age) VALUES (?, ?, ?, ?)",
                        ("Test User", "test@example.com", "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8", 25)
                    )
                    connection.commit()
                    print("Created test user: test@example.com / password")
        
    except Exception as e:
        print(f"Error initializing database: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    init_database() 