'use client';

import React, { useEffect, useMemo, useState } from 'react';
import {
  Clock,
  Calendar,
  CalendarDays,
  BarChart3,
  CheckCircle2,
  XCircle,
  FileCheck,
} from 'lucide-react';
import { attendanceService } from '@/services/attendanceService';
import MomLine from '@/components/MomLine';

interface AttendanceOverviewTabProps {
  onNavigateToTab?: (tab: string) => void;
  /** scope từ tabs Công ty/Phòng ban của workspace — dept thì backend chỉ tổng hợp phòng mình */
  scope?: 'dept' | 'company';
  deptName?: string;
}

interface OverviewData {
  periodStart?: string;
  periodEnd?: string;
  lateEarlyCount: number;
  actualLeaveCount: number;
  plannedLeaveCount: number;
  leaveByDept: { department: string; days: number }[];
  weeklyTrend: { label: string; days: number }[];
  leaveTypes: { label: string; count: number; percent: number }[];
  topAbsentees: { userId?: string; fullName: string; department: string; days: number }[];
  totalLeaveDays: number;
  otTotalHours?: number;
  otByDept?: { department: string; hours: number }[];
  topOt?: { userId?: string; fullName: string; department: string; hours: number }[];
  lateByDept?: { department: string; days: number }[];
  lateTrend?: { label: string; days: number }[];
  otSubmitted?: number;
  otApproved?: number;
  otRejected?: number;
  otTrend?: { label: string; days: number }[];
  leaveApproved?: number;
  leaveRejected?: number;
  totalWorkDays?: number;
  lateCount?: number;
  earlyCount?: number;
  onTimeCount?: number;
  statusCounts?: Record<string, number>;
  missingTop?: { userId?: string; fullName: string; department: string; days: number }[];
}

const PALETTE = ['#f97316', '#10b981', '#06b6d4', '#f59e0b', '#8b5cf6', '#ec4899', '#6366f1', '#84cc16', '#ef4444', '#14b8a6'];

