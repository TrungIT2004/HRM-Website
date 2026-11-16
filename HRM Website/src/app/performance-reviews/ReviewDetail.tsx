'use client';

import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { performanceService, REVIEW_STATUS_LABEL, ScorePayload } from '@/services/performanceService';
import { PerformanceReview } from '@/types';
import { Lock, Send, PenLine, CheckCircle2 } from 'lucide-react';

interface Props {
  review: PerformanceReview;
  onChanged: () => void;
  showToast: (text: string, type?: 'success' | 'error') => void;
}

const scoreColor = (s: number | null | undefined) =>
  s == null ? 'bg-slate-100 text-slate-400'
  : s >= 4.5 ? 'bg-emerald-100 text-emerald-700'
  : s >= 3 ? 'bg-blue-100 text-blue-700'
  : 'bg-rose-100 text-rose-700';

export default function ReviewDetail({ review, onChanged, showToast }: Props) {
  const { currentUser, can } = useAuth();
  const isOwner = currentUser?.userId === review.userId;
  const canScore = can('EVALUATION_APPROVE') || can('EVALUATION_APPROVE_DEPT');
  const canLock = can('EVALUATION_APPROVE');

  const [selfVals, setSelfVals] = useState<Record<string, number>>(() =>
    Object.fromEntries(review.scores.filter(s => s.selfScore != null).map(s => [s.criterionCode, s.selfScore as number])));
  const [mgrVals, setMgrVals] = useState<Record<string, number>>(() =>
    Object.fromEntries(review.scores.filter(s => s.managerScore != null).map(s => [s.criterionCode, s.managerScore as number])));
  const [summary, setSummary] = useState(review.overallSummary ?? '');
  const [goals, setGoals] = useState(review.nextGoals ?? '');
  const [busy, setBusy] = useState(false);

  const editableSelf = isOwner && review.status === 'DRAFT';
  const editableMgr = !isOwner && canScore && review.status === 'SELF_SUBMITTED';

  const collect = (vals: Record<string, number>): ScorePayload[] =>
    review.scores.map(s => ({ criterionCode: s.criterionCode, score: vals[s.criterionCode] ?? 0 }));

  const doSubmitSelf = async () => {
    if (review.scores.some(s => !selfVals[s.criterionCode])) {
      showToast('Vui lòng chấm đủ 10 tiêu chí (1-5).', 'error');
      return;
    }
    setBusy(true);
    try {
      await performanceService.submitSelf(review.reviewId, collect(selfVals));
      showToast('Nộp tự đánh giá thành công.');
      onChanged();
    } catch (e: any) { showToast(e.message || 'Nộp thất bại.', 'error'); }
    finally { setBusy(false); }
  };

  const doScore = async () => {
    if (review.scores.some(s => !mgrVals[s.criterionCode])) {
      showToast('Vui lòng chấm đủ 10 tiêu chí (1-5).', 'error');
      return;
    }
    setBusy(true);
    try {
      await performanceService.scoreManager(review.reviewId, collect(mgrVals), summary, goals);
      showToast('Chấm điểm thành công.');
      onChanged();
    } catch (e: any) { showToast(e.message || 'Chấm thất bại.', 'error'); }
    finally { setBusy(false); }
  };

  const doLock = async () => {
    setBusy(true);
    try {
      await performanceService.lock(review.reviewId);
      showToast('Đã khóa sổ.');
      onChanged();
    } catch (e: any) { showToast(e.message || 'Khóa thất bại.', 'error'); }
    finally { setBusy(false); }
  };

  const renderPills = (
    code: string, val: number | null | undefined,
    editable: boolean, onPick: (code: string, v: number) => void
  ) => (
    <div className="flex gap-1">
      {[1, 2, 3, 4, 5].map(v => (
        <button key={v} type="button" disabled={!editable || busy}
          onClick={() => onPick(code, v)}
          className={`w-7 h-7 rounded-lg text-xs font-bold transition cursor-pointer disabled:cursor-default ${val === v ? 'bg-amber-500 text-white shadow' : 'bg-slate-100 text-slate-500 hover:bg-slate-200'}`}>
          {v}
        </button>
      ))}
    </div>
  );

  const sigs: { label: string; value?: string | null; done: boolean }[] = [
    { label: 'Nhân viên', value: review.revieweeName, done: review.status !== 'DRAFT' },
    { label: 'Người đánh giá', value: review.evaluatorName, done: review.status === 'MANAGER_SCORED' || review.status === 'LOCKED' },
    { label: 'Quản lý trực tiếp', value: review.evaluatorName, done: review.status === 'MANAGER_SCORED' || review.status === 'LOCKED' },
    { label: 'Ban lãnh đạo', value: review.leaderConfirmed ? 'Đã xác nhận' : undefined, done: review.leaderConfirmed },
    { label: 'Phòng nhân sự', value: review.lockedBy ? 'Đã khóa sổ' : undefined, done: review.status === 'LOCKED' },
  ];

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2 text-sm">
        <span className="font-bold text-slate-800">{review.revieweeName}</span>
        <span className="text-slate-400">·</span>
        <span className="text-slate-500">{review.employeeCode} · {review.department}</span>
        <span className="text-slate-400">·</span>
        <span className="text-slate-500">
          {review.periodType === 'YEARLY' ? `Năm ${review.periodYear}` : `Tháng ${review.periodMonth}/${review.periodYear}`}
        </span>
        <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${review.status === 'LOCKED' ? 'bg-slate-200 text-slate-600' : 'bg-amber-100 text-amber-700'}`}>
          {REVIEW_STATUS_LABEL[review.status]}
        </span>
        {review.avgManager != null && (
          <span className={`px-2 py-0.5 rounded-full text-xs font-black ${scoreColor(review.avgManager)}`}>
            TB: {review.avgManager}
          </span>
        )}
      </div>

      <div className="overflow-x-auto rounded-2xl border border-slate-200">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-slate-50 text-xs text-slate-500">
              <th className="text-left p-3 font-semibold">Tiêu chí</th>
              <th className="p-3 font-semibold w-44">Tự đánh giá</th>
              <th className="p-3 font-semibold w-44">Quản lý chấm</th>
            </tr>
          </thead>
          <tbody>
            {review.scores.map(s => (
              <tr key={s.scoreId} className="border-t border-slate-100">
                <td className="p-3">
                  <div className="font-medium text-slate-700">{s.sortOrder}. {s.criterionText}</div>
                  {s.note && <div className="text-xs text-slate-400 mt-0.5">Ghi chú: {s.note}</div>}
                </td>
                <td className="p-3">
                  {editableSelf
                    ? renderPills(s.criterionCode, selfVals[s.criterionCode], true, (c, v) => setSelfVals(p => ({ ...p, [c]: v })))
                    : <span className={`inline-block px-2.5 py-1 rounded-lg text-xs font-black ${scoreColor(s.selfScore)}`}>{s.selfScore ?? '—'}</span>}
                </td>
                <td className="p-3">
                  {editableMgr
                    ? renderPills(s.criterionCode, mgrVals[s.criterionCode], true, (c, v) => setMgrVals(p => ({ ...p, [c]: v })))
                    : <span className={`inline-block px-2.5 py-1 rounded-lg text-xs font-black ${scoreColor(s.managerScore)}`}>{s.managerScore ?? '—'}</span>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {(editableMgr || review.overallSummary || review.nextGoals) && (
        <div className="grid gap-3 md:grid-cols-2">
          <div>
            <label className="text-xs font-semibold text-slate-500">Tổng kết chung</label>
            {editableMgr
              ? <textarea value={summary} onChange={e => setSummary(e.target.value)} rows={3}
                  className="mt-1 w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                  placeholder="Nhận xét tổng thể..." />
              : <p className="mt-1 text-sm text-slate-700 bg-slate-50 rounded-xl p-3">{review.overallSummary || '—'}</p>}
          </div>
          <div>
            <label className="text-xs font-semibold text-slate-500">Mục tiêu kỳ tiếp theo</label>
            {editableMgr
              ? <textarea value={goals} onChange={e => setGoals(e.target.value)} rows={3}
                  className="mt-1 w-full rounded-xl border border-slate-200 p-3 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400"
                  placeholder="Mục tiêu tháng/năm sau..." />
              : <p className="mt-1 text-sm text-slate-700 bg-slate-50 rounded-xl p-3">{review.nextGoals || '—'}</p>}
          </div>
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        {editableSelf && (
          <button onClick={doSubmitSelf} disabled={busy}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-amber-500 text-white text-sm font-semibold hover:bg-amber-600 transition cursor-pointer disabled:opacity-50">
            <Send className="h-4 w-4" /> Nộp tự đánh giá
          </button>
        )}
        {editableMgr && (
          <button onClick={doScore} disabled={busy}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-emerald-600 text-white text-sm font-semibold hover:bg-emerald-700 transition cursor-pointer disabled:opacity-50">
            <PenLine className="h-4 w-4" /> Chấm điểm
          </button>
        )}
        {canLock && review.status === 'MANAGER_SCORED' && (
          <button onClick={doLock} disabled={busy}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-800 text-white text-sm font-semibold hover:bg-slate-900 transition cursor-pointer disabled:opacity-50">
            <Lock className="h-4 w-4" /> Khóa sổ
          </button>
        )}
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-5 gap-2 pt-2 border-t border-slate-100">
        {sigs.map(s => (
          <div key={s.label} className="text-center py-2">
            <div className="text-[11px] font-bold text-slate-500">{s.label}</div>
            <div className="text-xs mt-1 flex items-center justify-center gap-1 text-slate-700">
              {s.done && <CheckCircle2 className="h-3.5 w-3.5 text-emerald-500" />}
              {s.value ?? <span className="text-slate-300">Chờ ký</span>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
