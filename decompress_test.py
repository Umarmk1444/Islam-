import sqlite3
import zlib
import base64

conn = sqlite3.connect('c:/islam/assets/muslim_house.db')
# We need to ensure we don't accidentally cast to TEXT in sqlite3
cursor = conn.cursor()
cursor.execute("SELECT story FROM roqua WHERE id = 38")
row = cursor.fetchone()

data = row[0]
if isinstance(data, str):
    print("It was read as string by python sqlite. Length:", len(data))
    raw_bytes = data.encode('utf-8')
    raw_bytes_utf16 = data.encode('utf-16le')
else:
    print("It was read as bytes. Length:", len(data))
    raw_bytes = data

try:
    print("Trying zlib on utf-8...")
    print(zlib.decompress(raw_bytes).decode('utf-8'))
except Exception as e:
    pass

try:
    print("Trying zlib on utf-16le...")
    print(zlib.decompress(raw_bytes_utf16).decode('utf-8'))
except Exception as e:
    pass

try:
    import lzma
    print("Trying lzma...")
    print(lzma.decompress(raw_bytes).decode('utf-8'))
except Exception as e:
    pass
