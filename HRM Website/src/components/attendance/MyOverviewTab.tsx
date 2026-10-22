'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { Clock, CalendarDays, Wallet, Briefcase, Timer } from 'lucide-react';
import { attendanceService } from '@/services/attendanceService';
import { leaveService } from '@/services/leaveService';
import { overtimeService } from '@/services/overtimeService';
import { dashboardService } from '@/services/dashboardService';
import { AttendanceRecord } from '@/types';

const IGNORED = ['NOT_CHECKED'];

const ON_TIME = ['SUFFICIENT', 'ADJUSTED', 'BUSINESS_TRIP'];
const LATE = ['LATE', 'EARLY', 'LATE_AND_EARLY'];
const LEAVE = ['PAID_LEAVE', 'UNPAID_LEAVE', 'MISSING', 'UNEXCUSED_ABSENCE'];

function monthRange(m: number, y: number) {
  const lastDay = new Date(y, m, 0).getDate();
  const mm = String(m).padStart(2, '0');
  return {
    start: `${y}-${mm}-01`,
    end: `${y}-${mm}-${String(lastDay).padStart(2, '0')}`
  };
}

function overlapDays(from: string, to: string, start: string, end: string): number {
  const s = from < start ? start : from;
  const e = to > end ? end : to;
  if (e < s) return 0;
  return Math.round((new Date(e).getTime() - new Date(s).getTime()) / 86400000) + 1;
}

