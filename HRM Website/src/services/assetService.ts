import { apiClient, API_BASE_URL } from './apiClient';
import {
  Asset,
  AssetAssignment,
  AssetCategory,
  AssetImage,
  AssetInventoryLog,
  AssetMaintenance,
  AssetRequest,
  AssetTimelineEvent,
} from '@/types';

export const assetService = {
  // ponytail: ảnh lưu relative /uploads/** (backend serve static) — ghép base lúc hiển thị
  resolveImage: (url?: string) => (!url ? '' : url.startsWith('http') ? url : `${API_BASE_URL}${url}`),
  // ─── Danh mục (list mở cho mọi nhân viên để làm đơn) ───
  listCategories: () => apiClient.get<AssetCategory[]>('/api/assets/categories'),
  createCategory: (data: { name: string; codePrefix: string; description?: string }) =>
    apiClient.post<AssetCategory>('/api/assets/categories', data),
  updateCategory: (categoryId: string, data: { name?: string; description?: string }) =>
    apiClient.put<AssetCategory>(`/api/assets/categories/${categoryId}`, data),
  deleteCategory: (categoryId: string) =>
    apiClient.delete<{ message: string }>(`/api/assets/categories/${categoryId}`),

  // ─── Kho (cần VIEW_ASSETS) ───
  listAssets: () => apiClient.get<Asset[]>('/api/assets'),
  getAsset: (assetId: string) => apiClient.get<Asset>(`/api/assets/${assetId}`),
  createAsset: (data: Partial<Asset> & { categoryId: string; name: string }) =>
    apiClient.post<Asset>('/api/assets', data),
  updateAsset: (assetId: string, data: Partial<Asset>) =>
    apiClient.put<Asset>(`/api/assets/${assetId}`, data),
  deleteAsset: (assetId: string) =>
    apiClient.delete<{ message: string }>(`/api/assets/${assetId}`),
  assetImages: (assetId: string) => apiClient.get<AssetImage[]>(`/api/assets/${assetId}/images`),
  uploadImage: (assetId: string, file: File, caption?: string) => {
    const fd = new FormData();
    fd.append('file', file);
    if (caption) fd.append('caption', caption);
    return apiClient.post<AssetImage>(`/api/assets/${assetId}/images`, fd);
  },
  deleteImage: (imageId: string) => apiClient.delete<{ message: string }>(`/api/assets/images/${imageId}`),
  timeline: (assetId: string) => apiClient.get<AssetTimelineEvent[]>(`/api/assets/${assetId}/timeline`),

  // ─── Đơn xin (mọi nhân viên) ───
  createRequest: (data: { categoryId: string; reason: string; neededByDate?: string; expectedReturnDate?: string }) =>
    apiClient.post<AssetRequest>('/api/assets/requests', data),
  myRequests: () => apiClient.get<AssetRequest[]>('/api/assets/requests/my'),
  pendingRequests: () => apiClient.get<AssetRequest[]>('/api/assets/requests/approvals'),
  handleRequest: (requestId: string, approve: boolean, rejectionReason?: string) =>
    apiClient.patch<AssetRequest>(`/api/assets/requests/${requestId}/handle`, { approve, rejectionReason }),
  cancelRequest: (requestId: string) => apiClient.delete(`/api/assets/requests/${requestId}`),
  urgentRequests: (days = 7) => apiClient.get<AssetRequest[]>(`/api/assets/requests/urgent?days=${days}`),

  // ─── Cấp phát / thu hồi ───
  assign: (requestId: string, assetId: string, conditionOnAssign?: string, departmentId?: string) =>
    apiClient.post<AssetAssignment>('/api/assets/assignments', { requestId, assetId, conditionOnAssign, departmentId }),
  myAssets: () => apiClient.get<AssetAssignment[]>('/api/assets/assignments/my'),
  pendingReturns: () => apiClient.get<AssetAssignment[]>('/api/assets/assignments/pending-returns'),
  requestReturn: (assignmentId: string) =>
    apiClient.post<AssetAssignment>(`/api/assets/assignments/${assignmentId}/request-return`),
  confirmReturn: (assignmentId: string, conditionOnReturn?: string) =>
    apiClient.post<AssetAssignment>(`/api/assets/assignments/${assignmentId}/confirm-return`, { conditionOnReturn }),
  markLost: (assignmentId: string) =>
    apiClient.post<AssetAssignment>(`/api/assets/assignments/${assignmentId}/mark-lost`),
  dueReturns: (days = 7) => apiClient.get<AssetAssignment[]>(`/api/assets/assignments/due-return?days=${days}`),

  // ─── Bảo trì / kiểm kê / ảnh (cần MANAGE_ASSETS) ───
  reportMaintenance: (data: { assetId: string; type: string; description?: string; cost?: number; vendor?: string }) =>
    apiClient.post<AssetMaintenance>('/api/assets/maintenances', data),
  maintenances: (assetId: string) => apiClient.get<AssetMaintenance[]>(`/api/assets/${assetId}/maintenances`),
  inventoryCheck: (data: { assetId: string; found: boolean; conditionNote?: string }) =>
    apiClient.post<AssetInventoryLog>('/api/assets/inventory', data),
  addImage: (data: { assetId: string; imageUrl: string; caption?: string; cover?: boolean; assignmentId?: string; maintenanceId?: string; inventoryLogId?: string }) =>
    apiClient.post<AssetImage>('/api/assets/images', data),
};
