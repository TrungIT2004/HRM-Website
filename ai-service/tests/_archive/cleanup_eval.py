"""Xoa du lieu test EVAL_ con ket. Chay: python tests/cleanup_eval.py"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from src.db.session import get_db_connection

c = get_db_connection()
cur = c.cursor()
cur.execute("DELETE FROM document_chunks WHERE breadcrumb LIKE 'EVAL_STD|%%'")
print("xoa chunks:", cur.rowcount)
cur.execute("DELETE FROM knowledge_documents WHERE file_name LIKE 'EVAL_STD%%'")
print("xoa docs:", cur.rowcount)
c.commit()
c.close()
print("OK")
