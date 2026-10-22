import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from tests.test_qrecc_memory_client import load_qrecc_data
turns = load_qrecc_data()
print(f'Loaded {len(turns)} turns')
print('Sample:')
for t in turns[:3]:
    print(f'  Conv {t.conversation_no}, Turn {t.turn_no}: {t.question[:60]}...')
convs = set(t.conversation_no for t in turns)
print(f'Conversations: {len(convs)}')