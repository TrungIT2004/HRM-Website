import sys
sys.stdout.reconfigure(encoding='utf-8')

import requests
import json

BASE_URL = "http://localhost:8000/api/v1"
SECRET = "hrm-internal-key-secure-2024"

headers = {
    "X-Internal-Secret": SECRET,
    "Content-Type": "application/json"
}

def test_conversational_memory():
    user_id = "EMP_TEST_001"
    print("\n=======================================================")
    print("🧠 BẮT ĐẦU TEST MULTI-TURN CONVERSATIONAL MEMORY")
    print("=======================================================")

    # ---------------------------------------------------------
    # LƯỢT 1: Câu hỏi mở đầu
    # ---------------------------------------------------------
    print("\n👉 [LƯỢT 1] Nhân viên hỏi câu đầu tiên:")
    q1 = "Quy định về việc kết hôn thì tôi được nghỉ mấy ngày?"
    print(f"❓ Câu hỏi: {q1}")

    res1 = requests.post(
        f"{BASE_URL}/chat/query",
        headers=headers,
        json={
            "question": q1,
            "user_id": user_id,
            "user_roles": ["ROLE_EMPLOYEE"],
            "department": "ALL",
            "top_k": 3
        }
    )
    assert res1.status_code == 200, f"Lượt 1 thất bại: {res1.text}"
    data1 = res1.json()

    conv_id = data1["conversation_id"]
    title = data1["title"]
    print(f"🆔 Conversation ID: {conv_id}")
    print(f"📌 Title: {title}")
    print(f"🤖 AI Trả Lời:\n{data1['answer']}\n")
    assert conv_id is not None, "Phải sinh ra conversation_id mới!"

    # ---------------------------------------------------------
    # LƯỢT 2: Câu hỏi nối tiếp (Có đại từ thay thế "trường hợp này")
    # ---------------------------------------------------------
    print("\n👉 [LƯỢT 2] Nhân viên hỏi nối tiếp (Test Kỹ thuật 1 Rewrite & Kỹ thuật 2 Context):")
    q2 = "Vậy tiền mừng của công ty cho trường hợp này là bao nhiêu?"
    print(f"❓ Câu hỏi nối tiếp: {q2}")

    res2 = requests.post(
        f"{BASE_URL}/chat/query",
        headers=headers,
        json={
            "question": q2,
            "conversation_id": conv_id,
            "user_id": user_id,
            "user_roles": ["ROLE_EMPLOYEE"],
            "department": "ALL",
            "top_k": 3
        }
    )
    assert res2.status_code == 200, f"Lượt 2 thất bại: {res2.text}"
    data2 = res2.json()

    print(f"🔄 Kỹ thuật 1 (Rewritten Query): '{data2['rewritten_query']}'")
    print(f"🤖 AI Trả Lời:\n{data2['answer']}\n")

    # Kiểm tra Kỹ thuật 1 đã đưa từ khóa "kết hôn" vào câu hỏi viết lại chưa
    assert "kết hôn" in data2["rewritten_query"].lower() or "cưới" in data2["rewritten_query"].lower(), \
        f"Kỹ thuật 1 thất bại: rewritten_query '{data2['rewritten_query']}' không chứa từ khóa kết hôn!"
    print("✅ KỸ THUẬT 1: Tái tạo câu hỏi độc lập thành công mỹ mãn!")

    # ---------------------------------------------------------
    # TEST 3: Kiểm tra API danh sách hội thoại của User
    # ---------------------------------------------------------
    print("\n📋 [TEST 3] Kiểm tra GET /api/v1/chat/conversations")
    res_list = requests.get(
        f"{BASE_URL}/chat/conversations",
        headers=headers,
        params={"user_id": user_id}
    )
    assert res_list.status_code == 200, f"Lỗi lấy danh sách hội thoại: {res_list.text}"
    conv_list = res_list.json()["conversations"]
    print(f"Số lượng cuộc hội thoại của user: {len(conv_list)}")
    matched_conv = next((c for c in conv_list if c["id"] == conv_id), None)
    assert matched_conv is not None, "Không tìm thấy conversation vừa tạo trong danh sách!"
    print(f"Tìm thấy conversation: {matched_conv['title']} (Tin nhắn: {matched_conv['message_count']})")
    assert matched_conv["message_count"] == 4, f"Mong đợi 4 messages, thực tế: {matched_conv['message_count']}"
    print("✅ Bảng chat_messages đã lưu đủ 4 tin nhắn (2 câu hỏi + 2 câu trả lời)!")

    # ---------------------------------------------------------
    # TEST 4: Kiểm tra API chi tiết tin nhắn trong hội thoại
    # ---------------------------------------------------------
    print("\n📜 [TEST 4] Kiểm tra GET /api/v1/chat/conversations/{conv_id}")
    res_detail = requests.get(
        f"{BASE_URL}/chat/conversations/{conv_id}",
        headers=headers,
        params={"user_id": user_id}
    )
    assert res_detail.status_code == 200, f"Lỗi lấy chi tiết tin nhắn: {res_detail.text}"
    detail_data = res_detail.json()
    messages = detail_data["messages"]
    print(f"Tổng số tin nhắn lấy về: {len(messages)}")
    for i, m in enumerate(messages):
        print(f"  [{i+1}] {m['sender_role']}: {m['content'][:80]}...")
    print("✅ Đã lấy chi tiết toàn bộ lịch sử tin nhắn thành công!")

    # ---------------------------------------------------------
    # TEST 5: Dọn dẹp hội thoại test
    # ---------------------------------------------------------
    print("\n🗑️ [TEST 5] Kiểm tra DELETE /api/v1/chat/conversations/{conv_id}")
    res_del = requests.delete(
        f"{BASE_URL}/chat/conversations/{conv_id}",
        headers=headers,
        params={"user_id": user_id}
    )
    assert res_del.status_code == 200, f"Lỗi xóa hội thoại: {res_del.text}"
    print("✅ Đã xóa cuộc hội thoại test thành công (CASCADE dọn sạch messages)!")

    print("\n🎉 TOÀN BỘ CÁC BÀI KIỂM THỬ CONVERSATIONAL MEMORY ĐÃ ĐẠT 100%!")

if __name__ == "__main__":
    test_conversational_memory()
