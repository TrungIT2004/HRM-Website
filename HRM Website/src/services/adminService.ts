import { apiClient } from './apiClient';

export interface PendingUserItem {
  pendingId: string;
  firstName: string;
  lastName: string;
  fullName: string;
  gender: string;
  birthDate: string;
  personalEmail: string;
  phoneNumber?: string;
  citizenId?: string;
  placeOfBirth?: string;
  departmentId: string;
  departmentName: string;
  jobId: string;
  jobTitle: string;
  shiftId?: string;
  shiftName?: string;
  baseSalary?: number;
  contractType?: string;
  contractStartDate?: string;
  contractEndDate?: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  rejectionReason?: string;
  createdByName?: string;
  createdAt: string;
}

export interface AdminAccountItem {
  userId: string;
  employeeCode: string;
  fullName: string;
  email: string;
  departmentName: string;
  jobTitle: string;
  isActive: boolean;
  joinedDate: string;
  activeSessionCount: number;
}

export interface AdminSessionItem {
  sessionId: string;
  userId: string;
  userFullName: string;
  userEmail: string;
  departmentName?: string;
  deviceType?: string;
  deviceOS?: string;
  browser?: string;
  ipAddr?: string;
  city?: string;
  country?: string;
  isp?: string;
  createdAt: string;
  lastActiveAt?: string;
  revoked: boolean;
}

export interface ProvisionPayload {
  corporateEmail: string;
  temporaryPassword: string;
  employeeCode?: string;
}

export interface UserPermissionItem {
  key: string;
  label: string;
  grantedBy: string;
  grantedByName: string;
  grantedAt: string;
}

/** Giải thích chi tiết, hiện khi hover (title attribute — native, không cần thư viện tooltip).
 *  Nội dung phải khớp với hành vi THẬT của backend, kể cả chỗ gây bất ngờ. */
