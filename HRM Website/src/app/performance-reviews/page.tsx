'use client';

import React, { useEffect, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { performanceService } from '@/services/performanceService';
import { PerformanceReview } from '@/types';
import { Award } from 'lucide-react';
import ReviewDetail from './ReviewDetail';

const now = new Date();
const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);

export default function PerformanceSelfPage() {
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToast({ text, type });
    setTimeout(() => setToast(null), 4000);
  };

  const [selfPeriod, setSelfPeriod] = useState<'MONTHLY' | 'YEARLY'>('MONTHLY');
  const [selfYear, setSelfYear] = useState(prev.getFullYear());
  const [selfMonth, setSelfMonth] = useState(prev.getMonth() + 1);
  const [current, setCurrent] = useState<PerformanceReview | null>(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const r = await performanceService.getCurrent(selfPeriod, selfYear, selfPeriod === 'YEARLY' ? undefined : selfMonth);
      setCurrent(r);
    } catch (e: any) { showToast(e.message || 'Không tải được bài đánh giá.', 'error'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, [selfPeriod, selfYear, selfMonth]);

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-5xl mx-auto">
        <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
          <Award className="h-5 w-5 text-amber-500" /> Tự đánh giá
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
              <select value={selfPeriod} onChange={e => setSelfPeriod(e.target.value as any)}
                className="ml-2 rounded-lg border border-slate-200 px-2.5 py-1.5 text-sm">
                <option value="MONTHLY">Tháng</option>
                <option value="YEARLY">Năm</option>
              </select>
            </div>
            {selfPeriod === 'MONTHLY' && (
              <div>
                <label className="text-xs font-semibold text-slate-500">Tháng</label>
                <select value={selfMonth} onChange={e => setSelfMonth(Number(e.target.value))}
                  className="ml-2 rounded-lg border border-slate-200 px-2.5 py-1.5 text-sm">
                  {Array.from({ length: 12 }, (_, i) => i + 1).map(m => <option key={m} value={m}>Tháng {m}</option>)}
                </select>
              </div>
            )}
            <div>
              <label className="text-xs font-semibold text-slate-500">Năm</label>
              <select value={selfYear} onChange={e => setSelfYear(Number(e.target.value))}
                className="ml-2 rounded-lg border border-slate-200 px-2.5 py-1.5 text-sm">
                {[now.getFullYear() - 1, now.getFullYear(), now.getFullYear() + 1].map(y => <option key={y} value={y}>{y}</option>)}
              </select>
            </div>
          </div>
          {loading ? <p className="text-sm text-slate-400">Đang tải…</p>
            : current ? <ReviewDetail review={current} onChanged={load} showToast={showToast} />
            : <p className="text-sm text-slate-400">Không có bài đánh giá.</p>}
        </div>
      </div>
    </AppShell>
  );
}
