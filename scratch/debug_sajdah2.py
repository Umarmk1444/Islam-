import re

with open(r'C:\Users\umerm\AppData\Local\Pub\Cache\hosted\pub.dev\qcf_quran-0.0.5\lib\src\data\quran_text.dart', 'r', encoding='utf-8') as f:
    text = f.read()

def find_qcf(surah, verse):
    pattern = r'"surah_number":\s*' + str(surah) + r',\s*"verse_number":\s*' + str(verse) + r',\s*"qcfData":\s*"(.*?)",\s*"content":\s*"(.*?)"'
    match = re.search(pattern, text)
    if match:
        qcf = match.group(1).replace('\\n', '')
        content = match.group(2)
        print(f"Surah {surah} Verse {verse}:")
        print(f"Content: {content}")
        for i, char in enumerate(qcf):
            code = hex(ord(char))[2:].upper().zfill(4)
            print(f'Char {i}: {char} [U+{code}]')
        print("-" * 20)

find_qcf(96, 19)
find_qcf(32, 15)
