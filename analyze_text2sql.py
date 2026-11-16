import json
data = [json.loads(line) for line in open('C:/Users/ad/Desktop/HRM/ai-service/test_v2/text2sql/benchmarks/hrm_db_only.jsonl', encoding='utf-8')]
print('Total questions:', len(data))
routes = {}
for q in data:
    r = q.get('metadata', {}).get('expected_route', 'unknown')
    routes[r] = routes.get(r, 0) + 1
print('Routes:', routes)