export const PERMISSION_DESCRIPTIONS: Record<string, string> = {
  ATTENDANCE_VIEW_ALL: 'Xem bảng chấm công của toàn bộ công ty, không giới hạn theo phòng ban. Bao gồm cả tab tổng hợp bảng công theo tháng.',
  LEAVE_VIEW_ALL: 'Xem toàn bộ đơn nghỉ phép của công ty, không giới hạn theo phòng ban. Thấy cả lý do nghỉ và số ngày phép.',
  OVERTIME_VIEW_ALL: 'Xem toàn bộ đơn tăng ca của công ty, không giới hạn theo phòng ban.',
  PAYROLL_VIEW_ALL: 'Xem bảng lương của toàn bộ công ty. Đây là dữ liệu nhạy cảm nhất — cấp cho đúng người thôi.',
  RESIGN_VIEW_ALL: 'Xem toàn bộ đơn thôi việc của công ty, không giới hạn theo phòng ban.',
  LEAVE_APPROVE: 'Duyệt / từ chối đơn nghỉ phép. CẢNH BÁO: quyền này bỏ qua chuỗi phân cấp, nên xem được MỌI đơn của công ty (kể cả đơn đã xử lý), không chỉ đơn trong phòng. Không tự duyệt đơn của chính mình.',
  OVERTIME_APPROVE: 'Duyệt / từ chối đơn tăng ca. CẢNH BÁO: xem được MỌI đơn tăng ca của công ty, không chỉ trong phòng. Không tự duyệt đơn của chính mình.',
  RESIGN_APPROVE: 'Duyệt đơn thôi việc ở cấp Ban Giám Đốc. Chỉ thấy đơn đang chờ duyệt, không thấy lịch sử đã xử lý.',
  TIMESHEET_LOCK: 'Tính toán và chốt sổ bảng công theo tháng. Sau khi chốt, số liệu chấm công không sửa được nữa.',
  PAYROLL_MANAGE: 'Tính và duyệt bảng lương. Quyền này tác động trực tiếp tới tiền thật của nhân viên.',
  ACCOUNT_LOCK: 'Khóa / mở khoá tài khoản nhân viên. Khi khoá, toàn bộ phiên đăng nhập của họ bị thu hồi ngay. Kèm theo: xem danh sách tài khoản và xem/thu hồi phiên đăng nhập.',
  PERMISSION_GRANT: 'Cấp quyền cho nhân viên khác. Người được cấp quyền này cũng cấp lại được — kể cả quyền này. Chỉ cấp khi thật sự tin tưởng.',
  ORG_MANAGE: 'Tạo / sửa / xoá phòng ban, chức danh và ca làm việc. Xoá bị chặn nếu còn nhân viên hoặc dữ liệu chấm công tham chiếu.',
  EMPLOYEE_VIEW_ALL: 'Xem hồ sơ của mọi nhân viên trong công ty, gồm cả lương, số tài khoản ngân hàng, CCCD và hợp đồng. Chỉ xem, không sửa.',
  EMPLOYEE_EDIT: 'Sửa hồ sơ nhân viên khác (cơ bản, pháp lý, hợp đồng, phụ cấp). Áp dụng phân nhiệm: không tự sửa hợp đồng của chính mình.',
  DOCUMENT_UPLOAD: 'Đăng tải tài liệu & quy chế lên kho tri thức. Người được cấp chỉ đăng được cho chính phòng mình; chỉ người đăng gốc mới sửa/xóa được tài liệu đó.',
  ATTENDANCE_VIEW_DEPT: 'Xem bảng chấm công của chính phòng ban mình. Không thấy phòng khác.',
  LEAVE_VIEW_DEPT: 'Xem đơn nghỉ phép của chính phòng ban mình, gồm cả đơn đã xử lý. Không tự duyệt đơn của chính mình.',
  OVERTIME_VIEW_DEPT: 'Xem đơn tăng ca của chính phòng ban mình, gồm cả đơn đã xử lý. Không tự duyệt đơn của chính mình.',
  LEAVE_APPROVE_DEPT: 'Duyệt / từ chối đơn nghỉ phép của chính phòng ban mình. Không thấy phòng khác. Không tự duyệt đơn của chính mình.',
  OVERTIME_APPROVE_DEPT: 'Duyệt / từ chối đơn tăng ca của chính phòng ban mình. Không thấy phòng khác. Không tự duyệt đơn của chính mình.',
  VIEW_ASSETS: 'Xem kho tài sản toàn công ty (mã, tình trạng, người giữ). Không được nhập / cấp / thu hồi.',
  MANAGE_ASSETS: 'Nhập kho, duyệt đơn, cấp phát và thu hồi tài sản. Bao hàm quyền xem. Không tự duyệt đơn của chính mình.',
  IT_TICKET_HANDLE: 'Thấy hàng chờ IT ticket, nhận và xử lý ticket. Người thường chỉ thấy ticket của chính mình.',
  EVALUATION_VIEW_ALL: 'Xem bài đánh giá hiệu suất của toàn bộ công ty, không giới hạn theo phòng ban.',
  EVALUATION_VIEW_DEPT: 'Xem bài đánh giá hiệu suất của chính phòng ban mình. Không thấy phòng khác.',
  EVALUATION_APPROVE: 'Chấm điểm + khóa sổ đánh giá toàn công ty. CẢNH BÁO: bỏ qua chuỗi phân cấp như LEAVE_APPROVE. Không tự chấm cho chính mình.',
  EVALUATION_APPROVE_DEPT: 'Chấm điểm đánh giá của chính phòng ban mình. Không thấy phòng khác. Không tự chấm cho chính mình.'
};
export const PERMISSION_GROUPS: { title: string; keys: readonly string[] }[] = [
  { title: 'Quyền xem toàn công ty', keys: ['ATTENDANCE_VIEW_ALL', 'LEAVE_VIEW_ALL', 'OVERTIME_VIEW_ALL', 'PAYROLL_VIEW_ALL', 'RESIGN_VIEW_ALL', 'EVALUATION_VIEW_ALL'] },
  { title: 'Quyền phạm vi phòng ban', keys: ['ATTENDANCE_VIEW_DEPT', 'LEAVE_VIEW_DEPT', 'OVERTIME_VIEW_DEPT', 'LEAVE_APPROVE_DEPT', 'OVERTIME_APPROVE_DEPT', 'EVALUATION_VIEW_DEPT', 'EVALUATION_APPROVE_DEPT'] },
  { title: 'Quyền duyệt, chốt & tính lương', keys: ['LEAVE_APPROVE', 'OVERTIME_APPROVE', 'RESIGN_APPROVE', 'TIMESHEET_LOCK', 'PAYROLL_MANAGE', 'EVALUATION_APPROVE'] },
  { title: 'Quyền quản trị hệ thống', keys: ['ACCOUNT_LOCK', 'PERMISSION_GRANT', 'ORG_MANAGE', 'EMPLOYEE_VIEW_ALL', 'EMPLOYEE_EDIT', 'DOCUMENT_UPLOAD'] },
  { title: 'Quyền tài sản', keys: ['VIEW_ASSETS', 'MANAGE_ASSETS'] },
  { title: 'Quyền IT ticket', keys: ['IT_TICKET_HANDLE'] }
];

