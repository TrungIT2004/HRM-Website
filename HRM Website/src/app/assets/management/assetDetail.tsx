'use client';

import React, { useEffect, useRef, useState } from 'react';
import { Asset, AssetCategory, AssetImage } from '@/types';
import { assetService } from '@/services/assetService';
import { formatDateVN } from '@/utils/format';
import { ASSET_STATUS_LABEL, assetStatusLabel } from '../labels';
import { X, ChevronLeft, ChevronRight, Pencil, Trash2, ImageOff, ImagePlus } from 'lucide-react';
import ConfirmDialog from '@/components/ConfirmDialog';

// Form nhập/sửa tài sản dùng chung (create + edit chỉ khác initial + submit)
export function AssetForm({ initial, categories, submitLabel, onSubmit, onClose }: {
  initial?: Asset;
  categories: AssetCategory[];
  submitLabel: string;
  onSubmit: (data: any) => Promise<void>;
  onClose: () => void;
}) {
  const [form, setForm] = useState({
    name: initial?.name ?? '', categoryId: initial?.categoryId ?? '',
    serialNumber: initial?.serialNumber ?? '', specs: initial?.specs ?? '',
    purchaseCost: initial?.purchaseCost?.toString() ?? '', supplier: (initial as any)?.supplier ?? '',
    location: initial?.location ?? '', conditionNote: initial?.conditionNote ?? '',
    status: initial?.status ?? 'available',
  });
  const set = (k: string, v: string) => setForm((f) => ({ ...f, [k]: v }));

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="fixed inset-0 bg-slate-900/50" onClick={onClose} />
      <form onSubmit={async (e) => {
        e.preventDefault();
        await onSubmit({
          name: form.name, categoryId: form.categoryId || undefined,
          serialNumber: form.serialNumber || undefined, specs: form.specs || undefined,
          purchaseCost: form.purchaseCost ? Number(form.purchaseCost) : undefined,
          supplier: form.supplier || undefined, location: form.location || undefined,
          conditionNote: form.conditionNote || undefined, status: form.status,
        });
      }} className="relative bg-white rounded-2xl p-5 w-full max-w-md space-y-2.5 shadow-2xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between">
          <h2 className="font-bold text-slate-800">{initial ? 'Cập nhật tài sản' : <>Nhập tài sản <span className="text-xs font-normal text-slate-400">(mã auto)</span></>}</h2>
          <button type="button" onClick={onClose} className="p-1 text-slate-400 hover:text-slate-700 cursor-pointer" aria-label="Đóng"><X className="h-4 w-4" /></button>
        </div>
        {!initial && (
          <select required value={form.categoryId} onChange={(e) => set('categoryId', e.target.value)} className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Loại tài sản">
            <option value="">— Loại tài sản —</option>
            {categories.map((c) => <option key={c.categoryId} value={c.categoryId}>{c.name}</option>)}
          </select>
        )}
        <input required value={form.name} onChange={(e) => set('name', e.target.value)} placeholder="Tên tài sản (vd ThinkPad T14 Gen3)" className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Tên tài sản" />
        <input value={form.serialNumber} onChange={(e) => set('serialNumber', e.target.value)} placeholder="Serial (nếu có)" className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Serial" />
        <input value={form.specs} onChange={(e) => set('specs', e.target.value)} placeholder="Cấu hình…" className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Cấu hình" />
        <div className="grid grid-cols-2 gap-2">
          <input value={form.purchaseCost} onChange={(e) => set('purchaseCost', e.target.value)} placeholder="Giá mua" inputMode="decimal" className="border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Giá mua" />
          <input value={form.supplier} onChange={(e) => set('supplier', e.target.value)} placeholder="Nhà cung cấp" className="border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Nhà cung cấp" />
        </div>
        <input value={form.location} onChange={(e) => set('location', e.target.value)} placeholder="Vị trí (CN-Tòa-Lầu-Phòng)" className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Vị trí" />
        <input value={form.conditionNote} onChange={(e) => set('conditionNote', e.target.value)} placeholder="Tình trạng…" className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Tình trạng" />
        {initial && (
          <select value={form.status} onChange={(e) => set('status', e.target.value)} className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Trạng thái">
            {Object.entries(ASSET_STATUS_LABEL).filter(([v]) => v !== 'assigned').map(([v, label]) => <option key={v} value={v}>{label}</option>)}
          </select>
        )}
        {initial && <AssetImageManager assetId={initial.assetId} />}
        <button type="submit" className="w-full py-2.5 rounded-xl bg-teal-600 text-white text-sm font-semibold hover:bg-teal-700 transition cursor-pointer">{submitLabel}</button>
      </form>
    </div>
  );
}

