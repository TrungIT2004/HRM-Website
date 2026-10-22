'use client';

import React, { Suspense, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import AppShell from '@/components/layout/AppShell';
import { ticketService } from '@/services/ticketService';
import { IT_CATEGORY_LABEL } from '../labels';
import { ImagePlus, PlusCircle, X } from 'lucide-react';

function NewTicketForm() {
  const router = useRouter();
  const params = useSearchParams();
  const [deviceInfo, setDeviceInfo] = useState(params.get('device') ?? '');
  const [category, setCategory] = useState('LAPTOP_PC');
  const [description, setDescription] = useState('');
  const [location, setLocation] = useState('');
  const [priority, setPriority] = useState('NORMAL');
  const [image, setImage] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!deviceInfo.trim() || !description.trim()) {
      setError('Vui lòng nhập thiết bị và mô tả.');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const created = await ticketService.create({ deviceInfo: deviceInfo.trim(), category, description: description.trim(), location: location.trim() || undefined, priority });
      if (image) {
        try { await ticketService.uploadImage(created.ticketId, image); } catch { /* tạo được, ảnh lỗi thì bỏ qua */ }
      }
      router.push('/tickets');
    } catch {
      setError('Không tạo được ticket. Vui lòng thử lại.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-4 md:p-6 max-w-2xl mx-auto">
      <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
        <PlusCircle className="h-5 w-5 text-teal-600" /> Tạo IT ticket
      </h1>
      <form onSubmit={submit} className="bg-white border border-slate-200 rounded-2xl p-5 space-y-4 shadow-xs">
        <div>
          <label className="text-sm font-medium text-slate-700" htmlFor="device">Thiết bị hỏng *</label>
          <input id="device" value={deviceInfo} onChange={(e) => setDeviceInfo(e.target.value)}
            placeholder="VD: Máy photo P.Nhân sự, Laptop Dell cá nhân"
            className="mt-1 w-full text-sm border border-slate-200 rounded-xl px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-teal-500" />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="text-sm font-medium text-slate-700" htmlFor="category">Loại sự cố *</label>
            <select id="category" value={category} onChange={(e) => setCategory(e.target.value)}
              className="mt-1 w-full text-sm border border-slate-200 rounded-xl px-3 py-2.5 bg-white">
              {Object.entries(IT_CATEGORY_LABEL).map(([k, v]) => (
                <option key={k} value={k}>{v}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="text-sm font-medium text-slate-700" htmlFor="priority">Mức độ</label>
            <select id="priority" value={priority} onChange={(e) => setPriority(e.target.value)}
              className="mt-1 w-full text-sm border border-slate-200 rounded-xl px-3 py-2.5 bg-white">
              <option value="NORMAL">Thường</option>
              <option value="HIGH">Gấp — cần xử lý ngay</option>
            </select>
          </div>
        </div>
        <div>
          <label className="text-sm font-medium text-slate-700" htmlFor="desc">Mô tả hiện trạng *</label>
          <textarea id="desc" value={description} onChange={(e) => setDescription(e.target.value)} rows={4}
            placeholder="VD: Kẹt giấy liên tục, đã thử tắt mở vẫn không được"
            className="mt-1 w-full text-sm border border-slate-200 rounded-xl px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-teal-500" />
        </div>
        <div>
          <label className="text-sm font-medium text-slate-700" htmlFor="location">Vị trí</label>
          <input id="location" value={location} onChange={(e) => setLocation(e.target.value)}
            placeholder="VD: P.Nhân sự - tầng 2"
            className="mt-1 w-full text-sm border border-slate-200 rounded-xl px-3 py-2.5 focus:outline-none focus:ring-2 focus:ring-teal-500" />
        </div>
        <div>
          <span className="text-sm font-medium text-slate-700">Ảnh hiện trạng (1 ảnh)</span>
          <input id="image" type="file" accept="image/*" onChange={(e) => setImage(e.target.files?.[0] ?? null)}
            className="sr-only" aria-label="Ảnh hiện trạng" />
          {!image ? (
            <label htmlFor="image"
              className="mt-1.5 flex items-center justify-center gap-2 w-full rounded-xl border-2 border-dashed border-slate-200 bg-slate-50/60 px-4 py-5 text-sm text-slate-500 hover:border-teal-400 hover:bg-teal-50/50 hover:text-teal-700 transition cursor-pointer">
              <ImagePlus className="h-5 w-5" />
              Bấm để chọn ảnh từ máy
            </label>
          ) : (
            <div className="mt-1.5 flex items-center gap-3 rounded-xl border border-slate-200 bg-slate-50/60 p-3">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={URL.createObjectURL(image)} alt="Ảnh đã chọn" className="h-14 w-14 rounded-lg object-cover border border-slate-200" />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-slate-700 truncate">{image.name}</p>
                <p className="text-xs text-slate-400">{(image.size / 1024).toFixed(0)} KB</p>
              </div>
              <button type="button" onClick={() => setImage(null)}
                className="p-2 text-slate-400 hover:text-rose-600 rounded-lg transition cursor-pointer" aria-label="Xóa ảnh">
                <X className="h-4 w-4" />
              </button>
            </div>
          )}
        </div>
        {error && <p className="text-sm text-rose-600">{error}</p>}
        <button type="submit" disabled={saving}
          className="w-full py-2.5 rounded-xl bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 transition disabled:opacity-60 cursor-pointer">
          {saving ? 'Đang gửi…' : 'Gửi ticket'}
        </button>
      </form>
    </div>
  );
}

export default function NewTicketPage() {
  return (
    <AppShell>
      <Suspense fallback={<p className="p-6 text-sm text-slate-400">Đang tải…</p>}>
        <NewTicketForm />
      </Suspense>
    </AppShell>
  );
}
