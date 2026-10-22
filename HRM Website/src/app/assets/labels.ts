// Nhãn tiếng Việt cho enum tài sản (backend giữ nguyên key tiếng Anh).
// Thêm key mới ở đây thay vì rải string khắp UI.
export const ASSET_STATUS_LABEL: Record<string, string> = {
  available: 'Sẵn sàng',
  assigned: 'Đang mượn',
  under_maintenance: 'Đang bảo trì',
  broken: 'Hỏng',
  lost: 'Mất',
  retired: 'Thanh lý',
};

export const ASSET_REQUEST_STATUS_LABEL: Record<string, string> = {
  pending: 'Chờ duyệt',
  approved: 'Đã duyệt',
  rejected: 'Từ chối',
  cancelled: 'Đã hủy',
  issued: 'Đã cấp',
  returned: 'Đã trả',
};

export const ASSIGNMENT_STATUS_LABEL: Record<string, string> = {
  active: 'Đang mượn',
  pending_return: 'Chờ thu hồi',
  returned: 'Đã trả',
  overdue: 'Quá hạn',
  lost: 'Mất',
};

export const assetStatusLabel = (s?: string) => (s && ASSET_STATUS_LABEL[s]) ?? s ?? '—';
export const requestStatusLabel = (s?: string) => (s && ASSET_REQUEST_STATUS_LABEL[s]) ?? s ?? '—';
export const assignmentStatusLabel = (s?: string) => (s && ASSIGNMENT_STATUS_LABEL[s]) ?? s ?? '—';
