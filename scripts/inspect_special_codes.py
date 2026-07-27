import csv
from collections import defaultdict

fn = 'data/raw/NSCH_2024_Survey_Data.csv'

codes = {'90', '96', '99'}
counts = defaultdict(int)
rows = 0
with open(fn, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        rows += 1
        for k, v in row.items():
            if v in codes:
                counts[k] += 1
        if rows >= 20000:
            break

for k, c in sorted(counts.items(), key=lambda x: -x[1])[:50]:
    print(f"{k}: {c}")
print('rows checked:', rows)
