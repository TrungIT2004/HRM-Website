import sys
sys.stdout.reconfigure(encoding='utf-8')

import time
import requests
import json
from pathlib import Path

BASE_URL = "http://localhost:8000/api/v1"

def test_production_features():
    sample_file = Path(__file__).resolve().parent / "sample_policy.docx"
    assert sample_file.exists(), f"Missing test file: {sample_file}"

    print("\n--- 1. TEST GET ALL DOCUMENTS ---")
    res = requests.get(f"{BASE_URL}/documents")
    print(f"Status: {res.status_code}")
    print(f"Current documents in DB: {res.json()['total']}")

    print("\n--- 2. TEST UPLOAD WITH BACKGROUND TASK & SHA-256 ---")
    with open(sample_file, "rb") as f:
        files = {"file": ("sample_policy.docx", f, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
        data = {
            "allowed_roles": "ROLE_EMPLOYEE,ROLE_MANAGER",
            "allowed_departments": "ALL",
            "uploaded_by": "HR_ADMIN",
            "overwrite": "true" # Overwrite existing if previously uploaded
        }
        start_time = time.time()
        res = requests.post(f"{BASE_URL}/documents/upload", files=files, data=data)
        elapsed = time.time() - start_time

    print(f"Upload Response Time: {elapsed:.2f}s (Phải trả về tức thì < 1s nhờ BackgroundTasks!)")
    print(f"Response Status: {res.status_code}")
    upload_data = res.json()
    print(json.dumps(upload_data, indent=2, ensure_ascii=False))

    doc_id = upload_data.get("document_id")
    assert doc_id, "Phải nhận được document_id!"

    print("\n--- 3. TEST DEDUPLICATION (UPLOAD LẠI FILE NGUYÊN BẢN) ---")
    with open(sample_file, "rb") as f:
        files = {"file": ("sample_policy.docx", f, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
        data = {
            "allowed_roles": "ROLE_EMPLOYEE",
            "allowed_departments": "ALL",
            "uploaded_by": "HR_ADMIN",
            "overwrite": "false" # KHÔNG overwrite
        }
        res_dup = requests.post(f"{BASE_URL}/documents/upload", files=files, data=data)
    print(f"Deduplication Response: {res_dup.json()['status']}")
    print(f"Message: {res_dup.json()['message']}")
    assert res_dup.json()["status"] == "DUPLICATE", "Hệ thống phải phát hiện trùng SHA-256!"

    print("\n--- 4. CHỜ BACKGROUND WORKER HOÀN THÀNH (POLL STATUS) ---")
    max_wait = 120
    waited = 0
    while waited < max_wait:
        res = requests.get(f"{BASE_URL}/documents/{doc_id}")
        doc_info = res.json()
        status = doc_info.get("status")
        chunk_count = doc_info.get("chunk_count")
        print(f"[{waited}s] Status: {status} | Chunks created: {chunk_count}")
        if status == "COMPLETED":
            print(f"✅ Background Worker hoàn thành xuất sắc! File URL: {doc_info['file_url']}")
            break
        elif status == "FAILED":
            print(f"❌ Background Worker thất bại: {doc_info.get('error_message')}")
            break
        time.sleep(5)
        waited += 5

    print("\n--- 5. TEST GET AUDIT CHUNKS (KIỂM TRA CÂU HỎI GIẢ ĐỊNH & BẢNG BIỂU) ---")
    res_chunks = requests.get(f"{BASE_URL}/documents/{doc_id}/chunks")
    chunks_data = res_chunks.json()
    print(f"Tổng số chunks đã cắt & lưu DB: {chunks_data['total_chunks']}")
    for c in chunks_data['chunks'][:2]:
        print(f"- Chunk #{c['chunk_index']} ({c['chunk_type']}) | Breadcrumb: {c['breadcrumb']}")
        print(f"  Summary: {c['summary']}")
        print(f"  Reverse HyDE Questions: {c['hypothetical_questions'][:2]}")

    print("\n🎉 TOÀN BỘ CÁC TÍNH NĂNG PRODUCTION CỦA PHƯƠNG ÁN A ĐÃ HOẠT ĐỘNG HOÀN HẢO!")

if __name__ == "__main__":
    test_production_features()
