'use client';

import React, { useEffect, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { performanceService, REVIEW_STATUS_LABEL } from '@/services/performanceService';
import { PerformanceReview } from '@/types';
import { ClipboardList, Search, Filter, X, RotateCcw, Lock, Download } from 'lucide-react';
import ReviewDetail from '../../ReviewDetail';
import ScopePill from '../../ScopePill';
import ConfirmDialog from '@/components/ConfirmDialog';

const now = new Date();
const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);

export default function PerformanceRecordsPage() {
  const { can, currentUser, isManager } = useAuth();
  const canCompany = can('EVALUATION_VIEW_ALL') || can('EVALUATION_APPROVE');
  const canDept = can('EVALUATION_VIEW_DEPT') || can('EVALUATION_APPROVE_DEPT') || isManager;
  const allowed = canCompany || canDept;
  const [scope, setScope] = useState<'dept' | 'company'>(canCompany ? 'company' : 'dept');

  const [year, setYear] = useState(prev.getFullYear());
  const [month, setMonth] = useState(prev.getMonth() + 1);
  const [keyword, setKeyword] = useState('');
  const [department, setDepartment] = useState('');
  const [status, setStatus] = useState('');

  const [rows, setRows] = useState<PerformanceReview[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [selected, setSelected] = useState<PerformanceReview | null>(null);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(new Set());
  const [confirmLock, setConfirmLock] = useState(false);
  const [busy, setBusy] = useState(false);
  const canLock = can('EVALUATION_APPROVE');
  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToast({ text, type });
    setTimeout(() => setToast(null), 4000);
  };

  const search = async () => {
    if (!allowed) { setLoading(false); return; }
    setLoading(true);
    try {
      const params = { year, month, keyword: keyword || undefined, department: scope === 'company' ? (department || undefined) : undefined, status: status || undefined, size: 20 };
      const res = scope === 'company'
        ? await performanceService.getCompanyRecords(params)
        : await performanceService.getApprovals(params);
      setRows(res.content ?? []);
      setTotal(res.totalElements ?? 0);
      setCheckedIds(new Set());
    } catch (e: any) { showToast(e.message || 'Không tải được dữ liệu.', 'error'); }
    finally { setLoading(false); }
  };

  useEffect(() => { search(); }, [scope]);

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

  const resetFilters = () => {
    setYear(prev.getFullYear());
    setMonth(prev.getMonth() + 1);
    setKeyword('');
    setDepartment('');
    setStatus('');
  };

  const toggleCheck = (id: string) => {
    setCheckedIds(prevSet => {
      const next = new Set(prevSet);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleCheckAll = () => {
    setCheckedIds(prevSet =>
      prevSet.size === rows.length ? new Set() : new Set(rows.map(r => r.reviewId)));
  };

  const doLockBatch = async () => {
    setBusy(true);
    try {
      const res = await performanceService.lockBatch([...checkedIds]);
      const skipMsg = res.skipped.length > 0 ? `, bỏ qua ${res.skipped.length} (chưa đủ điều kiện khóa)` : '';
      showToast(`Đã chốt ${res.locked} bài${skipMsg}.`);
      setCheckedIds(new Set());
      setConfirmLock(false);
      await search();
    } catch (e: any) { showToast(e.message || 'Chốt hàng loạt thất bại.', 'error'); }
    finally { setBusy(false); }
  };

  const doExport = async () => {
    setBusy(true);
    try {
      await performanceService.exportExcel([...checkedIds]);
      showToast(`Đã xuất Excel ${checkedIds.size} bài.`);
    } catch (e: any) { showToast(e.message || 'Xuất Excel thất bại.', 'error'); }
    finally { setBusy(false); }
  };

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-6xl mx-auto">
        <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
          <ClipboardList className="h-5 w-5 text-amber-500" /> {scope === 'company' ? 'Đánh giá toàn công ty' : 'Đánh giá phòng ban'}
        </h1>

        <ScopePill scope={scope} onChange={setScope} deptName={currentUser?.department} canCompany={canCompany} canDept={canDept} />

        {toast && (
          <div className={`mb-3 px-4 py-2.5 rounded-xl text-sm font-medium ${toast.type === 'success' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-rose-50 text-rose-700 border border-rose-200'}`}>
            {toast.text}
          </div>
        )}

        <div className="bg-white border border-slate-200 rounded-2xl p-4 md:p-5 shadow-xs mb-4">
          <div className="flex items-center gap-2 mb-4">
            <Filter className="h-4 w-4 text-amber-500" />
            <span className="text-sm font-bold text-slate-800">Bộ lọc đánh giá</span>
            <span className="flex-1" />
            {(keyword || department || status) && (
              <button onClick={resetFilters}
                className="text-xs font-medium text-slate-500 hover:text-slate-800 transition cursor-pointer">
                Xóa bộ lọc
              </button>
            )}
          </div>
          {/* ponytail: nut Tim kiem rieng — khong fetch lai moi lan doi filter */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div>
              <label className="text-xs font-semibold text-slate-500">Năm</label>
              <select value={year} onChange={e => setYear(Number(e.target.value))}
                className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400">
                {[now.getFullYear() - 2, now.getFullYear() - 1, now.getFullYear()].map(y => <option key={y} value={y}>{y}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-500">Tháng</label>
              <select value={month} onChange={e => setMonth(Number(e.target.value))}
                className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400">
                {Array.from({ length: 12 }, (_, i) => i + 1).map(m => <option key={m} value={m}>Tháng {m}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-500">Trạng thái</label>
              <select value={status} onChange={e => setStatus(e.target.value)}
                className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400">
                <option value="">Tất cả trạng thái</option>
                {Object.entries(REVIEW_STATUS_LABEL).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
              </select>
            </div>
            {/* ponytail: scope phong thi du lieu da loc cung phong — input phong chi co nghia o scope cong ty */}
            {scope === 'company' && (
              <div>
                <label className="text-xs font-semibold text-slate-500">Phòng ban</label>
                <input value={department} onChange={e => setDepartment(e.target.value)} placeholder="Tất cả phòng ban"
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
              </div>
            )}
          </div>
          <div className="relative mt-3">
            <Search className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input value={keyword} onChange={e => setKeyword(e.target.value)} placeholder="Tìm kiếm theo tên nhân viên, mã nhân viên…"
              aria-label="Tìm kiếm theo tên, mã nhân viên"
              className="w-full rounded-xl border border-slate-200 pl-9 pr-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" />
          </div>
          <div className="flex justify-end gap-2 mt-3">
            <button onClick={resetFilters}
              className="flex items-center gap-1.5 px-4 py-2 rounded-xl border border-slate-200 text-slate-600 text-sm font-semibold hover:bg-slate-50 transition cursor-pointer">
              <RotateCcw className="h-4 w-4" /> Đặt lại
            </button>
            <button onClick={search}
              className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-800 text-white text-sm font-semibold hover:bg-slate-900 transition cursor-pointer">
              <Search className="h-4 w-4" /> Tìm kiếm & Lọc
            </button>
          </div>
        </div>

        <div className="bg-white border border-slate-200 rounded-2xl shadow-xs overflow-hidden">
          {checkedIds.size > 0 && (
            <div className="flex flex-wrap items-center gap-2 px-4 py-3 border-b border-slate-100 bg-amber-50/60">
              <span className="text-xs font-semibold text-slate-600">Đã chọn {checkedIds.size} bài</span>
              <span className="flex-1" />
              {canLock && (
                <button onClick={() => setConfirmLock(true)} disabled={busy}
                  className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-amber-600 text-white text-xs font-bold hover:bg-amber-700 transition cursor-pointer disabled:opacity-50">
                  <Lock className="h-3.5 w-3.5" /> Chốt {checkedIds.size} đã chọn
                </button>
              )}
              <button onClick={doExport} disabled={busy}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-800 text-white text-xs font-bold hover:bg-slate-900 transition cursor-pointer disabled:opacity-50">
                <Download className="h-3.5 w-3.5" /> Xuất Excel
              </button>
            </div>
          )}
          {loading ? <p className="text-sm text-slate-400 p-5">Đang tải…</p>
            : rows.length === 0 ? <p className="text-sm text-slate-400 p-5 text-center">Không có bản ghi nào trong kỳ này.</p>
            : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm min-w-[760px]">
                  <thead>
                    <tr className="text-left text-xs text-slate-500 border-b border-slate-100">
                      <th className="px-4 py-2.5">
                        <input type="checkbox" checked={rows.length > 0 && checkedIds.size === rows.length}
                          onChange={toggleCheckAll} aria-label="Chọn tất cả"
                          className="h-4 w-4 rounded accent-amber-600 cursor-pointer" />
                      </th>
                      <th className="px-4 py-2.5 font-semibold">MÃ NV</th>
                      <th className="px-4 py-2.5 font-semibold">HỌ TÊN</th>
                      <th className="px-4 py-2.5 font-semibold">PHÒNG BAN</th>
                      <th className="px-4 py-2.5 font-semibold text-center">TỰ CHẤM</th>
                      <th className="px-4 py-2.5 font-semibold text-center">QUẢN LÝ</th>
                      <th className="px-4 py-2.5 font-semibold">TRẠNG THÁI</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map(r => (
                      <tr key={r.reviewId} onClick={() => setSelected(r)}
                        className="border-b border-slate-50 hover:bg-amber-50/50 cursor-pointer transition">
                        <td className="px-4 py-2.5" onClick={e => e.stopPropagation()}>
                          <input type="checkbox" checked={checkedIds.has(r.reviewId)}
                            onChange={() => toggleCheck(r.reviewId)} aria-label={`Chọn ${r.revieweeName}`}
                            className="h-4 w-4 rounded accent-amber-600 cursor-pointer" />
                        </td>
                        <td className="px-4 py-2.5 font-mono text-xs">{r.employeeCode}</td>
                        <td className="px-4 py-2.5 font-medium">{r.revieweeName}</td>
                        <td className="px-4 py-2.5 text-slate-600">{r.department}</td>
                        <td className="px-4 py-2.5 text-center font-bold text-slate-700">{r.avgSelf ?? '—'}</td>
                        <td className="px-4 py-2.5 text-center font-black text-amber-600">{r.avgManager ?? '—'}</td>
                        <td className="px-4 py-2.5">
                          <span className="text-xs font-semibold px-2 py-1 rounded-full bg-slate-100 text-slate-600">
                            {REVIEW_STATUS_LABEL[r.status]}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          <p className="text-xs text-slate-400 px-4 py-3">Tổng {total} bản ghi.</p>
        </div>

        <ConfirmDialog open={confirmLock}
          title={`Chốt ${checkedIds.size} bài đánh giá đã chọn?`}
          body="Các bài đã chốt sẽ bị khóa (Đã khóa) và không sửa được nữa. Bài chưa đủ điều kiện (chưa được quản lý chấm) sẽ tự động bỏ qua."
          confirmLabel="Chốt sổ"
          busy={busy} onConfirm={doLockBatch} onClose={() => setConfirmLock(false)} />

        {selected && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={() => setSelected(null)}>
            <div className="bg-white rounded-3xl max-w-3xl w-full max-h-[90vh] overflow-y-auto p-5" onClick={e => e.stopPropagation()}>
              <div className="flex justify-end mb-2">
                <button onClick={() => setSelected(null)} className="p-1.5 rounded-lg hover:bg-slate-100 cursor-pointer">
                  <X className="h-5 w-5 text-slate-500" />
                </button>
              </div>
              <ReviewDetail review={selected} showToast={showToast} onChanged={async () => { await search(); setSelected(null); }} />
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
