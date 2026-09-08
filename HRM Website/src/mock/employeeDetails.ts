import { EmployeeDetailed, WorkShiftScheduleItem } from '@/types';
import { MOCK_USERS } from './users';

const STANDARD_SCHEDULE: WorkShiftScheduleItem[] = [
  { dayOfWeek: 2, dayName: 'Thứ 2', isWorking: true, startTime: '08:30', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:00' },
  { dayOfWeek: 3, dayName: 'Thứ 3', isWorking: true, startTime: '08:30', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:00' },
  { dayOfWeek: 4, dayName: 'Thứ 4', isWorking: true, startTime: '08:30', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:00' },
  { dayOfWeek: 5, dayName: 'Thứ 5', isWorking: true, startTime: '08:30', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:00' },
  { dayOfWeek: 6, dayName: 'Thứ 6', isWorking: true, startTime: '08:30', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:00' },
  { dayOfWeek: 7, dayName: 'Thứ 7', isWorking: false, startTime: '08:30', endTime: '17:30' },
  { dayOfWeek: 8, dayName: 'Chủ Nhật', isWorking: false, startTime: '08:30', endTime: '17:30' },
];

export const MOCK_EMPLOYEE_DETAILS: Record<string, EmployeeDetailed> = {
  // 1. Nguyễn Minh Đức - Chairman
  '11111111-1111-1111-1111-111111111111': {
    ...MOCK_USERS[0],
    joinedDate: '2020-01-15',
    birthDate: '1980-05-20',
    gender: 'Nam',
    profile: {
      phoneNumber: '0901234567',
      personalEmail: 'duc.nguyen.personal@gmail.com',
      placeOfBirth: 'Hà Nội',
      maritalStatus: 'Đã kết hôn',
      nationality: 'Việt Nam',
      citizenIdNumber: '001080001234',
      socialInsuranceNumber: '7912345678',
      taxIdentificationNumber: '8012345678',
      socialInsuranceStartDate: '2020-02-01',
      emergencyContactName: 'Trần Thu Hà (Vợ)',
      emergencyContactPhone: '0909876543'
    },
    bankAccount: {
      bankName: 'Vietcombank',
      bankAccountNumber: '0011002233445'
    },
    contract: {
      contractType: 'Không xác định thời hạn',
      contractStartDate: '2020-01-15'
    },
    salary: {
      salaryId: 'sal-001',
      baseSalary: 120000000,
      payFrequency: 'MONTHLY',
      workDays: 26,
      startDate: '2020-01-15',
      isActive: true
    },
    weeklySchedule: STANDARD_SCHEDULE
  },

  // 2. Lê Thanh Hương - Director
  '22222222-2222-2222-2222-222222222222': {
    ...MOCK_USERS[1],
    joinedDate: '2020-03-01',
    birthDate: '1985-09-12',
    gender: 'Nữ',
    profile: {
      phoneNumber: '0912345678',
      personalEmail: 'huong.le.personal@gmail.com',
      placeOfBirth: 'Hải Phòng',
      maritalStatus: 'Đã kết hôn',
      nationality: 'Việt Nam',
      citizenIdNumber: '031085002345',
      socialInsuranceNumber: '7923456789',
      taxIdentificationNumber: '8023456789',
      socialInsuranceStartDate: '2020-04-01',
      emergencyContactName: 'Vũ Đức Thịnh (Chồng)',
      emergencyContactPhone: '0919876543'
    },
    bankAccount: {
      bankName: 'Techcombank',
      bankAccountNumber: '1903456789012'
    },
    contract: {
      contractType: 'Không xác định thời hạn',
      contractStartDate: '2020-03-01'
    },
    salary: {
      salaryId: 'sal-002',
      baseSalary: 95000000,
      payFrequency: 'MONTHLY',
      workDays: 26,
      startDate: '2020-03-01',
      isActive: true
    },
    weeklySchedule: STANDARD_SCHEDULE
  },

  // 6. Phạm Thị Cúc - Department Head of HR
  '66666666-6666-6666-6666-666666666666': {
    ...MOCK_USERS[5],
    joinedDate: '2021-02-10',
    birthDate: '1988-11-05',
    gender: 'Nữ',
    profile: {
      phoneNumber: '0934567890',
      personalEmail: 'cuc.pham.personal@gmail.com',
      placeOfBirth: 'Nam Định',
      maritalStatus: 'Đã kết hôn',
      nationality: 'Việt Nam',
      citizenIdNumber: '036088006789',
      socialInsuranceNumber: '7967890123',
      taxIdentificationNumber: '8067890123',
      socialInsuranceStartDate: '2021-03-01',
      emergencyContactName: 'Lê Minh Tuấn (Chồng)',
      emergencyContactPhone: '0939876543'
    },
    bankAccount: {
      bankName: 'MB Bank',
      bankAccountNumber: '0888999666888'
    },
    contract: {
      contractType: 'Không xác định thời hạn',
      contractStartDate: '2021-02-10'
    },
    salary: {
      salaryId: 'sal-006',
      baseSalary: 45000000,
      payFrequency: 'MONTHLY',
      workDays: 26,
      startDate: '2021-02-10',
      isActive: true
    },
    weeklySchedule: STANDARD_SCHEDULE
  },

  // 9. Đỗ Văn Hùng - Department Head of IT
  '99999999-9999-9999-9999-999999999999': {
    ...MOCK_USERS[8],
    joinedDate: '2021-04-01',
    birthDate: '1987-07-25',
    gender: 'Nam',
    profile: {
      phoneNumber: '0945678901',
      personalEmail: 'hung.do.personal@gmail.com',
      placeOfBirth: 'Thái Bình',
      maritalStatus: 'Đã kết hôn',
      nationality: 'Việt Nam',
      citizenIdNumber: '034087009876',
      socialInsuranceNumber: '7998765432',
      taxIdentificationNumber: '8098765432',
      socialInsuranceStartDate: '2021-05-01',
      emergencyContactName: 'Đỗ Thị Lan (Vợ)',
      emergencyContactPhone: '0949876543'
    },
    bankAccount: {
      bankName: 'Vietcombank',
      bankAccountNumber: '0071003456789'
    },
    contract: {
      contractType: 'Không xác định thời hạn',
      contractStartDate: '2021-04-01'
    },
    salary: {
      salaryId: 'sal-009',
      baseSalary: 55000000,
      payFrequency: 'MONTHLY',
      workDays: 26,
      startDate: '2021-04-01',
      isActive: true
    },
    weeklySchedule: [
      { dayOfWeek: 2, dayName: 'Thứ 2', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 3, dayName: 'Thứ 3', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 4, dayName: 'Thứ 4', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 5, dayName: 'Thứ 5', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 6, dayName: 'Thứ 6', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 7, dayName: 'Thứ 7', isWorking: false, startTime: '09:00', endTime: '18:00' },
      { dayOfWeek: 8, dayName: 'Chủ Nhật', isWorking: false, startTime: '09:00', endTime: '18:00' },
    ]
  },

  // 16. Nguyễn Hoàng - Software Engineer
  '00000000-0000-0000-0000-000000000001': {
    ...MOCK_USERS[14],
    joinedDate: '2023-08-01',
    birthDate: '1998-03-14',
    gender: 'Nam',
    profile: {
      phoneNumber: '0978123456',
      personalEmail: 'hoang.nguyen.coder@gmail.com',
      placeOfBirth: 'Đà Nẵng',
      maritalStatus: 'Độc thân',
      nationality: 'Việt Nam',
      citizenIdNumber: '048098005678',
      socialInsuranceNumber: '7934567890',
      taxIdentificationNumber: '8034567890',
      socialInsuranceStartDate: '2023-09-01',
      emergencyContactName: 'Nguyễn Văn Thành (Bố)',
      emergencyContactPhone: '0979876543'
    },
    bankAccount: {
      bankName: 'Techcombank',
      bankAccountNumber: '1909876543210'
    },
    contract: {
      contractType: 'Xác định thời hạn (3 năm)',
      contractStartDate: '2023-08-01',
      contractEndDate: '2026-07-31',
      probationEndDate: '2023-10-01'
    },
    salary: {
      salaryId: 'sal-016',
      baseSalary: 28000000,
      payFrequency: 'MONTHLY',
      workDays: 26,
      startDate: '2023-08-01',
      isActive: true
    },
    weeklySchedule: [
      { dayOfWeek: 2, dayName: 'Thứ 2', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 3, dayName: 'Thứ 3', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 4, dayName: 'Thứ 4', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 5, dayName: 'Thứ 5', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 6, dayName: 'Thứ 6', isWorking: true, startTime: '09:00', endTime: '18:00', restStartTime: '12:00', restEndTime: '13:00' },
      { dayOfWeek: 7, dayName: 'Thứ 7', isWorking: false, startTime: '09:00', endTime: '18:00' },
      { dayOfWeek: 8, dayName: 'Chủ Nhật', isWorking: false, startTime: '09:00', endTime: '18:00' },
    ]
  }
};

// Fallback generator for remaining users
export function getEmployeeDetail(userId: string): EmployeeDetailed {
  if (MOCK_EMPLOYEE_DETAILS[userId]) {
    return MOCK_EMPLOYEE_DETAILS[userId];
  }
  const user = MOCK_USERS.find(u => u.userId === userId) || MOCK_USERS[0];
  return {
    ...user,
    joinedDate: '2022-06-01',
    birthDate: '1995-04-15',
    gender: 'Nam',
    profile: {
      phoneNumber: '0987654321',
      personalEmail: `${user.email.split('@')[0]}@personal.com`,
      placeOfBirth: 'Hà Nội',
      maritalStatus: 'Độc thân',
      nationality: 'Việt Nam',
      citizenIdNumber: '001095009999',
      socialInsuranceNumber: '7999999999',
      taxIdentificationNumber: '8099999999',
      socialInsuranceStartDate: '2022-07-01',
      emergencyContactName: 'Người thân đại diện',
      emergencyContactPhone: '0988888888'
    },
    bankAccount: {
      bankName: 'Vietcombank',
      bankAccountNumber: '1029384756'
    },
    contract: {
      contractType: 'Xác định thời hạn (3 năm)',
      contractStartDate: '2022-06-01',
      contractEndDate: '2025-05-31'
    },
    salary: {
      salaryId: `sal-${user.employeeCode}`,
      baseSalary: 22000000,
      payFrequency: 'MONTHLY',
      workDays: 26,
      startDate: '2022-06-01',
      isActive: true
    },
    weeklySchedule: STANDARD_SCHEDULE
  };
}
