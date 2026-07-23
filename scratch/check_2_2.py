import json, re
with open(r'C:\Users\umerm\AppData\Local\Pub\Cache\hosted\pub.dev\qcf_quran-0.0.5\lib\src\data\quran_text.dart', 'r', encoding='utf-8') as f:
    text = f.read()

m = re.search(r'\{\s*"surah_number":\s*2,\s*"verse_number":\s*2,\s*"qcfData":\s*"(.*?)",\s*"content":\s*"(.*?)".*?\}', text, re.DOTALL)
if m:
    qcf = m.group(1).replace('\\n', '')
    content = m.group(2)
    tokens = content.split(' ')
    print('QCF length:', len(qcf))
    print('Tokens length:', len(tokens))
    for t in tokens:
        print(t)
