'use client';

import React, { useEffect, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { assetService } from '@/services/assetService';
import { AssetRequest } from '@/types';
import { formatDateVN } from '@/utils/format';
import { requestStatusLabel } from '../labels';
import { FileText, Plus, XCircle } from 'lucide-react';
import { RequestAssetModal } from '../requestAsset';
import { useMyAssetLookups } from '../useMyAssets';

export default function MyAssetRequestsPage() {
  const { currentUser } = useAuth();
  const { categories, catName, loadLookups } = useMyAssetLookups();
  const [requests, setRequests] = useState<AssetRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);

  const load = async () => {
    setLoading(true);
    try { setRequests(await assetService.myRequests()); } catch { /* giữ trống */ } finally { setLoading(false); }
  };

  useEffect(() => { if (currentUser) { load(); loadLookups(); } }, [currentUser?.userId]);

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-5xl mx-auto">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2">
            <FileText className="h-5 w-5 text-teal-600" /> Đơn của tôi
          </h1>
          <button onClick={() => setShowForm(true)}
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 transition cursor-pointer">
            <Plus className="h-4 w-4" /> Xin tài sản
          </button>
        </div>
        {loading ? <p className="text-sm text-slate-400">Đang tải…</p> :
          requests.length === 0 ? <p className="text-sm text-slate-400">Chưa có đơn nào.</p> :
          <div className="space-y-2">
            {requests.map((r) => (
              <div key={r.requestId} className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs flex items-start justify-between gap-3">
                <div>
                  <div className="font-medium text-slate-800 text-sm">{catName(r.categoryId)}</div>
                  <div className="text-xs text-slate-500 mt-0.5">{r.reason}{r.neededByDate ? ` · Cần trước: ${formatDateVN(r.neededByDate)}` : ''}</div>
                  {r.rejectionReason && <div className="text-xs text-rose-600 mt-0.5">Lý do từ chối: {r.rejectionReason}</div>}
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span className="text-xs font-medium text-slate-600 bg-slate-100 px-2.5 py-1 rounded-lg">{requestStatusLabel(r.status)}</span>
                  {r.status === 'pending' && (
                    <button onClick={async () => { await assetService.cancelRequest(r.requestId); load(); }}
                      className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg transition cursor-pointer" aria-label="Hủy đơn">
                      <XCircle className="h-4 w-4" />
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>}
        {showForm && <RequestAssetModal categories={categories} onDone={() => { setShowForm(false); load(); }} onClose={() => setShowForm(false)} />}
      </div>
    </AppShell>
  );
}
