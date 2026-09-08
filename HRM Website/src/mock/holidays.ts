import { HolidayItem } from '@/types';

export const VIETNAMESE_HOLIDAYS: HolidayItem[] = [
  { holidayId: 'h1', date: '2026-01-01', description: 'Tết Dương Lịch' },
  { holidayId: 'h2', date: '2026-02-16', description: 'Tết Nguyên Đán (29 Tết)' },
  { holidayId: 'h3', date: '2026-02-17', description: 'Tết Nguyên Đán (30 Tết)' },
  { holidayId: 'h4', date: '2026-02-18', description: 'Tết Nguyên Đán (Mùng 1)' },
  { holidayId: 'h5', date: '2026-02-19', description: 'Tết Nguyên Đán (Mùng 2)' },
  { holidayId: 'h6', date: '2026-02-20', description: 'Tết Nguyên Đán (Mùng 3)' },
  { holidayId: 'h7', date: '2026-04-26', description: 'Giỗ Tổ Hùng Vương' },
  { holidayId: 'h8', date: '2026-04-30', description: 'Ngày Giải phóng miền Nam' },
  { holidayId: 'h9', date: '2026-05-01', description: 'Ngày Quốc tế Lao động' },
  { holidayId: 'h10', date: '2026-09-02', description: 'Ngày Quốc Khánh' },
  { holidayId: 'h11', date: '2026-09-03', description: 'Nghỉ liền kề Quốc Khánh' },
];

export function isHoliday(dateStr: string): HolidayItem | undefined {
  return VIETNAMESE_HOLIDAYS.find(h => h.date === dateStr);
}
