import { apiClient, API_BASE_URL, ApiError } from './apiClient';

export interface Citation {
  document_name: string;
  breadcrumb?: string;
  page_number?: number;
  file_url?: string;
  chunk_type?: string;
  relevance_score?: number;
}

export interface ChatQueryResponse {
  conversation_id: string;
  title: string;
  question: string;
  rewritten_query?: string;
  answer: string;
  citations: Citation[];
  retrieved_chunks_count?: number;
  confidence: 'HIGH' | 'MEDIUM' | 'LOW';
}

export interface ConversationSummary {
  id: string;
  title: string;
  is_pinned: boolean;
  created_at: string;
  updated_at: string;
  message_count: number;
}

export interface ChatMessage {
  id?: string;
  sender_role: 'user' | 'assistant' | 'system';
  content: string;
  rewritten_query?: string;
  citations?: Citation[];
  confidence?: 'HIGH' | 'MEDIUM' | 'LOW';
  created_at?: string;
}

export interface KnowledgeDocument {
  id: string;
  file_name: string;
  file_type: string;
  file_size: number;
  file_hash: string;
  uploaded_by: string;
  status: 'PROCESSING' | 'COMPLETED' | 'FAILED';
  file_url: string;
  error_message?: string;
  created_at: string;
  updated_at: string;
  chunk_count: number;
  allowed_departments: string[];
}

export const aiService = {
  askQuestion: async (payload: { question: string; conversationId?: string; topK?: number }): Promise<ChatQueryResponse> => {
    return apiClient.post<ChatQueryResponse>('/api/ai/chat', payload);
  },

  streamChat: async (
    payload: { question: string; conversationId?: string; topK?: number },
    callbacks: {
      onStart?: (data: { conversation_id: string; title: string }) => void;
      onToken?: (token: string) => void;
      onCitations?: (data: { citations: Citation[]; confidence: 'HIGH' | 'MEDIUM' | 'LOW'; rewritten_query?: string }) => void;
      onDone?: () => void;
      onError?: (err: Error) => void;
    }
  ): Promise<void> => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
    const url = `${API_BASE_URL}/api/ai/chat/stream`;

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        throw new Error(`Lỗi kết nối AI Service (Mã ${response.status})`);
      }

      if (!response.body) {
        throw new Error('ReadableStream không được trình duyệt hỗ trợ');
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder('utf-8');
      let buffer = '';

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;

          const dataStr = trimmed.slice(5).trim();
          if (!dataStr) continue;

          try {
            const parsed = JSON.parse(dataStr);
            if (parsed.type === 'start') {
              callbacks.onStart?.(parsed);
            } else if (parsed.type === 'token') {
              callbacks.onToken?.(parsed.content || '');
            } else if (parsed.type === 'citations') {
              callbacks.onCitations?.(parsed);
            } else if (parsed.type === 'done') {
              callbacks.onDone?.();
            } else if (parsed.type === 'error') {
              callbacks.onError?.(new Error(parsed.message || 'Lỗi xử lý luồng AI'));
            }
          } catch {
            // raw text token fallback
            callbacks.onToken?.(dataStr);
          }
        }
      }
      callbacks.onDone?.();
    } catch (err: any) {
      callbacks.onError?.(err);
    }
  },

  getConversations: async (): Promise<{ conversations: ConversationSummary[] }> => {
    return apiClient.get('/api/ai/conversations');
  },

  getConversationMessages: async (conversationId: string): Promise<{ id: string; title: string; messages: ChatMessage[] }> => {
    return apiClient.get(`/api/ai/conversations/${conversationId}/messages`);
  },

  updateConversationTitle: async (conversationId: string, title: string): Promise<{ status: string; title: string }> => {
    return apiClient.put(`/api/ai/conversations/${conversationId}`, { title });
  },

  generateTitle: async (conversationId: string): Promise<{ status: string; title: string }> => {
    return apiClient.post(`/api/ai/conversations/${conversationId}/generate-title`);
  },

  deleteConversation: async (conversationId: string): Promise<{ status: string }> => {
    return apiClient.delete(`/api/ai/conversations/${conversationId}`);
  },

  pinConversation: async (conversationId: string, isPinned?: boolean): Promise<{ status: string; is_pinned: boolean }> => {
    return apiClient.put(`/api/ai/conversations/${conversationId}/pin`, { isPinned });
  },

  getDocuments: async (department?: string): Promise<{ documents: KnowledgeDocument[] }> => {
    const qs = department && department !== 'ALL' ? `?department=${encodeURIComponent(department)}` : '';
    return apiClient.get(`/api/ai/documents${qs}`);
  },

  uploadDocument: async (formData: FormData): Promise<{ status: string; document: KnowledgeDocument }> => {
    return apiClient.post('/api/ai/documents/upload', formData);
  },

  updateDocument: async (documentId: string, formData: FormData): Promise<{ status: string }> => {
    const res: any = await apiClient.put(`/api/ai/documents/${documentId}`, formData);
    // FastAPI trả HTTP 200 kèm status:"UNCHANGED" khi SHA-256 không đổi
    // (ai-service/main.py) → không hề chạy lại pipeline, chunk cũ giữ nguyên.
    // Không check ở đây thì UI báo "đã cập nhật" sai.
    if (res?.status === 'UNCHANGED') {
      throw new ApiError(409, res.message || 'Nội dung file không thay đổi, hệ thống không xử lý lại', res);
    }
    return res;
  },

  deleteDocument: async (documentId: string): Promise<{ status: string }> => {
    return apiClient.delete(`/api/ai/documents/${documentId}`);
  },

  downloadDocument: async (documentId: string, filename?: string): Promise<Blob> => {
    return apiClient.downloadBlob(`/api/ai/documents/${documentId}/download`, filename || 'document.pdf');
  }
};
