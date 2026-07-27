import csv

fn = 'data/raw/NSCH_2024_Survey_Data.csv'

total = 0.0
count = 0
with open(fn, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        val = row.get('FWC')
        if val is None or val == '':
            continue
        try:
            total += float(val)
            count += 1
        except Exception:
            try:
                total += float(val.replace(',',''))
                count += 1
            except Exception:
                continue

print(total)
print('rows_with_fwc=', count)