// ponytail: tổng quan cá nhân — chỉ số liệu của chính mình (attendances + đơn duyệt + dashboard).
// Không dùng API company-wide nào ở đây.
export default function MyOverviewTab() {
  const now = new Date();
  const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const [month, setMonth] = useState(prev.getMonth() + 1);
  const [year, setYear] = useState(prev.getFullYear());
  const [records, setRecords] = useState<AttendanceRecord[]>([]);
  const [paidDays, setPaidDays] = useState(0);
  const [unpaidDays, setUnpaidDays] = useState(0);
  const [remainingLeave, setRemainingLeave] = useState(0);
  const [otList, setOtList] = useState<{ date: string; hours: number }[]>([]);
  const [leaveList, setLeaveList] = useState<{ from: string; to: string; days: number; paid: number }[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async (m: number, y: number) => {
    setLoading(true);
    try {
      const { start, end } = monthRange(m, y);
      const [att, leaves, summary, ots] = await Promise.all([
        attendanceService.getMyAttendances({ startDate: start, endDate: end, size: 100 }),
        leaveService.getMyLeaves({}).catch(() => ({ content: [] as any[] })),
        dashboardService.getSummary().catch(() => null),
        overtimeService.getMyOvertimes({ size: 100 }).catch(() => ({ content: [] as any[] }))
      ]);
      setRecords(Array.isArray(att?.content) ? att.content : []);
      let paid = 0;
      let unpaid = 0;
      const list: { from: string; to: string; days: number; paid: number }[] = [];
      for (const l of (leaves as any)?.content || []) {
        if (String(l.status || '').toLowerCase() !== 'accepted') continue;
        const days = overlapDays(l.fromDate, l.toDate, start, end);
        if (days <= 0) continue;
        const total = Math.max(1, Math.round((new Date(l.toDate).getTime() - new Date(l.fromDate).getTime()) / 86400000) + 1);
        const p = Math.min(days, Math.round((l.paidLeaveDays || 0) * (days / total)));
        paid += p;
        unpaid += days - p;
        list.push({
          from: l.fromDate < start ? start : l.fromDate,
          to: l.toDate > end ? end : l.toDate,
          days,
          paid: p
        });
      }
      setPaidDays(paid);
      setUnpaidDays(unpaid);
      list.sort((a, b) => (a.from < b.from ? 1 : -1));
      setLeaveList(list);
      setRemainingLeave(summary?.monthSummary?.remainingLeaveDays ?? 0);
      // OT đã duyệt trong kỳ — ponytail: key giờ đúng là totalActualHours/totalApprovedHours
      // (actualHours/registeredHours chỉ là fallback vì type frontend đặt tên khác API thật)
      const ot: { date: string; hours: number }[] = [];
      for (const o of (ots as any)?.content || []) {
        if (String(o.status || '').toLowerCase() !== 'accepted') continue;
        if (!o.approvedDate || o.approvedDate < start || o.approvedDate > end) continue;
        // ponytail: DTO my-records không trả totalActualHours — mapOtItem đã dồn vào
        // actualHours/registeredHours, nên dùng || (0 phải rơi qua, ?? sẽ kẹt ở 0)
        const h = Number(o.actualHours || o.registeredHours || o.totalActualHours || o.totalApprovedHours || 0) || 0;
        if (h > 0) ot.push({ date: o.approvedDate, hours: Math.round(h * 10) / 10 });
      }
      setOtList(ot);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Mặc định kỳ gần nhất chính mình có công THẬT (bỏ qua dòng NOT_CHECKED cron tạo sẵn —
    // đầu tháng mới vào toàn 0 thì tự lùi về tháng trước)
    attendanceService
      .getMyAttendances({ size: 100 })
      .then(res => {
        const found = (res?.content || []).find(r => r?.workDate && !IGNORED.includes(r.status));
        if (found?.workDate) {
          const d = new Date(found.workDate);
          setMonth(d.getMonth() + 1);
          setYear(d.getFullYear());
          load(d.getMonth() + 1, d.getFullYear());
        } else {
          load(month, year);
        }
      })
      .catch(() => load(month, year));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const changePeriod = (m: number, y: number) => {
    setMonth(m);
    setYear(y);
    load(m, y);
  };

  const fmtD = (d: Date) => `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;
  const fmtKey = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  const weeks = useMemo(() => {
    const { start, end } = monthRange(month, year);
    const out: { label: string; from: string; to: string; onTime: number; late: number; leave: number; ot: number }[] = [];
    let cursor = new Date(start + 'T00:00:00');
    const endD = new Date(end + 'T00:00:00');
    let idx = 1;
    const byDate = new Map(records.map(r => [r.workDate, r.status]));
    while (cursor <= endD) {
      const weekEnd = new Date(Math.min(cursor.getTime() + 6 * 86400000, endD.getTime()));
      let onTime = 0;
      let late = 0;
      let leave = 0;
      for (let d = new Date(cursor); d <= weekEnd; d = new Date(d.getTime() + 86400000)) {
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
        const st = byDate.get(key);
        if (!st) continue;
        if (ON_TIME.includes(st)) onTime++;
        else if (LATE.includes(st)) late++;
        else if (LEAVE.includes(st)) leave++;
      }
      const ot = Math.round(otList.filter(o => o.date >= fmtKey(cursor) && o.date <= fmtKey(weekEnd)).reduce((a, o) => a + o.hours, 0) * 10) / 10;
      out.push({ label: `Tuần ${idx++}`, from: fmtD(cursor), to: fmtD(weekEnd), onTime, late, leave, ot });
      cursor = new Date(weekEnd.getTime() + 86400000);
    }
    return out;
  }, [records, otList, month, year]);

  const maxWeek = Math.max(1, ...weeks.map(w => w.onTime + w.late + w.leave));
  const workDays = records.filter(r => ON_TIME.includes(r.status) || LATE.includes(r.status)).length;
  const lateCount = records.filter(r => LATE.includes(r.status)).length;
  const leaveDays = paidDays + unpaidDays;
  const periodLabel = `Tháng ${month}/${year}`;
  const periodKey = `${year}-${month}`;
  const otHours = Math.round(weeks.reduce((a, w) => a + w.ot, 0) * 10) / 10;
  const otMax = Math.max(1, ...weeks.map(w => w.ot));

  // Phân tích loại nghỉ cá nhân — có lương/không lương từ đơn duyệt,
  // quên/vắng/công tác từ chấm công
  const myMissing = records.filter(r => r.status === 'MISSING').length;
  const myUnexcused = records.filter(r => r.status === 'UNEXCUSED_ABSENCE').length;
  const myBusiness = records.filter(r => r.status === 'BUSINESS_TRIP').length;
  const leaveSlices = [
    { label: 'Nghỉ phép có lương', count: paidDays, color: '#f97316' },
    { label: 'Nghỉ không lương', count: unpaidDays, color: '#10b981' },
    { label: 'Quên chấm công', count: myMissing, color: '#06b6d4' },
    { label: 'Vắng không phép', count: myUnexcused, color: '#f59e0b' },
    { label: 'Công tác', count: myBusiness, color: '#8b5cf6' }
  ];
  const leaveTotal = leaveSlices.reduce((a, s) => a + s.count, 0);

  const cards = [
    { label: 'Ngày công', value: String(workDays), sub: `${periodLabel}`, icon: Briefcase, bg: 'bg-blue-50 text-blue-600' },
    { label: 'Đi muộn, về sớm', value: String(lateCount), sub: 'Lượt trong kỳ', icon: Clock, bg: 'bg-amber-50 text-amber-600' },
    { label: 'Ngày nghỉ', value: String(leaveDays), sub: `Có lương ${paidDays} · Không lương ${unpaidDays}`, icon: CalendarDays, bg: 'bg-sky-50 text-sky-600' },
    { label: 'Giờ tăng ca', value: `${otHours}h`, sub: `OT đã duyệt ${periodLabel}`, icon: Timer, bg: 'bg-orange-50 text-orange-600' },
    { label: 'Phép năm còn lại', value: String(remainingLeave), sub: 'Số dư hiện tại', icon: Wallet, bg: 'bg-teal-50 text-teal-600' }
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center gap-2 text-xs">
        <span className="font-bold text-slate-700">Kỳ báo cáo:</span>
        <select
          value={month}
          onChange={e => changePeriod(Number(e.target.value), year)}
          className="rounded-xl border border-slate-200 bg-white px-2.5 py-1.5 font-semibold text-slate-700 focus:border-orange-500 focus:outline-hidden"
        >
          {Array.from({ length: 12 }, (_, i) => i + 1).map(m => (
            <option key={`${periodKey}-m-${m}`} value={m}>Tháng {m}</option>
          ))}
        </select>
        <select
          value={year}
          onChange={e => changePeriod(month, Number(e.target.value))}
          className="rounded-xl border border-slate-200 bg-white px-2.5 py-1.5 font-semibold text-slate-700 focus:border-orange-500 focus:outline-hidden"
        >
          {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - 2 + i).map(y => (
            <option key={`${periodKey}-y-${y}`} value={y}>Năm {y}</option>
          ))}
        </select>
        {loading && <span className="text-slate-400">Đang tải...</span>}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4">
        {cards.map(c => {
          const Icon = c.icon;
          return (
            <div key={c.label} className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
              <span className="text-xs font-bold text-slate-700">{c.label}</span>
              <div className="mt-3 mb-1 flex items-baseline justify-between">
                <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{c.value}</span>
                <div className={`h-10 w-10 rounded-full flex items-center justify-center ${c.bg}`}>
                  <Icon className="h-5 w-5" />
                </div>
              </div>
              <p className="text-[11px] text-slate-400">{c.sub}</p>
            </div>
          );
        })}
      </div>

      {/* ponytail: 2 biểu đồ chung 1 hàng (chia đôi màn hình), mobile tự xếp dọc */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
      <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
        <h3 className="text-sm font-bold text-slate-900">Chuyên cần theo tuần</h3>
        <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Đơn vị: ngày công của bạn</p>
        {loading ? (
          <p className="mt-6 text-xs text-slate-400">Đang tải...</p>
        ) : (
          <div className="mt-6 w-full overflow-x-auto">
            <div className="min-w-[480px]">
              <div className="flex items-center gap-4 text-[11px] font-semibold mb-3">
                <span className="flex items-center gap-1.5 text-slate-600"><span className="w-2.5 h-2.5 rounded-sm bg-emerald-500 inline-block" /> Đúng giờ</span>
                <span className="flex items-center gap-1.5 text-slate-600"><span className="w-2.5 h-2.5 rounded-sm bg-amber-500 inline-block" /> Muộn / sớm</span>
                <span className="flex items-center gap-1.5 text-slate-600"><span className="w-2.5 h-2.5 rounded-sm bg-sky-500 inline-block" /> Nghỉ</span>
              </div>
              <svg viewBox="0 0 540 240" className="w-full h-56 select-none">
                {[0, 0.25, 0.5, 0.75, 1].map(f => {
                  const val = Math.round(maxWeek * f);
                  const y = 190 - f * 160;
                  return (
                    <g key={f}>
                      <text x="24" y={y + 3} textAnchor="end" className="text-[9px] fill-slate-400 font-mono">{val}</text>
                      <line x1="32" y1={y} x2="530" y2={y} stroke="#f1f5f9" strokeDasharray="3 3" strokeWidth="1" />
                    </g>
                  );
                })}
                {weeks.map((w, idx) => {
                  const gap = 500 / Math.max(weeks.length, 1);
                  const x = 45 + idx * gap;
                  const segs = [
                    { v: w.onTime, color: '#10b981' },
                    { v: w.late, color: '#f59e0b' },
                    { v: w.leave, color: '#0ea5e9' }
                  ];
                  let yCursor = 190;
                  return (
                    <g key={w.label}>
                      <title>{`${w.label}: ${w.from} – ${w.to}\nĐúng giờ: ${w.onTime} · Muộn/sớm: ${w.late} · Nghỉ: ${w.leave}`}</title>
                      {segs.map((s, si) => {
                        const h = (s.v / maxWeek) * 160;
                        yCursor -= h;
                        if (h <= 0) return null;
                        return <rect key={si} x={x} y={yCursor} width={26} height={h} fill={s.color} rx={si === 0 ? 3 : 0} />;
                      })}
                      <text x={x + 13} y="208" textAnchor="middle" className="text-[9px] font-semibold fill-slate-500">{w.label}</text>
                      <text x={x + 13} y={yCursor - 5} textAnchor="middle" className="text-[9px] font-bold fill-slate-600 font-mono">
                        {w.onTime + w.late + w.leave > 0 ? w.onTime + w.late + w.leave : ''}
                      </text>
                    </g>
                  );
                })}
              </svg>
            </div>
          </div>
        )}
      </div>

      <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
        <h3 className="text-sm font-bold text-slate-900">Tăng ca theo tuần</h3>
        <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Tổng {otHours} giờ OT đã duyệt</p>
        {loading ? (
          <p className="mt-6 text-xs text-slate-400">Đang tải...</p>
        ) : (
          <div className="mt-6 w-full overflow-x-auto">
            <div className="min-w-[480px]">
              <svg viewBox="0 0 540 240" className="w-full h-56 select-none">
                {[0, 0.25, 0.5, 0.75, 1].map(f => {
                  const val = Math.round(otMax * f * 10) / 10;
                  const y = 190 - f * 160;
                  return (
                    <g key={f}>
                      <text x="30" y={y + 3} textAnchor="end" className="text-[9px] fill-slate-400 font-mono">{val}</text>
                      <line x1="38" y1={y} x2="530" y2={y} stroke="#f1f5f9" strokeDasharray="3 3" strokeWidth="1" />
                    </g>
                  );
                })}
                {weeks.map((w, idx) => {
                  const gap = 480 / Math.max(weeks.length, 1);
                  const bw = Math.min(40, gap * 0.5);
                  const x = 50 + idx * gap + (gap - bw) / 2;
                  const bh = (w.ot / otMax) * 160;
                  const y = 190 - bh;
                  return (
                    <g key={w.label}>
                      <title>{`${w.label}: ${w.from} – ${w.to}\nOT đã duyệt: ${w.ot} giờ`}</title>
                      {bh > 0 && <rect x={x} y={y} width={bw} height={bh} rx="4" fill="#f97316" />}
                      <text x={x + bw / 2} y={y - 5} textAnchor="middle" className="text-[10px] font-bold fill-slate-700 font-mono">{w.ot > 0 ? w.ot : ''}</text>
                      <text x={x + bw / 2} y="208" textAnchor="middle" className="text-[9px] font-semibold fill-slate-500">{w.label}</text>
                    </g>
                  );
                })}
              </svg>
            </div>
          </div>
        )}
      </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
      <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
        <h3 className="text-sm font-bold text-slate-900">Phân tích loại nghỉ</h3>
        <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Đơn nghỉ của bạn + trạng thái chấm công</p>
        {loading ? (
          <p className="mt-6 text-xs text-slate-400">Đang tải...</p>
        ) : leaveTotal === 0 ? (
          <p className="mt-6 text-xs text-slate-400">Tháng này bạn chưa có ngày nghỉ nào.</p>
        ) : (
          <div className="mt-4 flex flex-col sm:flex-row items-center justify-around gap-4 py-2">
            <div className="relative flex items-center justify-center">
              <svg width="180" height="180" viewBox="0 0 180 180" className="transform -rotate-90 select-none">
                <circle cx="90" cy="90" r="65" stroke="#f1f5f9" strokeWidth="24" fill="transparent" />
                {(() => {
                  const c = 2 * Math.PI * 65;
                  let acc = 0;
                  return leaveSlices.map(s => {
                    if (s.count <= 0) return null;
                    const len = (s.count / leaveTotal) * c;
                    const el = (
                      <circle key={s.label} cx="90" cy="90" r="65" stroke={s.color} strokeWidth="24" fill="transparent"
                        strokeDasharray={`${len} ${c - len}`} strokeDashoffset={-acc}>
                        <title>{`${s.label}: ${s.count} ngày (${Math.round((s.count / leaveTotal) * 1000) / 10}%)`}</title>
                      </circle>
                    );
                    acc += len;
                    return el;
                  });
                })()}
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-2xl font-black text-slate-900 tracking-tight">{leaveTotal}</span>
                <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Ngày nghỉ</span>
              </div>
            </div>
            <div className="space-y-2.5 w-full sm:w-auto">
              {leaveSlices.map(s => (
                <div key={s.label} className="flex items-center justify-between gap-4 text-xs">
                  <div className="flex items-center gap-2">
                    <span className="h-3 w-3 rounded-full" style={{ backgroundColor: s.color }} />
                    <span className="font-medium text-slate-700">{s.label}</span>
                  </div>
                  <div className="flex items-center gap-2 font-mono">
                    <span className="font-bold text-slate-900">{s.count}</span>
                    <span className="text-[11px] text-slate-400">({leaveTotal > 0 ? Math.round((s.count / leaveTotal) * 1000) / 10 : 0}%)</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
        <h3 className="text-sm font-bold text-slate-900">Chi tiết đơn nghỉ trong kỳ</h3>
        <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Các đơn đã duyệt cấu thành số liệu trên</p>
        {loading ? (
          <p className="mt-6 text-xs text-slate-400">Đang tải...</p>
        ) : leaveList.length === 0 ? (
          <p className="mt-6 text-xs text-slate-400">Tháng này bạn chưa có đơn nghỉ nào được duyệt.</p>
        ) : (
          <div className="mt-4 space-y-2.5 max-h-56 overflow-y-auto pr-1">
            {leaveList.map((l, i) => (
              <div key={i} className="flex items-center justify-between gap-3 text-xs border border-slate-100 rounded-xl px-3 py-2.5 hover:bg-slate-50 transition">
                <div className="min-w-0">
                  <p className="font-bold text-slate-900 font-mono">{l.from.slice(8, 10)}/{l.from.slice(5, 7)} → {l.to.slice(8, 10)}/{l.to.slice(5, 7)}</p>
                  <p className="text-[11px] text-slate-400">Có lương {l.paid} / Không lương {l.days - l.paid}</p>
                </div>
                <span className="shrink-0 text-xs font-bold text-sky-600 bg-sky-50 px-2.5 py-1 rounded-lg border border-sky-200/60 font-mono">
                  {l.days} ngày
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
      </div>
    </div>
  );
}
