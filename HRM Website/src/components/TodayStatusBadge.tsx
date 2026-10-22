const dot = (cls: string) => <span className={`h-1.5 w-1.5 shrink-0 rounded-full ${cls}`} />;
const shell = (tone: string) =>
  `inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[11px] font-bold border ${tone}`;

// Đã check-out nhưng backend trả nhiều trạng thái (đúng giờ / trễ / về sớm / đã điều chỉnh).
// ponytail: gom chung vì badge chỉ cần phân biệt "đã xong" — chi tiết trễ/sớm hiện ở bảng chấm công.
// Muốn tách từng loại thì sửa ở đây, đừng nhân bản lại ở 2 trang.
const CLOCKED_OUT = ['SUFFICIENT', 'LATE', 'EARLY', 'LATE_AND_EARLY', 'ADJUSTED'];
const ABSENT = ['ABSENT', 'MISSING', 'UNEXCUSED_ABSENCE'];
const ON_LEAVE = ['ON_LEAVE', 'PAID_LEAVE', 'UNPAID_LEAVE'];

export type TodayOvertimeStatus = 'OVERTIMING' | 'OVERTIME_DONE' | 'NONE';

/**
 * Badge trạng thái chấm công hôm nay + tăng ca.
 *
 * Trước đây chỉ biết 4 giá trị (WORKING/ON_LEAVE/NOT_CHECKED/ABSENT) nên:
 *  - ai đã đi về bị hiện nhầm "Chưa chấm công"
 *  - hôm nay không có bản ghi (nghỉ) cũng bị hiện "Chưa chấm công"
 * Backend giờ truyền thẳng attendances.status, thêm "DAY_OFF" khi không có bản ghi,
 * vì cron chỉ tạo record cho ngày làm việc.
 */
export default function TodayStatusBadge({
  status,
  overtime
}: {
  status?: string;
  overtime?: string | null;
}) {
  const s = String(status || 'NOT_CHECKED');
  const ot = String(overtime || 'NONE');

  // Tăng ca ghi đè trạng thái chấm công vì là thông tin mới nhất trong ngày.
  if (ot === 'OVERTIMING') {
    return (
      <span className={shell('bg-violet-50 text-violet-700 border-violet-200')}>
        {dot('bg-violet-500 animate-pulse')}
        <span>Đang tăng ca</span>
      </span>
    );
  }

  let body: React.ReactNode;
  let tone: string;

  if (ot === 'OVERTIME_DONE') {
    tone = 'bg-violet-50 text-violet-700 border-violet-200';
    body = (<><span className="h-1.5 w-1.5 shrink-0 rounded-full bg-violet-500" /><span>Đã kết thúc tăng ca</span></>);
  } else if (s === 'WORKING') {
    tone = 'bg-emerald-50 text-emerald-700 border-emerald-200';
    body = (<>{dot('bg-emerald-500 animate-pulse')}<span>Đang làm việc</span></>);
  } else if (ON_LEAVE.includes(s)) {
    tone = 'bg-amber-50 text-amber-700 border-amber-200';
    body = (<>{dot('bg-amber-500')}<span>Xin nghỉ phép</span></>);
  } else if (s === 'HOLIDAY') {
    tone = 'bg-rose-50 text-rose-700 border-rose-200';
    body = (<>{dot('bg-rose-400')}<span>Nghỉ lễ</span></>);
  } else if (s === 'BUSINESS_TRIP') {
    tone = 'bg-cyan-50 text-cyan-700 border-cyan-200';
    body = (<>{dot('bg-cyan-500')}<span>Đi công tác</span></>);
  } else if (ABSENT.includes(s)) {
    tone = 'bg-red-50 text-red-700 border-red-200';
    body = (<>{dot('bg-red-500')}<span>Vắng mặt</span></>);
  } else if (CLOCKED_OUT.includes(s)) {
    tone = 'bg-blue-50 text-blue-700 border-blue-200';
    body = (<>{dot('bg-blue-500')}<span>Đã đi về</span></>);
  } else if (s === 'DAY_OFF') {
    // Không có bản ghi chấm công => hôm nay là ngày nghỉ.
    tone = 'bg-slate-100 text-slate-600 border-slate-200';
    body = (<>{dot('bg-slate-400')}<span>Ngày nghỉ</span></>);
  } else {
    tone = 'bg-slate-100 text-slate-600 border-slate-200';
    body = (<>{dot('bg-slate-400')}<span>Chưa chấm công</span></>);
  }

  return <span className={shell(tone)}>{body}</span>;
}
