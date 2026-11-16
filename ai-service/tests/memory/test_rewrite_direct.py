import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from src.chat.chat_service import ChatService

svc = ChatService()

history = [
    {'role': 'USER', 'content': 'What is a physician assistant? Physician assistants are medical providers who are licensed to diagnose and treat illness and disease and to prescribe medication for patients'},
    {'role': 'ASSISTANT', 'content': 'Physician assistants are medical providers who are licensed to diagnose and treat illness and disease and to prescribe medication for patients'},
    {'role': 'USER', 'content': "What are the educational requirements required to become one?"},
    {'role': 'ASSISTANT', 'content': "Complete your bachelor degree... Apply to ARC-PA accredited physician assistant programs..."}
]

test_questions = [
    "What does it cost?",
    "What's the average starting salary in the UK?",
    "What about in the US?",
    "What is the PA average salary vs an RN?",
    "What the difference between a PA and a nurse practitioner?",
    "Do NPs or PAs make more?",
    "Is a PA above a NP?",
    "What is the fastest way to become a NP?",
    "How much longer does it take to become a doctor after being an NP?"
]

for q in test_questions:
    r = svc.condense_question(q, history, 'User asks about PA role, education, cost, salary')
    print(f'Q: {q}')
    print(f'R: {r}')
    print()