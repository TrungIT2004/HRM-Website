'use client';

import React, { useState } from 'react';
import { assetService } from '@/services/assetService';
import { AssetCategory } from '@/types';
import { FilePlus2, X } from 'lucide-react';

// ponytail: 1 modal dùng chung cho /assets và /assets/requests
export function RequestAssetModal({ categories, onDone, onClose }: {
  categories: AssetCategory[];
  onDone: () => void;
  onClose: () => void;
}) {
  const [form, setForm] = useState({ categoryId: '', reason: '', neededByDate: '', expectedReturnDate: '' });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="fixed inset-0 bg-slate-900/50" onClick={onClose} />
      <form onSubmit={async (e) => {
        e.preventDefault();
        await assetService.createRequest({
          categoryId: form.categoryId, reason: form.reason,
          neededByDate: form.neededByDate || undefined,
          expectedReturnDate: form.expectedReturnDate || undefined,
        });
        onDone();
      }} className="relative bg-white rounded-2xl p-5 w-full max-w-md space-y-3 shadow-2xl">
        <div className="flex items-center justify-between">
          <h2 className="font-bold text-slate-800 flex items-center gap-2"><FilePlus2 className="h-4 w-4" /> Đơn xin tài sản</h2>
          <button type="button" onClick={onClose} className="p-1 text-slate-400 hover:text-slate-700 cursor-pointer" aria-label="Đóng"><X className="h-4 w-4" /></button>
        </div>
        <select required value={form.categoryId} onChange={(e) => setForm({ ...form, categoryId: e.target.value })}
          className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Loại tài sản">
          <option value="">— Chọn loại tài sản —</option>
          {categories.map((c) => <option key={c.categoryId} value={c.categoryId}>{c.name}</option>)}
        </select>
        <textarea required value={form.reason} onChange={(e) => setForm({ ...form, reason: e.target.value })}
          placeholder="Lý do cần tài sản…" rows={3} className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Lý do" />
        <div className="grid grid-cols-2 gap-2">
          <label className="text-xs text-slate-500">Cần trước ngày<input type="date" value={form.neededByDate}
            onChange={(e) => setForm({ ...form, neededByDate: e.target.value })}
            className="mt-1 w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" /></label>
          <label className="text-xs text-slate-500">Trả dự kiến<input type="date" value={form.expectedReturnDate}
            onChange={(e) => setForm({ ...form, expectedReturnDate: e.target.value })}
            className="mt-1 w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" /></label>
        </div>
        <button type="submit" className="w-full py-2.5 rounded-xl bg-teal-600 text-white text-sm font-semibold hover:bg-teal-700 transition cursor-pointer">Gửi đơn</button>
      </form>
    </div>
  );
}
