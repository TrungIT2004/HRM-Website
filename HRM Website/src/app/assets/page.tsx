'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { assetService } from '@/services/assetService';
import { Asset, AssetAssignment } from '@/types';
import { formatDateVN } from '@/utils/format';
import { Box, Plus, RotateCcw, Wrench } from 'lucide-react';
import { RequestAssetModal } from './requestAsset';
import { useMyAssetLookups } from './useMyAssets';

export default function MyAssetsPage() {
  const { currentUser } = useAuth();
  const { categories, loadLookups } = useMyAssetLookups();
  const [assets, setAssets] = useState<(AssetAssignment & { asset?: Asset })[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const assigns = await assetService.myAssets();
      // ponytail: N+1 getAsset cho đồ mình giữ (N nhỏ) — gộp API khi cần
      const enriched = await Promise.all(assigns.map(async (a) => {
        try { return { ...a, asset: await assetService.getAsset(a.assetId) }; }
        catch { return a; }
      }));
      setAssets(enriched);
    } catch { /* rớt mạng: hiện trống */ } finally { setLoading(false); }
  };

  useEffect(() => { if (currentUser) { load(); loadLookups(); } }, [currentUser?.userId]);

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-5xl mx-auto">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2">
            <Box className="h-5 w-5 text-teal-600" /> Tài sản của tôi
          </h1>
          <button onClick={() => setShowForm(true)}
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 transition cursor-pointer">
            <Plus className="h-4 w-4" /> Xin tài sản
          </button>
        </div>
        {loading ? <p className="text-sm text-slate-400">Đang tải…</p> :
          assets.length === 0 ? <p className="text-sm text-slate-400">Bạn chưa được cấp tài sản nào.</p> :
          <div className="grid gap-3 md:grid-cols-2">
            {assets.map((a) => (
              <div key={a.assignmentId} className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs">
                <div className="font-semibold text-slate-800">{a.asset?.assetCode ?? a.assetId} — {a.asset?.name ?? ''}</div>
                {a.scope === 'DEPARTMENT' && (
                  <span className="inline-block mt-1 text-[11px] font-medium text-blue-700 bg-blue-50 px-2 py-0.5 rounded-lg">Đồ dùng chung phòng ban</span>
                )}
                <div className="text-xs text-slate-500 mt-1">Nhận: {formatDateVN(a.assignedAt)}{a.expectedReturnDate ? ` · Trả dự kiến: ${formatDateVN(a.expectedReturnDate)}` : ''}</div>
                {a.asset?.conditionNote && <div className="text-xs text-slate-600 mt-1">Tình trạng: {a.asset.conditionNote}</div>}
                <div className="mt-3 flex items-center gap-2">
                  {a.status === 'active' ? (
                    <button onClick={async () => { await assetService.requestReturn(a.assignmentId); load(); }}
                      className="flex items-center gap-1.5 text-xs font-medium text-amber-700 bg-amber-50 px-3 py-1.5 rounded-lg hover:bg-amber-100 transition cursor-pointer">
                      <RotateCcw className="h-3.5 w-3.5" /> Trả tài sản
                    </button>
                  ) : <span className="text-xs text-slate-400">Chờ quản lý xác nhận thu hồi</span>}
                  <Link href={`/tickets/new?device=${encodeURIComponent(`${a.asset?.assetCode ?? ''} — ${a.asset?.name ?? ''}`.trim())}`}
                    className="flex items-center gap-1.5 text-xs font-medium text-rose-700 bg-rose-50 px-3 py-1.5 rounded-lg hover:bg-rose-100 transition">
                    <Wrench className="h-3.5 w-3.5" /> Báo hỏng
                  </Link>
                </div>
              </div>
            ))}
          </div>}
        {showForm && <RequestAssetModal categories={categories} onDone={() => { setShowForm(false); }} onClose={() => setShowForm(false)} />}
      </div>
    </AppShell>
  );
}
