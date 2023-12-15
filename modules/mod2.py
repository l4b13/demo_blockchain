import hashlib
import json

with open('jsonnn.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
block = [data[0]]
del data[0]

while True:
    index = -1
    for i in range(len(data)):
        if block[0]["pre_hash"] == data[i]["hash"]:
            index = i
            break
    if index > -1:
        block.insert(0, data[index])
        del data[index]
    else:
        break

while True:
    index = -1
    for i in range(len(data)):
        if block[-1]['hash'] == data[i]['pre_hash']:
            index = i
            break
    if index > -1:
        block.append(data[index])
        del data[index]
    else:
        break

print(block)

mer = [block]
c = len(block)
while len(mer[-1]) > 1:
    if len(mer[-1]) % 2 == 1:
        mer[-1].append(mer[-1][-1])
    arr = []
    for i in range(0, len(mer[-1]), 2):
        t = mer[-1][i]["hash"] + mer[-1][i + 1]["hash"]
        arr.append({"hash": hashlib.sha224(t.encode("utf-8")).hexdigest()})
        c+=1
    mer.append(arr)



print(block[0]["hash"])
print(c)
print(len(mer))
print(mer[-1][-1]["hash"])