text = '(}ء″}&—ء^ˎ[)ء﴿×`؟ء`{﴿؟ء—ـ*﴿$ء$}&*،'
result = ''
for c in text:
    # shift by 0x0600
    shifted = chr(ord(c) + 0x0600)
    result += shifted
print("Shifted by 0x0600:", result)

result2 = ''
for c in text:
    if ord(c) < 0x0600:
        shifted = chr(ord(c) + 0x0600)
    else:
        shifted = c
    result2 += shifted
print("Selective shift:", result2)
