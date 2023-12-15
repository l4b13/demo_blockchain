import json
import hashlib

with open('tx.json', 'r') as f:
    data = json.load(f)

chain = [data[0]]
del data[0]

while True:
    index = -1
    for i in range(len(data)):
        if data[i]['hash'] == chain[0]['pre_hash']:
            index = i
            break
    if index > -1:
        chain.insert(0, data[index])
        del data[index]
    else:
        break

while True:
    index = -1
    for i in range(len(data)):
        if data[i]['pre_hash'] == chain[-1]['hash']:
            index = i
            break
    if index > -1:
        chain.append(data[index])
        del data[index]
    else:
        break

# print(chain)

merkl = [chain]
count = len(chain)
while len(merkl[-1]) >= 2:
    if len(merkl[-1]) % 2 != 0:
        merkl[-1].append(merkl[-1][-1])
    p = []
    for i in range(0, len(merkl[-1]), 2):
        count += 1
        p.append(
            {'hash': hashlib.sha384((merkl[-1][i]['hash'] + merkl[-1][i + 1]['hash']).encode('utf-8')).hexdigest()})
    merkl.append(p)

for i in merkl:
    print(i)

print('Количество листьев:', count)
print('Количество уровней', len(merkl))
print('Значение TopHash:', merkl[-1][-1]['hash'])