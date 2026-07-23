import re
with open(r'C:\Users\umerm\AppData\Local\Pub\Cache\hosted\pub.dev\qcf_quran-0.0.5\lib\src\data\quran_text.dart', 'r', encoding='utf-8') as f:
    text = f.read()

matches = re.finditer(r'"surah_number":\s*(\d+),\s*"verse_number":\s*(\d+).*?"content":\s*"([^"]*?\u06E4[^"]*?)"', text, re.DOTALL)
count = 0
for match in matches:
    print(f'Surah {match.group(1)} Verse {match.group(2)}: {match.group(3)}')
    count += 1
print(f'Total matches: {count}')
