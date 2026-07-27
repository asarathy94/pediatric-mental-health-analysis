import csv
from collections import defaultdict

labels = {}
with open('docs/NSCH_2024_Survey_Labels_ID.csv', encoding='utf-8', newline='') as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        if len(row) >= 2:
            labels[row[0]] = row[1]

counts = defaultdict(lambda: defaultdict(int))

with open('data/raw/NSCH_2024_Survey_Data.csv', encoding='utf-8', newline='') as f:
    reader = csv.DictReader(f)
    for row in reader:
        for k, v in row.items():
            if v in {'90', '96', '99'}:
                counts[k][v] += 1

for k in sorted(counts, key=lambda k: (-sum(counts[k].values()), k))[:80]:
    total = sum(counts[k].values())
    print(f"{k}: {total} | {dict(counts[k])} | {labels.get(k, '')}")
