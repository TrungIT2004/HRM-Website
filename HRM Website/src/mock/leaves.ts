import { LeavePreviewResult, LeaveRequest, User } from '@/types';
import { isHoliday } from './holidays';
import { MOCK_USERS } from './users';

export const MOCK_LEAVE_REQUESTS: LeaveRequest[] = [
  {
    requestId: 'leave-req-001',
    requestorId: '00000000-0000-0000-0000-000000000001',
    requestorName: 'Nguyễn Hoàng',
    requestorCode: 'IT002',
    requestorDepartment: 'Information Technology',
    requestorJob: 'Software Engineer',
    requestorEmail: 'it.employee@company.com',
    requestorPhone: '0978123456',
    fromDate: '2026-09-10',
    toDate: '2026-09-11',
    paidLeaveDays: 2,
    totalWorkingDays: 2,
    reason: 'Giải quyết việc gia đình tại quê',
    status: 'pending',
    approverId: '99999999-9999-9999-9999-999999999999',
    approverName: 'Đỗ Văn Hùng',
    approverJob: 'Department Head of IT',
    createdAt: '2026-09-04 09:30:00'
  },
  {
    requestId: 'leave-req-002',
    requestorId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    requestorName: 'Lê Tuấn',
    requestorCode: 'SALES002',
    requestorDepartment: 'Sales & Marketing',
    requestorJob: 'Sales Executive Staff',
    requestorEmail: 'sales.employee@company.com',
    requestorPhone: '0912345678',
    fromDate: '2026-09-15',
    toDate: '2026-09-16',
    paidLeaveDays: 2,
    totalWorkingDays: 2,
    reason: 'Tham gia đám cưới người thân',
    status: 'pending',
    approverId: '44444444-4444-4444-4444-444444444444',
    approverName: 'Trần Văn An',
    approverJob: 'Department Head of Sales',
    createdAt: '2026-09-03 14:15:00'
  },
  {
    requestId: 'leave-req-003',
    requestorId: '99999999-9999-9999-9999-999999999999',
    requestorName: 'Đỗ Văn Hùng',
    requestorCode: 'IT001',
    requestorDepartment: 'Information Technology',
    requestorJob: 'Department Head of IT',
    requestorEmail: 'dovanhung@company.com',
    requestorPhone: '0945678901',
    fromDate: '2026-08-20',
    toDate: '2026-08-21',
    paidLeaveDays: 2,
    totalWorkingDays: 2,
    reason: 'Đi khám sức khỏe định kỳ',
    status: 'accepted',
    approverId: '22222222-2222-2222-2222-222222222222',
    approverName: 'Lê Thanh Hương',
    approverJob: 'Director',
    createdAt: '2026-08-15 10:00:00'
  },
  {
    requestId: 'leave-req-004',
    requestorId: 'ffffffff-ffff-ffff-ffff-ffffffffffff',
    requestorName: 'Đặng Kim',
    requestorCode: 'CS002',
    requestorDepartment: 'Customer Support',
    requestorJob: 'Support Representative',
    requestorEmail: 'support.employee@company.com',
    requestorPhone: '0934567891',
    fromDate: '2026-08-10',
    toDate: '2026-08-12',
    paidLeaveDays: 3,
    totalWorkingDays: 3,
    reason: 'Nghỉ du lịch tự túc',
    status: 'rejected',
    approverId: '88888888-8888-8888-8888-888888888888',
    approverName: 'Hoàng Thị Hà',
    approverJob: 'Department Head of Support',
    rejectionReason: 'Trùng lịch trực cao điểm bảo trì hệ thống của phòng CSKH',
    createdAt: '2026-08-05 16:20:00'
  }
];

// Helper tính toán xem trước ngày nghỉ y hệt Spring Boot /api/leave/preview
export function calculateLeavePreview(user: User, fromDateStr: string, toDateStr: string): LeavePreviewResult {
  const from = new Date(fromDateStr);
  const to = new Date(toDateStr);

  if (isNaN(from.getTime()) || isNaN(to.getTime()) || from > to) {
    return {
      requestedLeaveDays: 0,
      workDays: 0,
      restDays: 0,
      holidayDays: 0,
      annualLeaveDays: user.annualLeaveDays,
      usedLeaveDays: user.usedLeaveDays,
      remainingAnnualLeaveDays: user.annualLeaveDays - user.usedLeaveDays,
      remainingAfterThisRequest: user.annualLeaveDays - user.usedLeaveDays,
      isSufficientAnnualLeave: true
    };
  }

  let cur = new Date(from);
  let totalDays = 0;
  let workDays = 0;
  let restDays = 0;
  let holidayDays = 0;
  const excludedDates: { date: string; type: 'WEEKEND' | 'HOLIDAY'; label: string }[] = [];

  while (cur <= to) {
    totalDays++;
    const yyyy = cur.getFullYear();
    const mm = String(cur.getMonth() + 1).padStart(2, '0');
    const dd = String(cur.getDate()).padStart(2, '0');
    const dStr = `${yyyy}-${mm}-${dd}`;
    const dayOfWeek = cur.getDay(); // 0 = Sunday, 6 = Saturday

    const holiday = isHoliday(dStr);
    if (holiday) {
      holidayDays++;
      excludedDates.push({ date: dStr, type: 'HOLIDAY', label: holiday.description });
    } else if (dayOfWeek === 0 || dayOfWeek === 6) {
      // Cuối tuần
      restDays++;
      excludedDates.push({ date: dStr, type: 'WEEKEND', label: dayOfWeek === 0 ? 'Chủ Nhật' : 'Thứ 7' });
    } else {
      workDays++;
    }

    cur.setDate(cur.getDate() + 1);
  }

  const remaining = user.annualLeaveDays - user.usedLeaveDays;
  const remainingAfter = remaining - workDays;

  return {
    requestedLeaveDays: totalDays,
    workDays,
    restDays,
    holidayDays,
    annualLeaveDays: user.annualLeaveDays,
    usedLeaveDays: user.usedLeaveDays,
    remainingAnnualLeaveDays: remaining,
    remainingAfterThisRequest: remainingAfter,
    isSufficientAnnualLeave: remainingAfter >= 0,
    excludedDates
  };
}
