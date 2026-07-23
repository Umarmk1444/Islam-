text = '(}ء″}&—ء^ˎ[)ء﴿×`؟ء`{﴿؟ء—ـ*﴿$ء$}&*،'
b = text.encode('utf-8')
try:
    print("UTF-16 LE:", b.decode('utf-16le', errors='replace'))
except Exception as e:
    pass
try:
    print("UTF-16 BE:", b.decode('utf-16be', errors='replace'))
except Exception as e:
    pass
