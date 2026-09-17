import sys
sys.stdout.reconfigure(encoding='utf-8')

import time
import requests
import json
from pathlib import Path
import docx

BASE_URL = "http://localhost:8000/api/v1"

def test_update_workflow():
    test_dir = Path(__file__).resolve().parent
    original_file = test_dir / "sample_policy.docx"
    updated_file = test_dir / "sample_policy_v2.docx"

    print("\n--- 1. LẤY TÀI LIỆU HIỆN CÓ ĐỂ CẬP NHẬT ---")
    res = requests.get(f"{BASE_URL}/documents")
    docs = res.json()["documents"]
    assert len(docs) > 0, "Không có tài liệu nào trong DB để test update!"
    target_doc = docs[0]
    doc_id = target_doc["id"]
    old_hash = target_doc["file_hash"]
    print(f"Target Document ID: {doc_id}")
    print(f"Tên tài liệu cũ: {target_doc['file_name']}")
    print(f"Mã SHA-256 cũ: {old_hash}")

    print("\n--- 2. TEST UPDATE VỚI FILE Y HỆT (UNCHANGED) ---")
    # Sử dụng đúng file đang lưu trong DB để test UNCHANGED
    current_file = updated_file if target_doc["file_name"] == "sample_policy_v2.docx" else original_file
    with open(current_file, "rb") as f:
        files = {"file": (target_doc["file_name"], f, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
        res_same = requests.put(f"{BASE_URL}/documents/{doc_id}", files=files)
    print(f"Kết quả: {res_same.json()['status']}")
    print(f"Thông báo: {res_same.json()['message']}")
    assert res_same.json()["status"] == "UNCHANGED", "File không đổi phải trả về UNCHANGED!"

    print("\n--- 3. TẠO FILE MỚI ĐÃ CHỈNH SỬA NỘI DUNG (V2) ---")
    # Tạo bản V2: Sửa mức phạt đi muộn từ 50.000đ thành 500.000đ
    doc = docx.Document(original_file)
    # Thêm một điều khoản mới vào cuối
    doc.add_heading("CHƯƠNG IV: QUY ĐỊNH LÀM VIỆC TỪ XA (REMOTE WORK 2024)", level=1)
    doc.add_paragraph("Điều 4: Nhân viên được phép đăng ký làm việc tại nhà (Work from Home) tối đa 2 ngày/tháng với điều kiện hoàn thành 100% KPI.")
    doc.save(updated_file)
    print(f"Đã tạo file V2 với điều khoản Remote Work mới: {updated_file}")

    print("\n--- 4. GỬI REQUEST PUT ĐỂ THAY THẾ TÀI LIỆU ---")
    with open(updated_file, "rb") as f:
        files = {"file": ("sample_policy_v2.docx", f, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
        data = {
            "allowed_roles": "ROLE_EMPLOYEE,ROLE_MANAGER,ROLE_DIRECTOR",
            "allowed_departments": "ALL",
            "updated_by": "HR_DIRECTOR"
        }
        res_put = requests.put(f"{BASE_URL}/documents/{doc_id}", files=files, data=data)

    print(f"Status Code: {res_put.status_code}")
    print(json.dumps(res_put.json(), indent=2, ensure_ascii=False))
    assert res_put.json()["status"] == "PROCESSING"

    print("\n--- 5. CHỜ BACKGROUND WORKER HOÀN THÀNH XỬ LÝ FILE V2 ---")
    max_wait = 120
    waited = 0
    while waited < max_wait:
        res = requests.get(f"{BASE_URL}/documents/{doc_id}")
        doc_info = res.json()
        status = doc_info.get("status")
        chunk_count = doc_info.get("chunk_count")
        print(f"[{waited}s] Status: {status} | Chunks count: {chunk_count}")
        if status == "COMPLETED":
            print(f"✅ Đã thay thế thành công tài liệu! Mã SHA-256 mới: {doc_info['file_hash']}")
            assert doc_info['file_hash'] != old_hash, "SHA-256 phải thay đổi sau khi cập nhật!"
            break
        elif status == "FAILED":
            print(f"❌ Cập nhật thất bại: {doc_info.get('error_message')}")
            break
        time.sleep(5)
        waited += 5

    print("\n--- 6. KIỂM TRA CHUNKS MỚI TRONG DATABASE ---")
    res_chunks = requests.get(f"{BASE_URL}/documents/{doc_id}/chunks")
    chunks = res_chunks.json()["chunks"]
    print(f"Tổng số chunks sau khi update: {len(chunks)}")
    
    # Tìm xem có chunk quy định Remote Work mới không
    remote_chunks = [c for c in chunks if "CHƯƠNG IV" in c["breadcrumb"] or "Remote" in c["content"]]
    assert len(remote_chunks) > 0, "Phải tìm thấy chunk Remote Work mới trong DB!"
    print(f"✅ Tìm thấy Chunk mới cập nhật: {remote_chunks[0]['breadcrumb']}")
    print(f"Nội dung: {remote_chunks[0]['content']}")

    print("\n🎉 TEST CẬP NHẬT THAY THẾ FILE (IN-PLACE REPLACEMENT) THÀNH CÔNG 100%!")

if __name__ == "__main__":
    test_update_workflow()
