import json
import re

with open(r'C:\Users\umerm\AppData\Local\Pub\Cache\hosted\pub.dev\qcf_quran-0.0.5\lib\src\data\quran_text.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# find all items manually
matches = re.finditer(r'\{\s*"surah_number":\s*(\d+),\s*"verse_number":\s*(\d+),\s*"qcfData":\s*"(.*?)",\s*"content":\s*"(.*?)".*?\}', text, re.DOTALL)

sajdah_verses = {}
for m in matches:
    surah = int(m.group(1))
    verse = int(m.group(2))
    qcf = m.group(3).replace('\\n', '')
    content = m.group(4)
    if '\u06E4' in content:
        tokens = content.split(' ')
        # figure out which tokens have U+06E4
        sajdah_tokens = []
        for i, t in enumerate(tokens):
            if '\u06E4' in t:
                sajdah_tokens.append(i + 1) # 1-based token index
        sajdah_verses[(surah, verse)] = {
            'qcf_len': len(qcf),
            'content_tokens': len(tokens),
            'sajdah_token_indices': sajdah_tokens,
            'content': content
        }

for k, v in sajdah_verses.items():
    print(f"Surah {k[0]} Verse {k[1]}: tokens={v['content_tokens']} sajdah_tokens={v['sajdah_token_indices']} qcf_len={v['qcf_len']}")

