import { apiClient, API_BASE_URL } from './apiClient';
import { ItTicket, ItTicketOverview } from '@/types';

export const ticketService = {
  // ponytail: ảnh lưu relative /uploads/** — ghép base lúc hiển thị (copy assetService.resolveImage)
  resolveImage: (url?: string) => (!url ? '' : url.startsWith('http') ? url : `${API_BASE_URL}${url}`),
  create: (data: { deviceInfo: string; category: string; description: string; location?: string; priority?: string }) =>
    apiClient.post<ItTicket>('/api/it-tickets', data),
  uploadImage: (ticketId: string, file: File) => {
    const fd = new FormData();
    fd.append('file', file);
    return apiClient.post<ItTicket>(`/api/it-tickets/${ticketId}/image`, fd);
  },
  myTickets: () => apiClient.get<ItTicket[]>('/api/it-tickets/my'),
  queue: (status = 'QUEUE') => apiClient.get<ItTicket[]>(`/api/it-tickets/queue?status=${status}`),
  overview: (year: number, month: number) =>
    apiClient.get<ItTicketOverview>(`/api/it-tickets/overview?year=${year}&month=${month}`),
  claim: (ticketId: string) => apiClient.patch<ItTicket>(`/api/it-tickets/${ticketId}/claim`, {}),
  resolve: (ticketId: string, resolveNote?: string) =>
    apiClient.patch<ItTicket>(`/api/it-tickets/${ticketId}/resolve`, { resolveNote }),
  cancel: (ticketId: string) => apiClient.patch<ItTicket>(`/api/it-tickets/${ticketId}/cancel`, {}),
};
