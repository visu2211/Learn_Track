# database.py
#
# Single entry point for getting a DB connection: get_connection().
# Every blueprint calls this instead of talking to pymysql/sqlite3 directly.
#
# Why: local dev and the free-tier deploy don't have a MySQL server available,
# so this tries real MySQL first (for a proper deployment) and transparently
# falls back to a local SQLite file otherwise. The SQLiteConnection/SQLiteCursor
# wrapper classes below exist purely so the fallback speaks the exact same
# cursor API pymysql does (%s placeholders, .execute()/.fetchone()/.fetchall())
# - callers never need an if/else for which database they're actually on.

import pymysql
import sqlite3
import os
from config import Config

def get_connection():
    try:
        # Try MySQL first
        connection = pymysql.connect(
            host=Config.MYSQL_HOST,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            db=Config.MYSQL_DB,
            cursorclass=pymysql.cursors.DictCursor
        )
        return connection
    except Exception as e:
        print(f"MySQL connection failed: {e}")
        print("Falling back to SQLite...")
        # Fallback to SQLite
        db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'learntrack.db')
        
        # Create a custom connection class for SQLite that mimics the PyMySQL API
        class SQLiteConnection:
            def __init__(self, db_path):
                self.db_path = db_path
                self.conn = None
                
            def __enter__(self):
                return self
                
            def __exit__(self, exc_type, exc_val, exc_tb):
                if self.conn:
                    self.conn.close()
                    
            def cursor(self):
                self.conn = sqlite3.connect(self.db_path)
                self.conn.row_factory = sqlite3.Row
                return SQLiteCursor(self.conn.cursor())
                
            def commit(self):
                if self.conn:
                    self.conn.commit()
                    
            def close(self):
                if self.conn:
                    self.conn.close()
                    self.conn = None
        
        # Custom cursor that mimics PyMySQL's cursor
        class SQLiteCursor:
            def __init__(self, cursor):
                self.cursor = cursor
                
            def execute(self, query, args=None):
                # Convert MySQL-style placeholders to SQLite style
                if args:
                    query = query.replace("%s", "?")
                return self.cursor.execute(query, args if args else ())
                
            def fetchone(self):
                row = self.cursor.fetchone()
                if row:
                    return {k: row[k] for k in row.keys()}
                return None
                
            def fetchall(self):
                rows = self.cursor.fetchall()
                return [{k: row[k] for k in row.keys()} for row in rows]
                
            def close(self):
                self.cursor.close()
                
            def __enter__(self):
                return self
                
            def __exit__(self, exc_type, exc_val, exc_tb):
                self.close()
                
        return SQLiteConnection(db_path)
