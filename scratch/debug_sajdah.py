import re

with open(r'C:\Users\umerm\AppData\Local\Pub\Cache\hosted\pub.dev\qcf_quran-0.0.5\lib\src\data\quran_text.dart', 'r', encoding='utf-8') as f:
    text = f.read()

def find_surah_verse(surah, verse):
    pattern = str(verse) + r':\s*\"(.*?)\"'
    surah_block = re.search(str(surah) + r':\s*\{(.*?)\}', text, re.DOTALL)
    if surah_block:
        verse_match = re.search(pattern, surah_block.group(1))
        if verse_match:
            qcf = verse_match.group(1)
            print(f'Surah {surah} Verse {verse}:')
            for i, char in enumerate(qcf):
                if char not in ['\n', '\r']:
                    code = hex(ord(char))[2:].upper().zfill(4)
                    print(f'Char {i}: {char} [U+{code}]')

find_surah_verse(96, 19)
find_surah_verse(32, 15)
