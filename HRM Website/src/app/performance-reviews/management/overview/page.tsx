'use client';

import React, { useEffect, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { performanceService, REVIEW_STATUS_LABEL } from '@/services/performanceService';
import { PerformanceOverview } from '@/types';
import { BarChart3, Trophy, TriangleAlert, FileText, Gauge } from 'lucide-react';
import ScopePill from '../../ScopePill';
import MomLine from '@/components/MomLine';

const now = new Date();
const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);
const STATUS_COLORS: Record<string, string> = {
  DRAFT: '#94a3b8', SELF_SUBMITTED: '#f59e0b', MANAGER_SCORED: '#3b82f6', LOCKED: '#10b981'
};

export default function PerformanceOverviewPage() {
  const { can, currentUser, isManager } = useAuth();
  const canCompany = can('EVALUATION_VIEW_ALL') || can('EVALUATION_APPROVE');
  const canDept = can('EVALUATION_VIEW_DEPT') || can('EVALUATION_APPROVE_DEPT') || isManager;
  const allowed = canCompany || canDept;
  const [scope, setScope] = useState<'dept' | 'company'>(canCompany ? 'company' : 'dept');
  const [year, setYear] = useState(prev.getFullYear());
  const [month, setMonth] = useState(prev.getMonth() + 1);
  const [data, setData] = useState<PerformanceOverview | null>(null);
  const [prevData, setPrevData] = useState<PerformanceOverview | null>(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    if (!allowed) { setLoading(false); return; }
    setLoading(true);
    try {
      setData(await performanceService.getOverview(year, month, scope));
    } catch { setData(null); }
    finally { setLoading(false); }
    // ponytail: MoM goi thang truoc song song — loi thi bo qua
    const pp = month === 1 ? { m: 12, y: year - 1 } : { m: month - 1, y: year };
    performanceService.getOverview(pp.y, pp.m, scope).then(setPrevData).catch(() => setPrevData(null));
  };

  useEffect(() => { load(); }, [scope]);

  if (!allowed) {
    return (
      <AppShell>
        <div className="p-4 md:p-6 max-w-6xl mx-auto">
          <div className="bg-white border border-slate-200 rounded-2xl p-6 text-center text-sm text-slate-500 shadow-xs">
            Bạn không có quyền xem trang quản lý đánh giá.
          </div>
        </div>
      </AppShell>
    );
  }

  const maxAvg = Math.max(5, ...(data?.avgByDept.map(d => d.avg) ?? [0]));
  const total = data?.total ?? 0;

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-6xl mx-auto">
        <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
          <BarChart3 className="h-5 w-5 text-amber-500" /> Tổng quan đánh giá
        </h1>

        <ScopePill scope={scope} onChange={setScope} deptName={currentUser?.department} canCompany={canCompany} canDept={canDept} />

        <div className="flex flex-wrap items-center gap-3 mb-4">
          <span className="text-sm font-semibold text-slate-700">Kỳ báo cáo:</span>
          <select value={month} onChange={e => setMonth(Number(e.target.value))}
            className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            aria-label="Tháng báo cáo">
            {Array.from({ length: 12 }, (_, i) => i + 1).map(m => <option key={m} value={m}>Tháng {m}</option>)}
          </select>
          <select value={year} onChange={e => setYear(Number(e.target.value))}
            className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
            aria-label="Năm báo cáo">
            {[now.getFullYear() - 2, now.getFullYear() - 1, now.getFullYear()].map(y => <option key={y} value={y}>Năm {y}</option>)}
          </select>
          <button onClick={load}
            className="px-4 py-2 rounded-xl bg-slate-800 text-white text-sm font-semibold hover:bg-slate-900 transition cursor-pointer">
            Xem
          </button>
        </div>

        {loading ? <p className="text-sm text-slate-400">Đang tải…</p>
          : !data ? <p className="text-sm text-slate-400">Không tải được dữ liệu.</p>
          : (
            <div className="space-y-4">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                {[
                  { label: 'Tổng bài', value: String(data.total), badge: `T${month}/${year}`, icon: FileText, tint: 'bg-blue-50 text-blue-600', cur: data.total, prev: prevData?.total },
                  { label: 'Điểm TB', value: data.avgScore != null ? String(data.avgScore) : '—', badge: `T${month}/${year}`, icon: Gauge, tint: 'bg-emerald-50 text-emerald-600', cur: data.avgScore, prev: prevData?.avgScore },
                  { label: 'Xuất sắc', value: String(data.excellent.length), badge: '≥ 4.5', icon: Trophy, tint: 'bg-amber-50 text-amber-600', cur: data.excellent.length, prev: prevData?.excellent.length },
                  { label: 'Chưa đạt', value: String(data.belowTarget.length), badge: '< 3.0', icon: TriangleAlert, tint: 'bg-rose-50 text-rose-600', cur: data.belowTarget.length, prev: prevData?.belowTarget.length },
                ].map(c => (
                  <div key={c.label} className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-semibold text-slate-700">{c.label}</span>
                      <span className="text-[11px] font-medium text-slate-500 bg-slate-50 border border-slate-200 px-2 py-0.5 rounded-lg">{c.badge}</span>
                    </div>
                    <div className="flex items-center justify-between mt-2">
                      <span className="text-3xl font-black text-slate-900">{c.value}</span>
                      <span className={`h-10 w-10 rounded-full flex items-center justify-center ${c.tint}`}>
                        <c.icon className="h-5 w-5" />
                      </span>
                    </div>
                    <div className="mt-1"><MomLine cur={c.cur} prev={c.prev} /></div>
                  </div>
                ))}
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-xs">
                  <h3 className="text-sm font-bold text-slate-800 mb-3">Điểm trung bình theo phòng</h3>
                  {data.avgByDept.length === 0 ? <p className="text-xs text-slate-400">Chưa có điểm.</p> : (
                    <div className="space-y-2.5">
                      {data.avgByDept.map(d => (
                        <div key={d.department}>
                          <div className="flex justify-between text-xs mb-1">
                            <span className="font-semibold text-slate-600 truncate">{d.department}</span>
                            <span className="font-black text-slate-800">{d.avg} <span className="font-normal text-slate-400">({d.count})</span></span>
                          </div>
                          <div className="h-2.5 rounded-full bg-slate-100 overflow-hidden">
                            <div className="h-full rounded-full bg-gradient-to-r from-amber-400 to-amber-500 transition-all"
                              style={{ width: `${Math.min(100, (d.avg / maxAvg) * 100)}%` }} />
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-xs">
                  <h3 className="text-sm font-bold text-slate-800 mb-3">Phân bố trạng thái</h3>
                  {Object.keys(data.byStatus).length === 0 ? <p className="text-xs text-slate-400">Chưa có dữ liệu.</p> : (
                    <div className="space-y-2.5">
                      {Object.entries(data.byStatus).map(([k, v]) => (
                        <div key={k}>
                          <div className="flex justify-between text-xs mb-1">
                            <span className="flex items-center gap-2 font-semibold text-slate-600">
                              <span className="w-2.5 h-2.5 rounded-sm" style={{ background: STATUS_COLORS[k] ?? '#cbd5e1' }} />
                              {REVIEW_STATUS_LABEL[k] ?? k}
                            </span>
                            <span className="font-black text-slate-800">{v} <span className="font-normal text-slate-400">({total > 0 ? Math.round((v / total) * 100) : 0}%)</span></span>
                          </div>
                          <div className="h-2.5 rounded-full bg-slate-100 overflow-hidden">
                            <div className="h-full rounded-full transition-all" style={{ width: `${total > 0 ? (v / total) * 100 : 0}%`, background: STATUS_COLORS[k] ?? '#cbd5e1' }} />
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div className="bg-white border border-emerald-200 rounded-2xl p-5 shadow-xs">
                  <h3 className="text-sm font-bold text-emerald-700 mb-3 flex items-center gap-2">
                    <Trophy className="h-4 w-4" /> Tuyên dương xuất sắc
                  </h3>
                  {data.excellent.length === 0 ? <p className="text-xs text-slate-400">Chưa có.</p> : (
                    <div className="space-y-2">
                      {data.excellent.map(r => (
                        <div key={r.reviewId} className="flex justify-between text-sm rounded-xl bg-emerald-50 px-3 py-2">
                          <span className="font-semibold text-slate-700">{r.revieweeName} <span className="font-normal text-slate-400">· {r.department}</span></span>
                          <span className="font-black text-emerald-700">{r.avgManager}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
                <div className="bg-white border border-rose-200 rounded-2xl p-5 shadow-xs">
                  <h3 className="text-sm font-bold text-rose-700 mb-3 flex items-center gap-2">
                    <TriangleAlert className="h-4 w-4" /> Chưa đạt chỉ tiêu
                  </h3>
                  {data.belowTarget.length === 0 ? <p className="text-xs text-slate-400">Chưa có.</p> : (
                    <div className="space-y-2">
                      {data.belowTarget.map(r => (
                        <div key={r.reviewId} className="flex justify-between text-sm rounded-xl bg-rose-50 px-3 py-2">
                          <span className="font-semibold text-slate-700">{r.revieweeName} <span className="font-normal text-slate-400">· {r.department}</span></span>
                          <span className="font-black text-rose-700">{r.avgManager}</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
      </div>
    </AppShell>
  );
}
