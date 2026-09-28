// ponytail: 1 nguồn duy nhất cho tên phòng ban (DB dùng tên ngắn, enum AI/PBAC dùng tên dài).
// Không gọi API: 7 phòng ban gần như không đổi, gọi API mỗi trang chỉ thêm request vô ích.
export interface DepartmentOption {
  /** Tên chuẩn enum backend/AI (VD: "Information Technology") */
  value: string;
  /** Tên cột departments.name trong DB (VD: "IT") — dùng cho filter chấm công/lương */
  dbName: string;
  /** Nhãn tiếng Việt hiển thị */
  label: string;
}

export const DEPARTMENTS: DepartmentOption[] = [
  { value: 'Executive Leadership', dbName: 'Executive Leadership', label: 'Ban Giám đốc' },
  { value: 'Human Resources', dbName: 'Human Resources', label: 'Nhân sự' },
  { value: 'Information Technology', dbName: 'IT', label: 'Công nghệ thông tin' },
  { value: 'Sales', dbName: 'Sales', label: 'Kinh doanh' },
  { value: 'Marketing & Communication', dbName: 'Marketing & Communication', label: 'Marketing & Truyền thông' },
  { value: 'Finance & Accounting', dbName: 'Finance & Accounting', label: 'Kế toán / Tài chính' },
  { value: 'Customer Support', dbName: 'Customer Support', label: 'Chăm sóc khách hàng' },
];
