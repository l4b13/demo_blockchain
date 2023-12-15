import hashlib

wstr = "NEFU_DEMO"
w = hashlib.sha224(wstr.encode("utf-8")).hexdigest()
f = "Ethereum" # ответ
c = 0
for i in range(1000000,10000000):
    wfx = w + f + str(i)
    str1 = hashlib.sha3_384(wfx.encode("utf-8")).hexdigest()
    if str1[-4:] == "abba":
        wfx2 = w + f + str(i+1)
        str2 = hashlib.sha3_384(wfx2.encode("utf-8")).hexdigest()
        c += 1
        if str2 == "552142abf201c3fbd698df8b275e3f39afb3e9badeffb431282fe5d89b9fa4bff2849e69479c62c52cfd736c8237050b":
            print(str1)
            print(i)
            print("yes")

print(w)
print(f)
print("sha3_384")
print(c)