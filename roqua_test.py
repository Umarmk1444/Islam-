import sqlite3

conn = sqlite3.connect('c:/islam/assets/muslim_house.db')
rows = conn.execute("SELECT id, level, roqua FROM roqua").fetchall()

with open('roqua_test.txt', 'w', encoding='utf-8') as f:
    for row in rows:
        f.write(f"ID: {row[0]} | Level: {row[1]} | Title: {row[2]}\n")
