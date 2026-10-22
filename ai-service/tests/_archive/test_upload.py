import sys
sys.stdout.reconfigure(encoding='utf-8')

import requests
from pathlib import Path
import json

def test_upload():
    # Sử dụng file word mẫu đã sinh ra từ trước
    file_path = Path(__file__).resolve().parent / "sample_policy.docx"
    
    url = "http://localhost:8000/api/v1/documents/upload"
    
    with open(file_path, "rb") as f:
        files = {"file": ("sample_policy.docx", f, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
        data = {
            "allowed_roles": "ROLE_EMPLOYEE,ROLE_MANAGER",
            "allowed_departments": "ALL",
            "uploaded_by": "ADMIN"
        }
        
        print("Đang gửi file lên FastAPI (Port 8000)...")
        print("Quá trình này sẽ mất khoảng 1-2 phút do Ollama và Gemini đang xử lý...")
        response = requests.post(url, files=files, data=data)
        
        print("\n=== KẾT QUẢ ===")
        print(f"Status Code: {response.status_code}")
        try:
            print(json.dumps(response.json(), indent=2, ensure_ascii=False))
        except:
            print(response.text)

if __name__ == "__main__":
    test_upload()
