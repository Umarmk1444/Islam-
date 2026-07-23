cipher = '(}ء″}&—ء^ˎ[)'
plain = 'بسم الله الرحمن الرحيم'
for c, p in zip(cipher, plain):
    print(f"{c} ({ord(c)}) -> {p} ({ord(p)}) : diff {ord(c) - ord(p)}")
