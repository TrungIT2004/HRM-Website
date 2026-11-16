// ponytail: Date local (toISOString lệch ngày ở +07) — giữ đúng convention của trang chấm công.
// Khoảng ngày dùng chung cho nút "Xem nhanh" ở Chấm công / Nghỉ phép / Làm thêm giờ.

/** 'YYYY-MM-DD' theo giờ địa phương (input[type=date] nhận đúng định dạng này). */
export const toLocalISO = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

export const DATE_PRESETS = [
  ['today', 'Hôm nay'],
  ['week', 'Tuần này'],
  ['month', 'Tháng này']
] as const;

export type DatePreset = (typeof DATE_PRESETS)[number][0];

export const dateRangeFor = (preset: DatePreset): { startDate: string; endDate: string } => {
  const now = new Date();
  if (preset === 'today') {
    const t = toLocalISO(now);
    return { startDate: t, endDate: t };
  }
  if (preset === 'week') {
    const monday = new Date(now);
    monday.setDate(now.getDate() - ((now.getDay() + 6) % 7));
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    return { startDate: toLocalISO(monday), endDate: toLocalISO(sunday) };
  }
  return {
    startDate: toLocalISO(new Date(now.getFullYear(), now.getMonth(), 1)),
    endDate: toLocalISO(new Date(now.getFullYear(), now.getMonth() + 1, 0))
  };
};

/** Ghi range vào input[type=date] của form — form lọc dùng uncontrolled input nên phải set DOM. */
export const fillDateInputs = (
  form: HTMLFormElement | null,
  range: { startDate: string; endDate: string },
  names: [string, string] = ['startDate', 'endDate']
) => {
  if (!form) return;
  const [fromName, toName] = names;
  const from = form.elements.namedItem(fromName) as HTMLInputElement | null;
  const to = form.elements.namedItem(toName) as HTMLInputElement | null;
  if (from) from.value = range.startDate;
  if (to) to.value = range.endDate;
};
