'use client';

import React, { useEffect, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { performanceService, REVIEW_STATUS_LABEL } from '@/services/performanceService';
import { PerformanceReview } from '@/types';
import { History, X } from 'lucide-react';
import ReviewDetail from '../ReviewDetail';

const now = new Date();
// ponytail: lich su mac dinh = thang truoc (thang 1 -> T12 nam truoc)
const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);

export default function PerformanceHistoryPage() {
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToast({ text, type });
    setTimeout(() => setToast(null), 4000);
  };

  const [hType, setHType] = useState('MONTHLY');
  const [hYear, setHYear] = useState(prev.getFullYear());
  const [hMonth, setHMonth] = useState(prev.getMonth() + 1);
  const [history, setHistory] = useState<PerformanceReview[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<PerformanceReview | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const res = await performanceService.getMyReviews({
        periodType: hType as any, year: hYear, month: hType === 'YEARLY' ? undefined : hMonth, size: 20
      });
      setHistory(res.content ?? []);
      setTotal(res.totalElements ?? 0);
    } catch { /* rớt mạng: hiện trống */ }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-5xl mx-auto">
        <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
          <History className="h-5 w-5 text-amber-500" /> Lịch sử đánh giá
        </h1>

        {toast && (
          <div className={`mb-3 px-4 py-2.5 rounded-xl text-sm font-medium ${toast.type === 'success' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-rose-50 text-rose-700 border border-rose-200'}`}>
            {toast.text}
          </div>
        )}

        <div className="bg-white border border-slate-200 rounded-2xl p-4 md:p-5 shadow-xs">
          <div className="flex flex-wrap items-end gap-3 mb-4">
            <div>
              <label className="text-xs font-semibold text-slate-500">Kỳ</label>
              <select value={hType} onChange={e => setHType(e.target.value)}
                className="ml-2 rounded-lg border border-slate-200 px-2.5 py-1.5 text-sm">
                <option value="MONTHLY">Tháng</option>
                <option value="YEARLY">Năm</option>
                <option value="ALL">Tất cả</option>
              </select>
            </div>
            {hType === 'MONTHLY' && (
              <div>
                <label className="text-xs font-semibold text-slate-500">Tháng</label>
                <select value={hMonth} onChange={e => setHMonth(Number(e.target.value))}
                  className="ml-2 rounded-lg border border-slate-200 px-2.5 py-1.5 text-sm">
                  {Array.from({ length: 12 }, (_, i) => i + 1).map(m => <option key={m} value={m}>Tháng {m}</option>)}
                </select>
              </div>
            )}
            <div>
              <label className="text-xs font-semibold text-slate-500">Năm</label>
              <select value={hYear} onChange={e => setHYear(Number(e.target.value))}
                className="ml-2 rounded-lg border border-slate-200 px-2.5 py-1.5 text-sm">
                {[now.getFullYear() - 2, now.getFullYear() - 1, now.getFullYear()].map(y => <option key={y} value={y}>{y}</option>)}
              </select>
            </div>
            <button onClick={load}
              className="px-4 py-1.5 rounded-xl bg-slate-800 text-white text-sm font-semibold hover:bg-slate-900 transition cursor-pointer">
              Tìm kiếm
            </button>
          </div>
          {loading ? <p className="text-sm text-slate-400">Đang tải…</p>
            : history.length === 0 ? <p className="text-sm text-slate-400">Chưa có bài đánh giá nào.</p>
            : (
              <div className="space-y-2">
                {history.map(r => (
                  <button key={r.reviewId} onClick={() => setSelected(r)}
                    className="w-full text-left flex items-center justify-between gap-3 rounded-xl border border-slate-200 px-4 py-3 hover:bg-slate-50 transition cursor-pointer">
                    <div>
                      <div className="text-sm font-semibold text-slate-800">
                        {r.periodType === 'YEARLY' ? `Năm ${r.periodYear}` : `Tháng ${r.periodMonth}/${r.periodYear}`}
                      </div>
                      <div className="text-xs text-slate-500">
                        Tự chấm: {r.avgSelf ?? '—'} · Quản lý: {r.avgManager ?? '—'}
                        {r.evaluatorName ? ` · ${r.evaluatorName}` : ''}
                      </div>
                    </div>
                    <span className="text-xs font-semibold px-2 py-1 rounded-full bg-slate-100 text-slate-600 shrink-0">
                      {REVIEW_STATUS_LABEL[r.status]}
                    </span>
                  </button>
                ))}
                <p className="text-xs text-slate-400">Tổng {total} bài.</p>
              </div>
            )}
        </div>

        {selected && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={() => setSelected(null)}>
            <div className="bg-white rounded-3xl max-w-3xl w-full max-h-[90vh] overflow-y-auto p-5" onClick={e => e.stopPropagation()}>
              <div className="flex justify-end mb-2">
                <button onClick={() => setSelected(null)} className="p-1.5 rounded-lg hover:bg-slate-100 cursor-pointer">
                  <X className="h-5 w-5 text-slate-500" />
                </button>
              </div>
              <ReviewDetail review={selected} showToast={showToast}
                onChanged={async () => { await load(); setSelected(null); }} />
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
