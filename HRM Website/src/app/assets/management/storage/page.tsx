'use client';

import React, { useMemo, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { assetService } from '@/services/assetService';
import { Asset } from '@/types';
import { ASSET_STATUS_LABEL, assetStatusLabel } from '../../labels';
import { useManageAssets, ManageGate } from '../../manageAssets';
import { AssetDetailModal, AssetForm } from '../assetDetail';
import { Package, Plus, Search, Eye } from 'lucide-react';

// ponytail: lọc client-side (kho V1 vài trăm món) — chuyển sang query backend khi kho > vài nghìn
export default function AssetStoragePage() {
  const { canManage, canEnter, assets, categories, userName, catName, load } = useManageAssets();
  const [keyword, setKeyword] = useState('');
  const [status, setStatus] = useState('ALL');
  const [categoryId, setCategoryId] = useState('ALL');
  // ponytail: nháp vs đã áp dụng — bảng chỉ lọc khi bấm Tìm kiếm (kẻo gõ chữ nào nhảy chữ đó)
  const [applied, setApplied] = useState({ keyword: '', status: 'ALL', categoryId: 'ALL' });
  const [showForm, setShowForm] = useState(false);
  const [detail, setDetail] = useState<Asset | null>(null);
  const [editing, setEditing] = useState<Asset | null>(null);

  const filtered = useMemo(() => {
    const k = applied.keyword.trim().toLowerCase();
    return assets.filter((a) =>
      (!k || `${a.assetCode} ${a.name}`.toLowerCase().includes(k)) &&
      (applied.status === 'ALL' || a.status === applied.status) &&
      (applied.categoryId === 'ALL' || a.categoryId === applied.categoryId));
  }, [assets, applied]);
  const isFiltered = applied.keyword !== '' || applied.status !== 'ALL' || applied.categoryId !== 'ALL';

  return (
    <ManageGate canEnter={canEnter}>
      <AppShell>
        <div className="p-4 md:p-6 max-w-6xl mx-auto">
          <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
            <Package className="h-5 w-5 text-teal-600" /> Kho tài sản
          </h1>
          <form onSubmit={(e) => { e.preventDefault(); setApplied({ keyword, status, categoryId }); }}
            className="flex flex-wrap items-center gap-2 mb-3">
            <div className="relative flex-1 min-w-52">
              <Search className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input value={keyword} onChange={(e) => setKeyword(e.target.value)} placeholder="Tìm theo mã, tên tài sản…"
                aria-label="Tìm theo mã, tên tài sản"
                className="w-full border border-slate-200 rounded-xl pl-9 pr-3 py-2 text-sm focus:border-teal-600 focus:outline-none" />
            </div>
            <select value={status} onChange={(e) => setStatus(e.target.value)} aria-label="Lọc theo trạng thái"
              className="border border-slate-200 rounded-xl px-3 py-2 text-sm bg-white">
              <option value="ALL">Mọi trạng thái</option>
              {Object.entries(ASSET_STATUS_LABEL).map(([v, label]) => (
                <option key={v} value={v}>{label}</option>
              ))}
            </select>
            <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)} aria-label="Lọc theo loại tài sản"
              className="border border-slate-200 rounded-xl px-3 py-2 text-sm bg-white">
              <option value="ALL">Mọi loại</option>
              {categories.map((c) => <option key={c.categoryId} value={c.categoryId}>{c.name}</option>)}
            </select>
            <button type="submit"
              className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-slate-800 text-white text-sm font-medium hover:bg-slate-900 transition cursor-pointer">
              <Search className="h-4 w-4" /> Tìm kiếm
            </button>
            {isFiltered && (
              <button type="button" onClick={() => { setKeyword(''); setStatus('ALL'); setCategoryId('ALL'); setApplied({ keyword: '', status: 'ALL', categoryId: 'ALL' }); }}
                className="text-xs text-slate-500 hover:text-slate-800 font-medium transition cursor-pointer">
                Xóa lọc
              </button>
            )}
            {canManage && (
              <button type="button" onClick={() => setShowForm(true)}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 transition cursor-pointer">
                <Plus className="h-4 w-4" /> Nhập tài sản
              </button>
            )}
          </form>
          <p className="text-xs text-slate-400 mb-2">{filtered.length}/{assets.length} tài sản</p>
          <div className="bg-white border border-slate-200 rounded-2xl overflow-x-auto shadow-xs">
            <table className="w-full text-sm min-w-[760px]">
              <thead><tr className="text-left text-xs text-slate-400 border-b border-slate-100">
                <th className="px-4 py-2.5">Mã</th><th className="px-4 py-2.5">Tên</th><th className="px-4 py-2.5">Loại</th>
                <th className="px-4 py-2.5">Trạng thái</th><th className="px-4 py-2.5">Người giữ</th><th className="px-4 py-2.5">Vị trí</th>
                <th className="px-4 py-2.5 text-right">Thao tác</th>
              </tr></thead>
              <tbody>
                {filtered.map((a) => (
                  <tr key={a.assetId} className="border-b border-slate-50 hover:bg-slate-50">
                    <td className="px-4 py-2.5 font-mono text-xs">{a.assetCode}</td>
                    <td className="px-4 py-2.5 font-medium">{a.name}</td>
                    <td className="px-4 py-2.5">{catName(a.categoryId)}</td>
                    <td className="px-4 py-2.5"><span className="text-xs bg-slate-100 px-2 py-0.5 rounded-lg">{assetStatusLabel(a.status)}</span></td>
                    <td className="px-4 py-2.5 text-xs">{a.currentHolderId ? userName(a.currentHolderId) : '—'}</td>
                    <td className="px-4 py-2.5 text-xs text-slate-500">{a.location ?? '—'}</td>
                    <td className="px-4 py-2.5 text-right">
                      <button onClick={() => setDetail(a)}
                        className="inline-flex items-center gap-1 text-xs font-medium text-teal-700 hover:text-teal-900 transition cursor-pointer" aria-label={`Xem chi tiết ${a.assetCode}`}>
                        <Eye className="h-3.5 w-3.5" /> Chi tiết
                      </button>
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 && <tr><td colSpan={7} className="px-4 py-6 text-center text-xs text-slate-400">Không khớp tìm kiếm.</td></tr>}
              </tbody>
            </table>
          </div>

          {showForm && (
            <AssetForm categories={categories} submitLabel="Nhập kho"
              onSubmit={async (data) => { await assetService.createAsset(data); setShowForm(false); load(); }}
              onClose={() => setShowForm(false)} />
          )}

          {editing && (
            <AssetForm initial={editing} categories={categories} submitLabel="Lưu thay đổi"
              onSubmit={async (data) => {
                const updated = await assetService.updateAsset(editing.assetId, data);
                setEditing(null); setDetail(updated); load();
              }}
              onClose={() => setEditing(null)} />
          )}

          {detail && !editing && (
            <AssetDetailModal asset={detail}
              catName={catName(detail.categoryId)}
              holderName={detail.currentHolderId ? userName(detail.currentHolderId) : '—'}
              canManage={canManage}
              onEdit={() => setEditing(detail)}
              onDeleted={() => { setDetail(null); load(); }}
              onClose={() => setDetail(null)} />
          )}
        </div>
      </AppShell>
    </ManageGate>
  );
}
