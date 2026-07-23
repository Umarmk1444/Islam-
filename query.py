import sqlite3

conn = sqlite3.connect('c:/islam/assets/muslim_house.db')
cursor = conn.cursor()

def dump_schema(table_name):
    print(f"--- Schema for {table_name} ---")
    rows = cursor.execute(f"PRAGMA table_info({table_name})").fetchall()
    for r in rows:
        print(r)
    
    print(f"--- First row for {table_name} ---")
    try:
        row = cursor.execute(f"SELECT * FROM {table_name} LIMIT 1").fetchone()
        print(row)
    except Exception as e:
        print(e)

dump_schema('quiz')
dump_schema('quizQuestions')