// Quản lý ảnh ngay trong form Sửa: xem trước, thêm (upload), xóa
function AssetImageManager({ assetId }: { assetId: string }) {
  const [images, setImages] = useState<AssetImage[]>([]);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const reload = async () => {
    try { setImages(await assetService.assetImages(assetId)); } catch { /* giữ cũ */ }
  };
  useEffect(() => { reload(); }, [assetId]);

  return (
    <div className="border border-slate-200 rounded-xl p-2.5">
      <div className="text-xs font-semibold text-slate-500 mb-2">Ảnh ({images.length})</div>
      {images.length > 0 && (
        <div className="grid grid-cols-4 gap-1.5 mb-2">
          {images.map((img) => (
            <div key={img.imageId} className="relative group/img">
              <img src={assetService.resolveImage(img.imageUrl)} alt={img.caption ?? 'Ảnh tài sản'}
                className="h-16 w-full object-cover rounded-lg border border-slate-100" loading="lazy" />
              <button type="button" onClick={async () => { await assetService.deleteImage(img.imageId); reload(); }}
                aria-label="Xóa ảnh"
                className="absolute top-0.5 right-0.5 p-1 rounded-full bg-black/60 text-white opacity-0 group-hover/img:opacity-100 focus:opacity-100 hover:bg-rose-600 transition cursor-pointer">
                <Trash2 className="h-3 w-3" />
              </button>
            </div>
          ))}
        </div>
      )}
      <input ref={fileRef} type="file" accept="image/*" className="hidden" aria-label="Chọn ảnh tải lên"
        onChange={async (e) => {
          const f = e.target.files?.[0];
          if (!f) return;
          setUploading(true);
          try { await assetService.uploadImage(assetId, f); await reload(); }
          finally { setUploading(false); if (fileRef.current) fileRef.current.value = ''; }
        }} />
      <button type="button" disabled={uploading} onClick={() => fileRef.current?.click()}
        className="flex items-center gap-1.5 text-xs font-medium text-teal-700 hover:text-teal-900 transition cursor-pointer disabled:opacity-50">
        <ImagePlus className="h-4 w-4" /> {uploading ? 'Đang tải lên…' : 'Thêm ảnh'}
      </button>
    </div>
  );
}

