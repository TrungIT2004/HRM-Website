import { apiClient, API_BASE_URL } from './apiClient';

export type TemplateCategory =
  | 'HANDOVER' | 'MEETING' | 'RECRUITMENT' | 'LEAVE' | 'RESIGN' | 'HDLD';

export const TEMPLATE_CATEGORY_LABELS: Record<TemplateCategory, string> = {
  HANDOVER: 'Bàn giao công việc',
  MEETING: 'Biên bản cuộc họp',
  RECRUITMENT: 'Bổ sung nhân sự',
  LEAVE: 'Đơn xin nghỉ',
  RESIGN: 'Đơn xin nghỉ việc',
  HDLD: 'Hợp đồng lao động',
};

export interface TemplateDocument {
  documentId: string;
  category: TemplateCategory;
  categoryLabel: string;
  documentName: string;
  documentTitle: string;
  fileUrl: string;
  fileType: string;
  fileSize: number;
  summary?: string;
  uploaderId?: string;
  uploaderName?: string;
  createdAt: string;
  updatedAt: string;
}

export const documentService = {
  list: async (category?: string): Promise<TemplateDocument[]> => {
    const qs = category && category !== 'ALL' ? `?category=${encodeURIComponent(category)}` : '';
    return apiClient.get(`/api/documents${qs}`);
  },

  upload: async (formData: FormData): Promise<TemplateDocument> => {
    return apiClient.post('/api/documents', formData);
  },

  update: async (documentId: string, formData: FormData): Promise<TemplateDocument> => {
    return apiClient.put(`/api/documents/${documentId}`, formData);
  },

  delete: async (documentId: string): Promise<{ message: string }> => {
    return apiClient.delete(`/api/documents/${documentId}`);
  },

  // ponytail: file tĩnh serve qua /uploads/**, không cần endpoint download riêng —
  // fetch blob để giữ đúng tên file gốc khi tải (attr download cross-origin bị browser lờ).
  download: async (doc: TemplateDocument): Promise<void> => {
    const res = await fetch(`${API_BASE_URL}${doc.fileUrl}`, { credentials: 'include' });
    if (!res.ok) throw new Error(`Tải file thất bại (Mã lỗi ${res.status})`);
    const blob = await res.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = doc.documentName || 'mau-don.docx';
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(url);
  },
};