function initialsOf(name: string) {
  const parts = (name || '').trim().split(/\s+/);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

export default function AttendanceOverviewTab({ onNavigateToTab, scope = 'company', deptName }: AttendanceOverviewTabProps) {
  const [data, setData] = useState<OverviewData | null>(null);
  const [prevData, setPrevData] = useState<OverviewData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  // ponytail: ky mac dinh = thang truoc (du lieu thang truoc chot xong) — doi select de xem ky khac
  const now = new Date();
  const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const [month, setMonth] = useState<number>(prev.getMonth() + 1);
  const [year, setYear] = useState<number>(prev.getFullYear());
  const [periodKey, setPeriodKey] = useState<string>('latest');

  // ponytail: 3 tab nội trang theo nghiệp vụ (chấm công / nghỉ / OT) — mỗi tab chỉ dữ liệu liên quan
  const [view, setView] = useState<'attendance' | 'leave' | 'ot'>('attendance');

  const fetchOverview = (m: number, y: number, explicit: boolean, effScope: 'dept' | 'company' = scope) => {
    setLoading(true);
    setError('');
    const params = explicit
      ? (() => {
          const lastDay = new Date(y, m, 0).getDate();
          const mm = String(m).padStart(2, '0');
          return { startDate: `${y}-${mm}-01`, endDate: `${y}-${mm}-${String(lastDay).padStart(2, '0')}`, ...(effScope === 'dept' ? { scope: 'dept' as const } : {}) };
        })()
      : (effScope === 'dept' ? { scope: 'dept' as const } : {});
    attendanceService
      .getOverview(params)
      .then(res => {
        setData(res);
        let pm = m;
        let py = y;
        if (res?.periodStart) {
          const d = new Date(res.periodStart);
          pm = d.getMonth() + 1;
          py = d.getFullYear();
          setMonth(pm);
          setYear(py);
        }
        // ponytail: so MoM thi goi them thang truoc — loi thi bo qua, giu so lieu thang nay
        const pp = pm === 1 ? { m: 12, y: py - 1 } : { m: pm - 1, y: py };
        const lastDay = new Date(pp.y, pp.m, 0).getDate();
        const mm = String(pp.m).padStart(2, '0');
        attendanceService
          .getOverview({ startDate: `${pp.y}-${mm}-01`, endDate: `${pp.y}-${mm}-${String(lastDay).padStart(2, '0')}`, ...(effScope === 'dept' ? { scope: 'dept' as const } : {}) })
          .then(setPrevData)
          .catch(() => setPrevData(null));
      })
      .catch((e: any) => setError(e?.response?.data?.msg || e?.message || 'Không tải được tổng quan'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchOverview(month, year, false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ponytail: đổi scope Công ty/Phòng ban thì tải lại đúng kỳ đang xem
  useEffect(() => {
    fetchOverview(month, year, true, scope);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [scope]);

  const handlePeriodChange = (m: number, y: number) => {
    setMonth(m);
    setYear(y);
    setPeriodKey(`${y}-${m}`);
    fetchOverview(m, y, true);
  };

  const maxDeptDays = useMemo(() => {
    const m = Math.max(1, ...(data?.leaveByDept.map(d => d.days) || [1]));
    return Math.ceil(m * 1.15);
  }, [data]);

  const maxWeek = useMemo(() => Math.max(1, ...(data?.weeklyTrend.map(w => w.days) || [1])), [data]);
  const typeTotal = useMemo(
    () => (data?.leaveTypes || []).reduce((a, b) => a + b.count, 0),
    [data]
  );

  // ponytail: mọi useMemo phải đứng trước return sớm (Rules of Hooks)
  // Khoảng ngày từng bucket tuần — cùng cách cắt 7 ngày từ periodStart như backend
  const weekRanges = useMemo(() => {
    if (!data?.periodStart || !data?.periodEnd) return [] as { label: string; range: string }[];
    const fmt = (d: Date) => `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;
    const out: { label: string; range: string }[] = [];
    let c = new Date(data.periodStart + 'T00:00:00');
    const e = new Date(data.periodEnd + 'T00:00:00');
    let i = 1;
    while (c <= e) {
      const we = new Date(Math.min(c.getTime() + 6 * 86400000, e.getTime()));
      out.push({ label: `Tuần ${i++}`, range: `${fmt(c)} – ${fmt(we)}` });
      c = new Date(we.getTime() + 86400000);
    }
    return out;
  }, [data]);

  if (loading) {
    return (
      <div className="rounded-2xl bg-white border border-slate-200 p-8 text-center text-xs text-slate-500">
        <span className="inline-block h-5 w-5 rounded-full border-2 border-orange-500 border-t-transparent animate-spin align-middle mr-2" />
        Đang tải tổng quan chấm công từ máy chủ...
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="rounded-2xl bg-rose-50 border border-rose-200 p-6 text-xs text-rose-700 font-semibold">
        {error || 'Không có dữ liệu tổng quan.'} — kiểm tra backend GET /api/attendances/overview.
      </div>
    );
  }

  // Nhãn kỳ lấy từ dữ liệu thật backend trả về (periodStart), không lấy tháng hiện tại
  const periodDate = data.periodStart ? new Date(data.periodStart) : new Date(`${year}-${String(month).padStart(2, '0')}-01`);
  const periodLabel = `Tháng ${periodDate.getMonth() + 1}/${periodDate.getFullYear()}`;
  const circumference = 2 * Math.PI * 65;
  let acc = 0;
  const donutSlices = (data.leaveTypes || []).map((t, i) => {
    const frac = typeTotal > 0 ? t.count / typeTotal : 0;
    const len = frac * circumference;
    const s = { ...t, len, offset: -acc, color: PALETTE[i % PALETTE.length] };
    acc += len;
    return s;
  });

  // Weekly bars from real values (same style as dept widget)
  const weekMax = Math.max(1, ...(data.weeklyTrend || []).map(w => w.days));
  const weekRangeOf = (label: string) => weekRanges.find(w => w.label === label)?.range ?? '';

  const otByDept = data.otByDept || [];
  const topOt = data.topOt || [];
  const otMax = Math.max(1, ...otByDept.map(d => d.hours));
  const otTrend = data.otTrend || [];
  const otWeekMax = Math.max(1, ...otTrend.map(w => w.days));

  // Donut 6 trạng thái chấm công — thứ tự và màu cố định
  const STATUS_DONUT = [
    { key: 'SUFFICIENT', label: 'Đúng giờ', color: '#10b981' },
    { key: 'LATE', label: 'Đi trễ', color: '#f59e0b' },
    { key: 'EARLY', label: 'Về sớm', color: '#f97316' },
    { key: 'LATE_AND_EARLY', label: 'Đi trễ & về sớm', color: '#f43f5e' },
    { key: 'NOT_CHECKED', label: 'Chưa điểm danh', color: '#94a3b8' },
    { key: 'MISSING', label: 'Quên chấm công', color: '#06b6d4' }
  ];
  const statusSlices = STATUS_DONUT.map(s => ({
    ...s,
    count: data.statusCounts?.[s.key] ?? 0
  }));
  const statusTotal = statusSlices.reduce((a, s) => a + s.count, 0);
  const missingTop = data.missingTop || [];
  // Donut duyệt/từ chối OT
  const otApprovalTotal = (data.otApproved ?? 0) + (data.otRejected ?? 0);
  const otApprovalSlices = (() => {
    const c = 2 * Math.PI * 65;
    let acc = 0;
    return [
      { label: 'Đã duyệt', count: data.otApproved ?? 0, color: '#10b981' },
      { label: 'Từ chối', count: data.otRejected ?? 0, color: '#f43f5e' }
    ].map(s => {
      const frac = otApprovalTotal > 0 ? s.count / otApprovalTotal : 0;
      const len = frac * c;
      const el = { ...s, len, offset: -acc, percent: otApprovalTotal > 0 ? Math.round(frac * 1000) / 10 : 0 };
      acc += len;
      return el;
    });
  })();
  const lateByDept = data.lateByDept || [];
  const lateTrend = data.lateTrend || [];
  const lateMax = Math.max(1, ...lateByDept.map(d => d.days));
  const lateWeekMax = Math.max(1, ...lateTrend.map(w => w.days));

  return (
    <div className="space-y-6">
      {/* Tab nghiệp vụ lên đầu trang, kéo dài full-width */}
      <div className="flex items-stretch gap-1 bg-slate-100 p-1.5 rounded-2xl border border-slate-200/80 w-full max-w-2xl text-sm font-bold">
        {([
          ['attendance', 'Chấm công'],
          ['leave', 'Nghỉ phép'],
          ['ot', 'Tăng ca']
        ] as const).map(([k, label]) => (
          <button
            key={k}
            onClick={() => setView(k)}
            className={`flex-1 px-6 py-2.5 rounded-xl transition cursor-pointer ${
              view === k ? 'bg-white text-orange-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            {label}
          </button>
        ))}
      </div>
      {/* Chọn kỳ báo cáo — mặc định kỳ gần nhất có công */}
      <div className="flex flex-wrap items-center gap-2 text-xs">
        <span className="font-bold text-slate-700">Kỳ báo cáo:</span>
        <select
          value={month}
          onChange={e => handlePeriodChange(Number(e.target.value), year)}
          className="rounded-xl border border-slate-200 bg-white px-2.5 py-1.5 font-semibold text-slate-700 focus:border-orange-500 focus:outline-hidden"
        >
          {Array.from({ length: 12 }, (_, i) => i + 1).map(m => (
            <option key={`${periodKey}-m-${m}`} value={m}>Tháng {m}</option>
          ))}
        </select>
        <select
          value={year}
          onChange={e => handlePeriodChange(month, Number(e.target.value))}
          className="rounded-xl border border-slate-200 bg-white px-2.5 py-1.5 font-semibold text-slate-700 focus:border-orange-500 focus:outline-hidden"
        >
          {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - 2 + i).map(y => (
            <option key={`${periodKey}-y-${y}`} value={y}>Năm {y}</option>
          ))}
        </select>
        {loading && <span className="text-slate-400">Đang tải...</span>}
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      {view === 'attendance' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Tổng ngày công</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.totalWorkDays ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
              <CalendarDays className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.totalWorkDays} prev={prevData?.totalWorkDays} />
        </div>
      )}
      {view === 'attendance' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Đúng giờ</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.onTimeCount ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
              <CheckCircle2 className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.onTimeCount} prev={prevData?.onTimeCount} />
        </div>
      )}
      {view === 'attendance' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Đi muộn</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.lateCount ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-amber-50 flex items-center justify-center text-amber-600">
              <Clock className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.lateCount} prev={prevData?.lateCount} />
        </div>
      )}
      {view === 'attendance' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Về sớm</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.earlyCount ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-orange-50 flex items-center justify-center text-orange-600">
              <Clock className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.earlyCount} prev={prevData?.earlyCount} />
        </div>
      )}

      {view === 'leave' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Thực tế nghỉ</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.actualLeaveCount}</span>
            <div className="h-10 w-10 rounded-full bg-sky-50 flex items-center justify-center text-sky-600">
              <Calendar className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.actualLeaveCount} prev={prevData?.actualLeaveCount} />
        </div>
      )}

      {view === 'leave' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Kế hoạch nghỉ</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">Đơn pending giao kỳ</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.plannedLeaveCount}</span>
            <div className="h-10 w-10 rounded-full bg-teal-50 flex items-center justify-center text-teal-600">
              <CalendarDays className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.plannedLeaveCount} prev={prevData?.plannedLeaveCount} />
        </div>
      )}
      {view === 'leave' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Đơn nghỉ đã duyệt</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.leaveApproved ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
              <CheckCircle2 className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.leaveApproved} prev={prevData?.leaveApproved} />
        </div>
      )}
      {view === 'leave' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Đơn nghỉ từ chối</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.leaveRejected ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-rose-50 flex items-center justify-center text-rose-600">
              <XCircle className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.leaveRejected} prev={prevData?.leaveRejected} />
        </div>
      )}

      {view === 'ot' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Giờ OT đã duyệt</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.otTotalHours ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-amber-50 flex items-center justify-center text-amber-600">
              <Clock className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.otTotalHours} prev={prevData?.otTotalHours} />
        </div>
      )}
      {view === 'ot' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Đơn OT đã gửi</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.otSubmitted ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
              <FileCheck className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.otSubmitted} prev={prevData?.otSubmitted} />
        </div>
      )}
      {view === 'ot' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Đơn OT đã duyệt</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.otApproved ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600">
              <CheckCircle2 className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.otApproved} prev={prevData?.otApproved} />
        </div>
      )}
      {view === 'ot' && (
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-700">Đơn OT từ chối</span>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-50 px-2.5 py-1 rounded-lg border border-slate-200">{periodLabel}</span>
          </div>
          <div className="mt-4 mb-2 flex items-baseline justify-between">
            <span className="text-3xl font-extrabold text-slate-900 tracking-tight">{data.otRejected ?? 0}</span>
            <div className="h-10 w-10 rounded-full bg-rose-50 flex items-center justify-center text-rose-600">
              <XCircle className="h-5 w-5" />
            </div>
          </div>
          <MomLine cur={data.otRejected} prev={prevData?.otRejected} />
        </div>
      )}
      </div>

      {view === 'attendance' && (
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Đi muộn theo phòng ban</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Đơn vị: lượt LATE / EARLY / LATE_AND_EARLY</p>
          {lateByDept.length === 0 ? (
            <p className="mt-6 text-xs text-slate-400">Kỳ này không có lượt đi muộn, về sớm nào.</p>
          ) : (
            <div className="mt-6 w-full overflow-x-auto">
              <div className="min-w-[480px]">
                <svg viewBox="0 0 540 240" className="w-full h-56 select-none">
                  {[0, 0.25, 0.5, 0.75, 1].map(f => {
                    const val = Math.round(lateMax * f);
                    const y = 190 - f * 160;
                    return (
                      <g key={f}>
                        <text x="24" y={y + 3} textAnchor="end" className="text-[9px] fill-slate-400 font-mono">{val}</text>
                        <line x1="32" y1={y} x2="530" y2={y} stroke="#f1f5f9" strokeDasharray="3 3" strokeWidth="1" />
                      </g>
                    );
                  })}
                  {lateByDept.map((d, idx) => {
                    const barWidth = 22;
                    const gap = 500 / Math.max(lateByDept.length, 1);
                    const x = 45 + idx * gap;
                    const barHeight = (d.days / lateMax) * 160;
                    const y = 190 - barHeight;
                    return (
                      <g key={d.department}>
                        <title>{`${d.department}: ${d.days} lượt đi muộn, về sớm`}</title>
                        <text x={x + barWidth / 2} y={y - 4} textAnchor="middle" className="text-[9px] font-bold fill-slate-600 font-mono">{d.days}</text>
                        <rect x={x} y={y} width={barWidth} height={barHeight} rx="3" fill="#f43f5e" />
                        <text x={x + barWidth / 2} y="205" textAnchor="end" transform={`rotate(-35, ${x + barWidth / 2}, 205)`} className="text-[8px] font-semibold fill-slate-500">
                          {d.department.slice(0, 22)}
                        </text>
                      </g>
                    );
                  })}
                </svg>
              </div>
            </div>
          )}
          <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            Tổng: <span className="font-semibold text-rose-600">{data.lateEarlyCount} lượt</span>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Đi muộn theo thời gian</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">Bucket 7 ngày trong kỳ — Đơn vị: lượt</p>
          <div className="mt-6 w-full overflow-x-auto">
            <div className="min-w-[420px]">
              <svg viewBox="0 0 540 240" className="w-full h-56 select-none">
                {[0, 0.25, 0.5, 0.75, 1].map(f => {
                  const val = Math.round(lateWeekMax * f);
                  const y = 190 - f * 160;
                  return (
                    <g key={f}>
                      <text x="24" y={y + 3} textAnchor="end" className="text-[9px] fill-slate-400 font-mono">{val}</text>
                      <line x1="32" y1={y} x2="530" y2={y} stroke="#f1f5f9" strokeDasharray="3 3" strokeWidth="1" />
                    </g>
                  );
                })}
                {lateTrend.map((w, idx, arr) => {
                  const gap = 480 / Math.max(arr.length, 1);
                  const bw = Math.min(40, gap * 0.5);
                  const x = 45 + idx * gap + (gap - bw) / 2;
                  const h = (w.days / lateWeekMax) * 160;
                  const y = 190 - h;
                  return (
                    <g key={w.label}>
                      <title>{`${w.label}: ${weekRangeOf(w.label)}\n${w.days} lượt đi muộn, về sớm`}</title>
                      {h > 0 && <rect x={x} y={y} width={bw} height={h} rx="4" fill="#f43f5e" />}
                      <text x={x + bw / 2} y={y - 5} textAnchor="middle" className="text-[10px] font-bold fill-slate-700 font-mono">{w.days}</text>
                      <text x={x + bw / 2} y="208" textAnchor="middle" className="text-[10px] font-semibold fill-slate-500">{w.label}</text>
                    </g>
                  );
                })}
              </svg>
            </div>
          </div>
          <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            {lateTrend.length === 0 ? 'Chưa có dữ liệu.' : `Cao nhất: ${Math.max(...lateTrend.map(w => w.days))} lượt/tuần`}
          </div>
        </div>
      </div>
      )}

      {view === 'attendance' && (
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Cơ cấu trạng thái chấm công</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Đơn vị: bản ghi</p>
          {statusTotal === 0 ? (
            <p className="mt-6 text-xs text-slate-400">Kỳ này chưa có bản ghi chấm công nào.</p>
          ) : (
            <div className="mt-4 flex flex-col sm:flex-row items-center justify-around gap-4 py-2">
              <div className="relative flex items-center justify-center">
                <svg width="180" height="180" viewBox="0 0 180 180" className="transform -rotate-90 select-none">
                  <circle cx="90" cy="90" r="65" stroke="#f1f5f9" strokeWidth="24" fill="transparent" />
                  {(() => {
                    const c = 2 * Math.PI * 65;
                    let acc = 0;
                    return statusSlices.map(s => {
                      if (s.count <= 0) return null;
                      const len = (s.count / statusTotal) * c;
                      const el = (
                        <circle key={s.label} cx="90" cy="90" r="65" stroke={s.color} strokeWidth="24" fill="transparent"
                          strokeDasharray={`${len} ${c - len}`} strokeDashoffset={-acc}>
                          <title>{`${s.label}: ${s.count} (${Math.round((s.count / statusTotal) * 1000) / 10}%)`}</title>
                        </circle>
                      );
                      acc += len;
                      return el;
                    });
                  })()}
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <span className="text-2xl font-black text-slate-900 tracking-tight">{statusTotal}</span>
                  <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Bản ghi</span>
                </div>
              </div>
              <div className="space-y-2.5 w-full sm:w-auto">
                {statusSlices.map(s => (
                  <div key={s.label} className="flex items-center justify-between gap-4 text-xs">
                    <div className="flex items-center gap-2">
                      <span className="h-3 w-3 rounded-full" style={{ backgroundColor: s.color }} />
                      <span className="font-medium text-slate-700">{s.label}</span>
                    </div>
                    <div className="flex items-center gap-2 font-mono">
                      <span className="font-bold text-slate-900">{s.count}</span>
                      <span className="text-[11px] text-slate-400">({statusTotal > 0 ? Math.round((s.count / statusTotal) * 1000) / 10 : 0}%)</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <div className="flex items-start justify-between">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Nhân viên quên chấm công</h3>
              <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Top 7</p>
            </div>
            <BarChart3 className="h-4 w-4 text-slate-300" />
          </div>
          <div className="mt-4 space-y-2.5 divide-y divide-slate-100">
            {missingTop.length === 0 && (
              <p className="text-xs text-slate-400">Kỳ này không ai quên chấm công.</p>
            )}
            {missingTop.map(emp => (
              <div key={emp.userId || emp.fullName} title={`${emp.fullName} — ${emp.department}: quên ${emp.days} lượt`} className="pt-2.5 first:pt-0 flex items-center justify-between gap-3">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 bg-cyan-100 text-cyan-700">
                    {initialsOf(emp.fullName)}
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-900 truncate">{emp.fullName}</p>
                    <p className="text-[11px] text-slate-400 truncate">{emp.department}</p>
                  </div>
                </div>
                <span className="text-xs font-bold text-cyan-600 bg-cyan-50 px-2.5 py-1 rounded-lg border border-cyan-200/60 font-mono shrink-0">
                  {emp.days} lượt
                </span>
              </div>
            ))}
          </div>
          <div className="pt-3 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            Đầu tháng rà soát và giải quyết quên chấm công trước khi chốt sổ bảng công
          </div>
        </div>
      </div>
      )}

      {view === 'leave' && (
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Tình hình nghỉ theo phòng ban</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Đơn vị: ngày nghỉ</p>
          {data.leaveByDept.length === 0 ? (
            <p className="mt-6 text-xs text-slate-400">Kỳ này chưa có ngày nghỉ nào.</p>
          ) : (
            <div className="mt-6 w-full overflow-x-auto">
              <div className="min-w-[480px]">
                <svg viewBox="0 0 540 240" className="w-full h-56 select-none">
                  {[0, 0.25, 0.5, 0.75, 1].map(f => {
                    const val = Math.round(maxDeptDays * f);
                    const y = 190 - f * 160;
                    return (
                      <g key={f}>
                        <text x="24" y={y + 3} textAnchor="end" className="text-[9px] fill-slate-400 font-mono">{val}</text>
                        <line x1="32" y1={y} x2="530" y2={y} stroke="#f1f5f9" strokeDasharray="3 3" strokeWidth="1" />
                      </g>
                    );
                  })}
                  {data.leaveByDept.map((d, idx) => {
                    const barWidth = 22;
                    const gap = 500 / Math.max(data.leaveByDept.length, 1);
                    const x = 45 + idx * gap;
                    const barHeight = (d.days / maxDeptDays) * 160;
                    const y = 190 - barHeight;
                    return (
                      <g key={d.department}>
                        <title>{`${d.department}: ${d.days} ngày nghỉ`}</title>
                        <text x={x + barWidth / 2} y={y - 4} textAnchor="middle" className="text-[9px] font-bold fill-slate-600 font-mono">{d.days}</text>
                        <rect x={x} y={y} width={barWidth} height={barHeight} rx="3" fill="#f97316" />
                        <text x={x + barWidth / 2} y="205" textAnchor="end" transform={`rotate(-35, ${x + barWidth / 2}, 205)`} className="text-[8px] font-semibold fill-slate-500">
                          {d.department.slice(0, 22)}
                        </text>
                      </g>
                    );
                  })}
                </svg>
              </div>
            </div>
          )}
          <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            Tổng: <span className="font-semibold text-orange-600">{data.totalLeaveDays} ngày nghỉ</span>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Tình hình nghỉ theo thời gian</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">Bucket 7 ngày trong kỳ — Đơn vị: ngày nghỉ</p>
          <div className="mt-6 w-full overflow-x-auto">
            <div className="min-w-[420px]">
              <svg viewBox="0 0 540 240" className="w-full h-56 select-none">
                {[0, 0.25, 0.5, 0.75, 1].map(f => {
                  const val = Math.round(weekMax * f);
                  const y = 190 - f * 160;
                  return (
                    <g key={f}>
                      <text x="24" y={y + 3} textAnchor="end" className="text-[9px] fill-slate-400 font-mono">{val}</text>
                      <line x1="32" y1={y} x2="530" y2={y} stroke="#f1f5f9" strokeDasharray="3 3" strokeWidth="1" />
                    </g>
                  );
                })}
                {(data.weeklyTrend || []).map((w, idx, arr) => {
                  const gap = 480 / Math.max(arr.length, 1);
                  const bw = Math.min(40, gap * 0.5);
                  const x = 45 + idx * gap + (gap - bw) / 2;
                  const h = (w.days / weekMax) * 160;
                  const y = 190 - h;
                  return (
                    <g key={w.label}>
                      <title>{`${w.label}: ${weekRangeOf(w.label)}\n${w.days} ngày nghỉ`}</title>
                      {h > 0 && <rect x={x} y={y} width={bw} height={h} rx="4" fill="#f97316" />}
                      <text x={x + bw / 2} y={y - 5} textAnchor="middle" className="text-[10px] font-bold fill-slate-700 font-mono">{w.days}</text>
                      <text x={x + bw / 2} y="208" textAnchor="middle" className="text-[10px] font-semibold fill-slate-500">{w.label}</text>
                    </g>
                  );
                })}
              </svg>
            </div>
          </div>
          <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            {(data.weeklyTrend || []).length === 0 ? 'Chưa có dữ liệu.' : `Cao nhất: ${Math.max(...(data.weeklyTrend || []).map(w => w.days))} ngày nghỉ/tuần`}
          </div>
        </div>

        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Phân tích loại nghỉ</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">Từ trạng thái chấm công thật</p>
          <div className="mt-4 flex flex-col sm:flex-row items-center justify-around gap-4 py-2">
            <div className="relative flex items-center justify-center">
              <svg width="180" height="180" viewBox="0 0 180 180" className="transform -rotate-90 select-none">
                <circle cx="90" cy="90" r="65" stroke="#f1f5f9" strokeWidth="24" fill="transparent" />
                {donutSlices.map(s => (
                  <circle key={s.label} cx="90" cy="90" r="65" stroke={s.color} strokeWidth="24" fill="transparent"
                    strokeDasharray={`${s.len} ${circumference - s.len}`} strokeDashoffset={s.offset}>
                    <title>{`${s.label}: ${s.count} (${s.percent}%)`}</title>
                  </circle>
                ))}
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-2xl font-black text-slate-900 tracking-tight">{typeTotal}</span>
                <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Ngày nghỉ</span>
              </div>
            </div>
            <div className="space-y-2.5 w-full sm:w-auto">
              {donutSlices.map(s => (
                <div key={s.label} className="flex items-center justify-between gap-4 text-xs">
                  <div className="flex items-center gap-2">
                    <span className="h-3 w-3 rounded-full" style={{ backgroundColor: s.color }} />
                    <span className="font-medium text-slate-700">{s.label}</span>
                  </div>
                  <div className="flex items-center gap-2 font-mono">
                    <span className="font-bold text-slate-900">{s.count}</span>
                    <span className="text-[11px] text-slate-400">({s.percent}%)</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="pt-2 border-t border-slate-100 mt-2">
            {onNavigateToTab && (
              <button onClick={() => onNavigateToTab('requests')} className="text-xs font-bold text-orange-600 hover:text-orange-700 cursor-pointer">
                Xem chi tiết đơn →
              </button>
            )}
          </div>
        </div>

        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <div className="flex items-start justify-between">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Nhân viên nghỉ nhiều nhất</h3>
              <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Top 7</p>
            </div>
            <BarChart3 className="h-4 w-4 text-slate-300" />
          </div>
          <div className="mt-4 space-y-2.5 divide-y divide-slate-100">
            {data.topAbsentees.length === 0 && (
              <p className="text-xs text-slate-400">Kỳ này chưa có ngày nghỉ nào.</p>
            )}
            {data.topAbsentees.map(emp => (
              <div key={emp.userId || emp.fullName} title={`${emp.fullName} — ${emp.department}: ${emp.days} ngày nghỉ`} className="pt-2.5 first:pt-0 flex items-center justify-between gap-3">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 bg-orange-100 text-orange-700">
                    {initialsOf(emp.fullName)}
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-900 truncate">{emp.fullName}</p>
                    <p className="text-[11px] text-slate-400 truncate">{emp.department}</p>
                  </div>
                </div>
                <span className="text-xs font-bold text-orange-600 bg-orange-50 px-2.5 py-1 rounded-lg border border-orange-200/60 font-mono shrink-0">
                  {emp.days} ngày
                </span>
              </div>
            ))}
          </div>
          <div className="pt-3 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            Dữ liệu tổng hợp từ đơn nghỉ đã duyệt kỳ hiện tại
          </div>
        </div>
      </div>
      )}

      {view === 'ot' && (
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Tăng ca theo phòng ban</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Đơn vị: giờ OT đã duyệt</p>
          {otByDept.length === 0 ? (
            <p className="mt-6 text-xs text-slate-400">Kỳ này chưa có giờ OT nào được duyệt.</p>
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
                  {otByDept.map((d, idx) => {
                    const gap = 480 / Math.max(otByDept.length, 1);
                    const bw = Math.min(40, gap * 0.5);
                    const x = 50 + idx * gap + (gap - bw) / 2;
                    const h = (d.hours / otMax) * 160;
                    const y = 190 - h;
                    return (
                      <g key={d.department}>
                        <title>{`${d.department}: ${d.hours} giờ OT`}</title>
                        {h > 0 && <rect x={x} y={y} width={bw} height={h} rx="4" fill="#f59e0b" />}
                        <text x={x + bw / 2} y={y - 5} textAnchor="middle" className="text-[10px] font-bold fill-slate-700 font-mono">{d.hours}</text>
                        <text x={x + bw / 2} y="205" textAnchor="end" transform={`rotate(-35, ${x + bw / 2}, 205)`} className="text-[8px] font-semibold fill-slate-500">
                          {d.department.slice(0, 22)}
                        </text>
                      </g>
                    );
                  })}
                </svg>
              </div>
            </div>
          )}
          <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            Tổng: <span className="font-semibold text-amber-600">{data.otTotalHours ?? 0} giờ OT</span>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <div className="flex items-start justify-between">
            <div>
              <h3 className="text-sm font-bold text-slate-900">Nhân viên tăng ca nhiều nhất</h3>
              <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Top 7</p>
            </div>
            <BarChart3 className="h-4 w-4 text-slate-300" />
          </div>
          <div className="mt-4 space-y-2.5 divide-y divide-slate-100">
            {topOt.length === 0 && (
              <p className="text-xs text-slate-400">Kỳ này chưa có giờ OT nào được duyệt.</p>
            )}
            {topOt.map(emp => (
              <div key={emp.userId || emp.fullName} title={`${emp.fullName} — ${emp.department}: ${emp.hours} giờ OT`} className="pt-2.5 first:pt-0 flex items-center justify-between gap-3">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 bg-amber-100 text-amber-700">
                    {initialsOf(emp.fullName)}
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-900 truncate">{emp.fullName}</p>
                    <p className="text-[11px] text-slate-400 truncate">{emp.department}</p>
                  </div>
                </div>
                <span className="text-xs font-bold text-amber-600 bg-amber-50 px-2.5 py-1 rounded-lg border border-amber-200/60 font-mono shrink-0">
                  {emp.hours} giờ
                </span>
              </div>
            ))}
          </div>
          <div className="pt-3 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            Giờ thực tế từ đơn OT đã duyệt kỳ hiện tại
          </div>
        </div>
      </div>
      )}

      {view === 'ot' && (
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Tỷ lệ duyệt / từ chối OT</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">{periodLabel} — Đơn vị: đơn giao kỳ</p>
          {otApprovalTotal === 0 ? (
            <p className="mt-6 text-xs text-slate-400">Kỳ này chưa có đơn OT nào được duyệt hoặc từ chối.</p>
          ) : (
            <div className="mt-4 flex flex-col sm:flex-row items-center justify-around gap-4 py-2">
              <div className="relative flex items-center justify-center">
                <svg width="180" height="180" viewBox="0 0 180 180" className="transform -rotate-90 select-none">
                  <circle cx="90" cy="90" r="65" stroke="#f1f5f9" strokeWidth="24" fill="transparent" />
                  {otApprovalSlices.map(s => (
                    s.len > 0 ? (
                      <circle key={s.label} cx="90" cy="90" r="65" stroke={s.color} strokeWidth="24" fill="transparent"
                        strokeDasharray={`${s.len} ${2 * Math.PI * 65 - s.len}`} strokeDashoffset={s.offset}>
                        <title>{`${s.label}: ${s.count} đơn (${s.percent}%)`}</title>
                      </circle>
                    ) : null
                  ))}
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                  <span className="text-2xl font-black text-slate-900 tracking-tight">{otApprovalTotal}</span>
                  <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Đơn OT</span>
                </div>
              </div>
              <div className="space-y-2.5 w-full sm:w-auto">
                {otApprovalSlices.map(s => (
                  <div key={s.label} className="flex items-center justify-between gap-4 text-xs">
                    <div className="flex items-center gap-2">
                      <span className="h-3 w-3 rounded-full" style={{ backgroundColor: s.color }} />
                      <span className="font-medium text-slate-700">{s.label}</span>
                    </div>
                    <div className="flex items-center gap-2 font-mono">
                      <span className="font-bold text-slate-900">{s.count}</span>
                      <span className="text-[11px] text-slate-400">({s.percent}%)</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs">
          <h3 className="text-sm font-bold text-slate-900">Tăng ca theo thời gian</h3>
          <p className="text-[11px] text-slate-400 mt-0.5">Bucket 7 ngày trong kỳ — Đơn vị: giờ OT đã duyệt</p>
          <div className="mt-6 w-full overflow-x-auto">
            <div className="min-w-[420px]">
              <svg viewBox="0 0 540 240" className="w-full h-56 select-none">
                {[0, 0.25, 0.5, 0.75, 1].map(f => {
                  const val = Math.round(otWeekMax * f * 10) / 10;
                  const y = 190 - f * 160;
                  return (
                    <g key={f}>
                      <text x="30" y={y + 3} textAnchor="end" className="text-[9px] fill-slate-400 font-mono">{val}</text>
                      <line x1="38" y1={y} x2="530" y2={y} stroke="#f1f5f9" strokeDasharray="3 3" strokeWidth="1" />
                    </g>
                  );
                })}
                {otTrend.map((w, idx, arr) => {
                  const gap = 480 / Math.max(arr.length, 1);
                  const bw = Math.min(40, gap * 0.5);
                  const x = 45 + idx * gap + (gap - bw) / 2;
                  const h = (w.days / otWeekMax) * 160;
                  const y = 190 - h;
                  return (
                    <g key={w.label}>
                      <title>{`${w.label}: ${weekRangeOf(w.label)}\n${w.days} giờ OT`}</title>
                      {h > 0 && <rect x={x} y={y} width={bw} height={h} rx="4" fill="#f59e0b" />}
                      <text x={x + bw / 2} y={y - 5} textAnchor="middle" className="text-[10px] font-bold fill-slate-700 font-mono">{w.days}</text>
                      <text x={x + bw / 2} y="208" textAnchor="middle" className="text-[10px] font-semibold fill-slate-500">{w.label}</text>
                    </g>
                  );
                })}
              </svg>
            </div>
          </div>
          <div className="pt-2 border-t border-slate-100 text-[11px] text-slate-400 mt-2">
            {otTrend.length === 0 ? 'Chưa có dữ liệu.' : `Cao nhất: ${Math.max(...otTrend.map(w => w.days))} giờ OT/tuần`}
          </div>
        </div>
      </div>
      )}
    </div>
  );
}