// Modal chi tiết: carousel ảnh (mũi tên + phím) + toàn bộ thông tin + Sửa/Xóa
export function AssetDetailModal({ asset, catName, holderName, canManage, onEdit, onDeleted, onClose }: {
  asset: Asset;
  catName: string;
  holderName: string;
  canManage: boolean;
  onEdit: () => void;
  onDeleted: () => void;
  onClose: () => void;
}) {
  const [images, setImages] = useState<AssetImage[]>([]);
  const [idx, setIdx] = useState(0);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [busy, setBusy] = useState(false);
  const [deleteError, setDeleteError] = useState('');

  useEffect(() => {
    assetService.assetImages(asset.assetId).then(setImages).catch(() => setImages([]));
  }, [asset.assetId]);

  const n = images.length;
  const go = (d: number) => setIdx((i) => (i + d + n) % n);
  const img = images[idx];

  const rows: [string, string][] = [
    ['Mã', asset.assetCode],
    ['Loại', catName],
    ['Serial', asset.serialNumber ?? '—'],
    ['Trạng thái', assetStatusLabel(asset.status)],
    ['Người giữ', holderName],
    ['Vị trí', asset.location ?? '—'],
    ['Giá mua', asset.purchaseCost ? `${asset.purchaseCost.toLocaleString('vi-VN')}đ` : '—'],
    ['Nhà cung cấp', (asset as any).supplier ?? '—'],
    ['Bảo hành đến', asset.warrantyUntil ? formatDateVN(asset.warrantyUntil) : '—'],
    ['Ngày nhập', formatDateVN(asset.createdAt)],
    ['Tình trạng', asset.conditionNote ?? '—'],
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="fixed inset-0 bg-slate-900/50" onClick={onClose} />
      <div role="dialog" aria-modal="true" aria-label={`Chi tiết ${asset.assetCode}`}
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === 'Escape') onClose();
          else if (e.key === 'ArrowRight' && n > 1) go(1);
          else if (e.key === 'ArrowLeft' && n > 1) go(-1);
        }}
        className="relative bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-2xl outline-none">
        <div className="sticky top-0 bg-white/95 backdrop-blur px-5 py-3.5 border-b border-slate-100 flex items-center justify-between">
          <h2 className="font-bold text-slate-800">{asset.assetCode} — {asset.name}</h2>
          <button onClick={onClose} className="p-1 text-slate-400 hover:text-slate-700 cursor-pointer" aria-label="Đóng"><X className="h-5 w-5" /></button>
        </div>

        {/* Carousel — mũi tên chỉ khi >1 ảnh */}
        <div className="relative bg-slate-100">
          {img ? (
            // ponytail: <img> thuần thay vì next/image — ảnh nội bộ /uploads, khỏi config remotePatterns
            <img key={img.imageId} src={assetService.resolveImage(img.imageUrl)} alt={`${asset.name} — ${img.caption ?? `ảnh ${idx + 1}`}`}
              className="w-full max-h-80 object-contain" />
          ) : (
            <div className="w-full h-48 flex flex-col items-center justify-center gap-2 text-slate-400 text-xs">
              <ImageOff className="h-8 w-8" /> Chưa có ảnh
            </div>
          )}
          {n > 1 && (
            <>
              <button onClick={() => go(-1)} aria-label="Ảnh trước"
                className="absolute left-2 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition cursor-pointer">
                <ChevronLeft className="h-5 w-5" />
              </button>
              <button onClick={() => go(1)} aria-label="Ảnh kế tiếp"
                className="absolute right-2 top-1/2 -translate-y-1/2 p-2 rounded-full bg-black/50 text-white hover:bg-black/70 transition cursor-pointer">
                <ChevronRight className="h-5 w-5" />
              </button>
              <span className="absolute bottom-2 right-2 text-[11px] font-medium bg-black/60 text-white px-2 py-0.5 rounded-full">
                {idx + 1}/{n}
              </span>
            </>
          )}
        </div>
        {img?.caption && <p className="px-5 pt-2 text-xs text-slate-500">{img.caption}</p>}

        <div className="px-5 py-4">
          <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">Cấu hình</h3>
          <p className="text-sm text-slate-700 whitespace-pre-wrap bg-slate-50 border border-slate-100 rounded-xl p-3">{asset.specs || '—'}</p>
          <dl className="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2 text-sm">
            {rows.map(([k, v]) => (
              <div key={k} className="flex gap-2">
                <dt className="text-slate-400 text-xs w-24 shrink-0 pt-0.5">{k}</dt>
                <dd className="text-slate-700 text-xs font-medium">{v}</dd>
              </div>
            ))}
          </dl>
          {deleteError && <p className="mt-3 text-xs text-rose-600">{deleteError}</p>}
          {canManage && (
            <div className="mt-4 flex gap-2 justify-end border-t border-slate-100 pt-3">
              <button onClick={onEdit}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl border border-slate-200 text-slate-700 text-xs font-semibold hover:bg-slate-50 transition cursor-pointer">
                <Pencil className="h-3.5 w-3.5" /> Cập nhật
              </button>
              <button onClick={() => { setDeleteError(''); setConfirmDelete(true); }}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-rose-50 text-rose-700 text-xs font-semibold hover:bg-rose-100 transition cursor-pointer">
                <Trash2 className="h-3.5 w-3.5" /> Xóa
              </button>
            </div>
          )}
        </div>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        title={`Xóa ${asset.assetCode}?`}
        body="Tài sản đã từng cấp phát sẽ bị chặn xóa để giữ lịch sử. Chỉ xóa được tài sản chưa từng cấp cho ai, kèm ảnh và nhật ký của nó."
        confirmLabel="Xóa tài sản"
        busy={busy}
        onClose={() => !busy && setConfirmDelete(false)}
        onConfirm={async () => {
          setBusy(true);
          try {
            await assetService.deleteAsset(asset.assetId);
            setConfirmDelete(false);
            onDeleted();
          } catch (err: any) {
            setDeleteError(err?.message || 'Không xóa được tài sản');
            setConfirmDelete(false);
          } finally { setBusy(false); }
        }}
      />
    </div>
  );
}
