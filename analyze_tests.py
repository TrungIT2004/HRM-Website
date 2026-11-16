import json

# Analyze DB_ONLY_HYBRID questions
data = json.load(open('C:/Users/ad/Desktop/HRM/ai-service/tests/db_only_hybrid_questions.json', encoding='utf-8'))
print('Tables:', len(data['tables']))
total = sum(len(t['questions']) for t in data['tables'])
print('Total questions:', total)
for t in data['tables']:
    routes = {}
    for q in t['questions']:
        routes[q.get('expected_route', 'unknown')] = routes.get(q.get('expected_route', 'unknown'), 0) + 1
    print(f'  {t["table"]}: {len(t["questions"])} questions, routes: {routes}')

print()

# Analyze memory dataset
data = json.load(open('C:/Users/ad/Desktop/HRM/ai-service/tests/tests/DOC_ONLY/datasets/doc_only_memory_20x12.json', encoding='utf-8'))
print('Memory dataset - Total turns:', len(data))
convs = set(r['conversation_id'] for r in data)
print('Memory dataset - Conversations:', len(convs))
turns_per_conv = {}
for r in data:
    turns_per_conv[r['conversation_id']] = turns_per_conv.get(r['conversation_id'], 0) + 1
print('Memory dataset - Turns per conversation:', sorted(turns_per_conv.values()))

# Analyze doc_only_with_answers
data = json.load(open('C:/Users/ad/Desktop/HRM/ai-service/tests/db_only_hybrid_questions_with_answers.json', encoding='utf-8'))
print('DB_ONLY_HYBRID with answers - Tables:', len(data['tables']))
total = sum(len(t['questions']) for t in data['tables'])
print('DB_ONLY_HYBRID with answers - Total questions:', total)
for t in data['tables']:
    routes = {}
    for q in t['questions']:
        routes[q.get('expected_route', 'unknown')] = routes.get(q.get('expected_route', 'unknown'), 0) + 1
    print(f'  {t["table"]}: {len(t["questions"])} questions, routes: {routes}')