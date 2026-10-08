'use client';

import React, { useEffect, useMemo, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { assetService } from '@/services/assetService';
import { organizationService, DepartmentDto } from '@/services/organizationService';
import { AssetRequest } from '@/types';
import { formatDateVN } from '@/utils/format';
import { requestStatusLabel } from '../../labels';
import { useManageAssets, ManageGate, AssetCombobox } from '../../manageAssets';
import { FileCheck, X } from 'lucide-react';

export default function AssetFormsPage() {
  const { canManage, canEnter, assets, pending, approved, pendingReturns, userName, catName, assetLabel, load } = useManageAssets();
  const [assignFor, setAssignFor] = useState<AssetRequest | null>(null);
  const [assignAssetId, setAssignAssetId] = useState('');
  const [assignDept, setAssignDept] = useState(false);
  const [departments, setDepartments] = useState<DepartmentDto[]>([]);
  const [assignDeptId, setAssignDeptId] = useState('');

  useEffect(() => {
    if (canManage) organizationService.getAllDepartments().then(setDepartments).catch(() => { /* giữ trống */ });
  }, [canManage]);

  const availableFor = useMemo(() => {
    if (!assignFor) return [];
    return assets.filter((a) => a.status === 'available' && a.categoryId === assignFor.categoryId);
  }, [assets, assignFor]);

  return (
    <ManageGate canEnter={canEnter}>
      <AppShell>
        <div className="p-4 md:p-6 max-w-6xl mx-auto">
          <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
            <FileCheck className="h-5 w-5 text-teal-600" /> Duyệt đơn
          </h1>
          <div className="space-y-2">
            {pending.length === 0 && approved.length === 0 && <p className="text-sm text-slate-400">Không có đơn cần xử lý.</p>}
            {[...pending, ...approved].map((r) => (
              <div key={r.requestId} className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs flex items-start justify-between gap-3">
                <div>
                  <div className="font-medium text-slate-800 text-sm">{catName(r.categoryId)} — {userName(r.requestorId)}</div>
                  <div className="text-xs text-slate-500 mt-0.5">{r.reason}{r.neededByDate ? ` · Cần trước: ${formatDateVN(r.neededByDate)}` : ''}</div>
                  <span className="inline-block mt-1 text-xs bg-slate-100 px-2 py-0.5 rounded-lg">{requestStatusLabel(r.status)}</span>
                </div>
                {canManage && r.status === 'pending' && (
                  <div className="flex gap-2 shrink-0">
                    <button onClick={async () => { await assetService.handleRequest(r.requestId, true); load(); }}
                      className="text-xs font-medium px-3 py-1.5 rounded-lg bg-teal-600 text-white hover:bg-teal-700 transition cursor-pointer">Duyệt</button>
                    <button onClick={async () => { const reason = prompt('Lý do từ chối:'); if (reason !== null) { await assetService.handleRequest(r.requestId, false, reason); load(); } }}
                      className="text-xs font-medium px-3 py-1.5 rounded-lg bg-slate-100 text-slate-600 hover:bg-slate-200 transition cursor-pointer">Từ chối</button>
                  </div>
                )}
                {canManage && r.status === 'approved' && (
                  <button onClick={() => { setAssignFor(r); setAssignAssetId(''); }}
                    className="text-xs font-medium px-3 py-1.5 rounded-lg bg-blue-600 text-white hover:bg-blue-700 transition cursor-pointer shrink-0">Cấp phát</button>
                )}
              </div>
            ))}
            {pendingReturns.length > 0 && (
              <div className="pt-2">
                <h3 className="text-sm font-semibold text-slate-700 mb-2">Chờ xác nhận thu hồi</h3>
                {pendingReturns.map((a) => (
                  <div key={a.assignmentId} className="bg-amber-50 border border-amber-200 rounded-2xl p-4 text-sm flex items-center justify-between gap-3">
                    <span>{assetLabel(a.assetId)} — {a.scope === 'DEPARTMENT' ? 'Cả phòng ban' : userName(a.userId ?? undefined)}</span>
                    {canManage && (
                      <button onClick={async () => { const note = prompt('Tình trạng lúc nhận:', ''); if (note !== null) { await assetService.confirmReturn(a.assignmentId, note); load(); } }}
                        className="text-xs font-medium px-3 py-1.5 rounded-lg bg-amber-600 text-white hover:bg-amber-700 transition cursor-pointer shrink-0">Đã nhận</button>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          {assignFor && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
              <div className="fixed inset-0 bg-slate-900/50" onClick={() => setAssignFor(null)} />
              <div className="relative bg-white rounded-2xl p-5 w-full max-w-md space-y-3 shadow-2xl">
                <div className="flex items-center justify-between">
                  <h2 className="font-bold text-slate-800 flex items-center gap-2"><FileCheck className="h-4 w-4" /> Cấp phát</h2>
                  <button onClick={() => setAssignFor(null)} className="p-1 text-slate-400 hover:text-slate-700 cursor-pointer" aria-label="Đóng"><X className="h-4 w-4" /></button>
                </div>
                <p className="text-xs text-slate-500">{catName(assignFor.categoryId)} → {userName(assignFor.requestorId)}</p>
                <AssetCombobox assets={availableFor} value={assignAssetId} onPick={setAssignAssetId} placeholder="Gõ mã còn trống để chọn…" />
                {availableFor.length === 0 && <p className="text-xs text-amber-600">Hết hàng loại này trong kho.</p>}
                <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                  <input type="checkbox" checked={assignDept} onChange={(e) => setAssignDept(e.target.checked)} className="h-4 w-4 accent-teal-600" />
                  Cấp cho cả phòng ban (đồ dùng chung)
                </label>
                {assignDept && (
                  <select value={assignDeptId} onChange={(e) => setAssignDeptId(e.target.value)}
                    className="w-full text-sm border border-slate-200 rounded-xl px-3 py-2.5 bg-white" aria-label="Chọn phòng ban">
                    <option value="">— Chọn phòng ban —</option>
                    {departments.map((d) => (
                      <option key={d.departmentId} value={d.departmentId}>{d.name}</option>
                    ))}
                  </select>
                )}
                <button disabled={!assignAssetId || (assignDept && !assignDeptId)} onClick={async () => {
                  await assetService.assign(assignFor.requestId, assignAssetId, undefined, assignDept ? assignDeptId : undefined);
                  setAssignFor(null); setAssignDept(false); setAssignDeptId(''); load();
                }} className="w-full py-2.5 rounded-xl bg-blue-600 text-white text-sm font-semibold hover:bg-blue-700 transition cursor-pointer disabled:opacity-40">Xác nhận cấp</button>
              </div>
            </div>
          )}
        </div>
      </AppShell>
    </ManageGate>
  );
}
