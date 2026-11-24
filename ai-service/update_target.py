import os
import json
from datetime import date, datetime, time
from decimal import Decimal

with open('query_results_fixed5.json', 'r', encoding='utf-8') as f:
    query_results = json.load(f)

with open('test_v2/db_only_hybrid_questions.json', 'r', encoding='utf-8') as f:
    target = json.load(f)

results = query_results['results']

# Update target with actual results
updated = 0
for t in target['tables']:
    for q in t['questions']:
        if q['expected_route'] == 'DB_ONLY' and q['id'] in results:
            q['expected_answer'] = results[q['id']]
            updated += 1

print(f'Updated {updated} questions')

with open('test_v2/db_only_hybrid_questions.json', 'w', encoding='utf-8') as f:
    json.dump(target, f, ensure_ascii=False, indent=2)

print('Done')