export const PERMISSION_LABELS: Record<string, string> = {
  ATTENDANCE_VIEW_ALL: 'Xem chấm công toàn công ty',
  LEAVE_VIEW_ALL: 'Xem nghỉ phép toàn công ty',
  OVERTIME_VIEW_ALL: 'Xem tăng ca toàn công ty',
  PAYROLL_VIEW_ALL: 'Xem lương toàn công ty',
  RESIGN_VIEW_ALL: 'Xem thôi việc toàn công ty',
  // ponytail: nhãn ghi rõ "toàn công ty" vì grant APPROVE = thấy MỌI đơn công ty
  // (LeaveRequestSpecification.java:87 để trống nhánh if, chỉ lọc "không tự duyệt")
  LEAVE_APPROVE: 'Duyệt / từ chối đơn nghỉ phép toàn công ty',
  OVERTIME_APPROVE: 'Duyệt / từ chối đơn tăng ca toàn công ty',
  RESIGN_APPROVE: 'Duyệt đơn thôi việc toàn công ty',
  TIMESHEET_LOCK: 'Tính toán + chốt sổ bảng công',
  PAYROLL_MANAGE: 'Tính + duyệt bảng lương',
  ACCOUNT_LOCK: 'Mở / khóa tài khoản nhân viên',
  PERMISSION_GRANT: 'Cấp quyền cho nhân viên khác',
  ORG_MANAGE: 'Quản lý phòng ban, chức danh & ca làm việc',
  EMPLOYEE_VIEW_ALL: 'Xem hồ sơ nhân viên toàn công ty',
  EMPLOYEE_EDIT: 'Chỉnh sửa hồ sơ nhân viên',
  DOCUMENT_UPLOAD: 'Đăng tải tài liệu & quy chế',
  ATTENDANCE_VIEW_DEPT: 'Xem chấm công phòng ban',
  LEAVE_VIEW_DEPT: 'Xem nghỉ phép phòng ban',
  OVERTIME_VIEW_DEPT: 'Xem tăng ca phòng ban',
  LEAVE_APPROVE_DEPT: 'Duyệt / từ chối đơn nghỉ phép phòng ban',
  OVERTIME_APPROVE_DEPT: 'Duyệt / từ chối đơn tăng ca phòng ban',
  VIEW_ASSETS: 'Xem tài sản toàn công ty',
  MANAGE_ASSETS: 'Nhập / cấp / thu hồi tài sản',
  IT_TICKET_HANDLE: 'Nhận và xử lý IT ticket',
  EVALUATION_VIEW_ALL: 'Xem đánh giá hiệu suất toàn công ty',
  EVALUATION_VIEW_DEPT: 'Xem đánh giá hiệu suất phòng ban',
  EVALUATION_APPROVE: 'Chấm + khóa sổ đánh giá toàn công ty',
  EVALUATION_APPROVE_DEPT: 'Chấm đánh giá hiệu suất phòng ban'
};

export const adminService = {
  getPendingUsers: async (status: string = 'PENDING'): Promise<PendingUserItem[]> => {
    return apiClient.get<PendingUserItem[]>(`/api/admin/pending-users?status=${status}`);
  },

  createPendingUser: async (payload: Record<string, any>): Promise<PendingUserItem> => {
    return apiClient.post<PendingUserItem>('/api/admin/pending-users', payload);
  },

  provisionUser: async (pendingId: string, payload: ProvisionPayload): Promise<AdminAccountItem> => {
    return apiClient.post<AdminAccountItem>(`/api/admin/pending-users/${pendingId}/provision`, payload);
  },

  rejectPendingUser: async (pendingId: string, reason: string): Promise<{ message: string }> => {
    return apiClient.post<{ message: string }>(`/api/admin/pending-users/${pendingId}/reject`, { reason });
  },

  getAllAccounts: async (): Promise<AdminAccountItem[]> => {
    return apiClient.get<AdminAccountItem[]>('/api/admin/accounts');
  },

  updateAccountStatus: async (userId: string, isActive: boolean, reason?: string): Promise<AdminAccountItem> => {
    return apiClient.patch<AdminAccountItem>(`/api/admin/accounts/${userId}/status`, { isActive, reason });
  },

  resetPassword: async (userId: string, newPassword: string): Promise<{ message: string }> => {
    return apiClient.post<{ message: string }>(`/api/admin/accounts/${userId}/reset-password`, { newPassword });
  },

  getAllSessions: async (): Promise<AdminSessionItem[]> => {
    return apiClient.get<AdminSessionItem[]>('/api/admin/sessions');
  },

  getUserSessions: async (userId: string): Promise<AdminSessionItem[]> => {
    return apiClient.get<AdminSessionItem[]>(`/api/admin/users/${userId}/sessions`);
  },

  revokeSession: async (sessionId: string): Promise<{ message: string }> => {
    return apiClient.delete<{ message: string }>(`/api/admin/sessions/${sessionId}`);
  },

  revokeAllUserSessions: async (userId: string): Promise<{ message: string }> => {
    return apiClient.delete<{ message: string }>(`/api/admin/users/${userId}/sessions`);
  },

  getUserPermissions: async (userId: string): Promise<UserPermissionItem[]> => {
    return apiClient.get<UserPermissionItem[]>(`/api/admin/users/${userId}/permissions`);
  },

  saveUserPermissions: async (userId: string, permissions: string[]): Promise<UserPermissionItem[]> => {
    return apiClient.put<UserPermissionItem[]>(`/api/admin/users/${userId}/permissions`, { permissions });
  }
};
