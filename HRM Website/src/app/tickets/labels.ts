// Nhãn tiếng Việt cho enum IT ticket (backend giữ key tiếng Anh — theo mẫu assets/labels.ts).
export const IT_CATEGORY_LABEL: Record<string, string> = {
  LAPTOP_PC: 'Máy tính (Laptop / PC)',
  NETWORK: 'Mạng / Internet / WiFi',
  PRINTER: 'Máy in / Photocopy / Scan',
  ACCOUNT_EMAIL: 'Tài khoản / Email',
  SOFTWARE: 'Phần mềm / Ứng dụng',
  PERIPHERAL: 'Bàn phím / Chuột / Màn hình',
  OTHER: 'Khác',
};

export const IT_STATUS_LABEL: Record<string, string> = {
  OPEN: 'Chờ nhận',
  IN_PROGRESS: 'Đang xử lý',
  DONE: 'Hoàn thành',
  CANCELLED: 'Đã hủy',
};

export const IT_PRIORITY_LABEL: Record<string, string> = {
  NORMAL: 'Thường',
  HIGH: 'Gấp',
};

export const itCategoryLabel = (s?: string) => (s && IT_CATEGORY_LABEL[s]) ?? s ?? '—';
export const itStatusLabel = (s?: string) => (s && IT_STATUS_LABEL[s]) ?? s ?? '—';
export const itPriorityLabel = (s?: string) => (s && IT_PRIORITY_LABEL[s]) ?? s ?? '—';

// ponytail: màu cố định theo category cho donut + bar — 1 bảng duy nhất, khỏi lib chart
export const IT_CATEGORY_COLOR: Record<string, string> = {
  LAPTOP_PC: '#0ea5e9',
  NETWORK: '#8b5cf6',
  PRINTER: '#f59e0b',
  ACCOUNT_EMAIL: '#10b981',
  SOFTWARE: '#ec4899',
  PERIPHERAL: '#64748b',
  OTHER: '#cbd5e1',
};

export const itCategoryColor = (s?: string) => (s && IT_CATEGORY_COLOR[s]) ?? '#94a3b8';
