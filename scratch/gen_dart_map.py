import json
import re

with open(r'C:\Users\umerm\AppData\Local\Pub\Cache\hosted\pub.dev\qcf_quran-0.0.5\lib\src\data\quran_text.dart', 'r', encoding='utf-8') as f:
    text = f.read()

matches = re.finditer(r'\{\s*"surah_number":\s*(\d+),\s*"verse_number":\s*(\d+),\s*"qcfData":\s*"(.*?)",\s*"content":\s*"(.*?)".*?\}', text, re.DOTALL)

print('  static final Map<String, Set<int>> _sajdahLinePositions = {')
for m in matches:
    surah = int(m.group(1))
    verse = int(m.group(2))
    content = m.group(4)
    if '\u06E4' in content:
        qcf = m.group(3).replace('\\n', '')
        
        # Calculate exactly which QCF indices correspond to \u06E4
        tokens = content.split(' ')
        qcf_idx = 1
        sajdah_indices = []
        for t in tokens:
            qcf_idx += 1 # base word
            
            # extra glyphs in this token
            for c in t:
                # \u06E4 sajdah line
                if c == '\u06E4':
                    sajdah_indices.append(qcf_idx)
                    qcf_idx += 1
                # stop marks
                elif c in ['\u06E9', '\u06DE', '\u06D6', '\u06D7', '\u06D8', '\u06D9', '\u06DA', '\u06DB', '\u06DC', '\u06E2']:
                    qcf_idx += 1
        
        indices_str = ', '.join(str(x) for x in sajdah_indices)
        print(f"    '{surah}_{verse}': {{{indices_str}}},")

print('  };')
