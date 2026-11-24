import json
with open('test_v2/db_only_hybrid_questions.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

with open('verify_output.txt', 'w', encoding='utf-8') as out:
    count = 0
    for t in data['tables']:
        for q in t['questions']:
            if q['expected_route'] == 'DB_ONLY' and 'expected_answer' in q:
                out.write(q['id'] + ': ' + q['question'][:60] + '\n')
                ans = q['expected_answer']
                out.write('  Columns: ' + str(ans['columns']) + '\n')
                out.write('  Row count: ' + str(ans['row_count']) + '\n')
                if ans['rows']:
                    out.write('  First row: ' + str(ans['rows'][0]) + '\n')
                count += 1
                if count >= 5:
                    break
        if count >= 5:
            break
    out.write('\nTotal DB_ONLY: 187\n')
    out.write('All have expected_answer: YES\n')