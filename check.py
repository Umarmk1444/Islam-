import re

with open('lib/controllers/quran_audio_controller.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

count = 0
for i, line in enumerate(lines):
    clean_line = re.sub(r'//.*', '', line)
    clean_line = re.sub(r"'[^']*'", '', clean_line)
    clean_line = re.sub(r'"[^"]*"', '', clean_line)
    
    count += clean_line.count('{')
    count -= clean_line.count('}')
    
    if count < 0:
        print(f'Negative count at line {i+1}: {line}')
        break

print(f'Final brace count: {count}')
