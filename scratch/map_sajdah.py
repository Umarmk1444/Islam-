import json
import re

with open(r'C:\Users\umerm\AppData\Local\Pub\Cache\hosted\pub.dev\qcf_quran-0.0.5\lib\src\data\quran_text.dart', 'r', encoding='utf-8') as f:
    text = f.read()

matches = re.finditer(r'\{\s*"surah_number":\s*(\d+),\s*"verse_number":\s*(\d+),\s*"qcfData":\s*"(.*?)",\s*"content":\s*"(.*?)".*?\}', text, re.DOTALL)

for m in matches:
    surah = int(m.group(1))
    verse = int(m.group(2))
    content = m.group(4)
    if '\u06E4' in content:
        qcf = m.group(3).replace('\\n', '')
        print(f"Surah {surah} Verse {verse}")
        print("Tokens:")
        tokens = content.split(' ')
        for i, t in enumerate(tokens):
            print(f"  Token {i+1}: {t}")
        print("QCF Glyphs:")
        for i, c in enumerate(qcf):
            code = hex(ord(c))[2:].upper().zfill(4)
            print(f"  QCF {i+1}: {c} [U+{code}]")
        print("-" * 20)
