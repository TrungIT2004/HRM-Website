import sys
sys.stdout.reconfigure(encoding='utf-8')

import requests
import json

BASE_URL = "http://localhost:8000/api/v1"
SECRET = "hrm-internal-key-secure-2024"

def test_chat_queries():
    print("\n=======================================================")
    print("🔒 1. TEST BẢO MẬT: GỌI API KHÔNG CÓ X-Internal-Secret")
    print("=======================================================")
    res_no_sec = requests.post(f"{BASE_URL}/chat/query", json={"question": "Xin chào"})
    print(f"Status: {res_no_sec.status_code}")
    print(f"Response: {res_no_sec.text}")
    assert res_no_sec.status_code == 403, "Phải chặn 403 Forbidden nếu không có X-Internal-Secret!"
    print("✅ Đã chặn thành công truy cập lạ từ bên ngoài!")

    headers = {
        "X-Internal-Secret": SECRET,
        "Content-Type": "application/json"
    }

    test_questions = [
        {
            "title": "HỎI ĐÁP PHÚC LỢI KẾT HÔN",
            "question": "Tôi kết hôn được nghỉ mấy ngày có lương và công ty mừng bao nhiêu tiền?",
            "role": "ROLE_EMPLOYEE"
        },
        {
            "title": "HỎI ĐÁP BẢNG BIỂU XỬ PHẠT ĐI LÀM MUỘN",
            "question": "Nếu tôi đi muộn trên 30 phút lần thứ hai thì bị xử phạt thế nào?",
            "role": "ROLE_EMPLOYEE"
        },
        {
            "title": "HỎI ĐÁP ĐIỀU KHOẢN MỚI CẬP NHẬT (REMOTE WORK)",
            "question": "Quy định làm việc tại nhà (Work from Home) của công ty như thế nào?",
            "role": "ROLE_EMPLOYEE"
        },
        {
            "title": "TEST CHỐNG ẢO GIÁC (CÂU HỎI KHÔNG CÓ TRONG QUY ĐỊNH)",
            "question": "Công ty có chính sách thưởng Tết bằng xe máy SH cho nhân viên xuất sắc không?",
            "role": "ROLE_EMPLOYEE"
        }
    ]

    for item in test_questions:
        print(f"\n=======================================================")
        print(f"💬 TEST: {item['title']}")
        print(f"❓ Câu hỏi: {item['question']}")
        print("=======================================================")
        
        payload = {
            "question": item["question"],
            "user_roles": [item["role"]],
            "department": "ALL",
            "top_k": 3
        }

        res = requests.post(f"{BASE_URL}/chat/query", headers=headers, json=payload)
        assert res.status_code == 200, f"Query failed with status {res.status_code}: {res.text}"

        data = res.json()
        print("\n🤖 [AI TRẢ LỜI]:")
        print(data["answer"])

        print(f"\n📚 [TRÍCH DẪN NGUỒN] (Độ tin cậy: {data['confidence']}):")
        if data["citations"]:
            for c in data["citations"]:
                print(f"  • File: {c['document_name']} | Trang: {c['page_number']} | Điểm khớp: {c['relevance_score']}")
                print(f"    Ngữ cảnh: {c['breadcrumb']}")
                print(f"    Link xem file: {c['file_url']}")
        else:
            print("  (Không có trích dẫn do câu hỏi ngoài phạm vi)")

    print("\n🎉 TOÀN BỘ CÁC BÀI TEST CHATBOT RAG ĐÃ THÀNH CÔNG RỰC RỠ!")

if __name__ == "__main__":
    test_chat_queries()
