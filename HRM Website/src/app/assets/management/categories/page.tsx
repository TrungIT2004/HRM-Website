'use client';

import React, { useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { assetService } from '@/services/assetService';
import { AssetCategory } from '@/types';
import { useManageAssets, ManageGate } from '../../manageAssets';
import ConfirmDialog from '@/components/ConfirmDialog';
import { Tags, Plus, X, Pencil, Trash2 } from 'lucide-react';

export default function AssetCategoriesPage() {
  const { canManage, canEnter, categories, assets, load } = useManageAssets();
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<AssetCategory | null>(null);
  const [form, setForm] = useState({ name: '', codePrefix: '', description: '' });
  const [deleteTarget, setDeleteTarget] = useState<AssetCategory | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const countOf = (id: string) => assets.filter((a) => a.categoryId === id).length;
  const openCreate = () => { setEditing(null); setForm({ name: '', codePrefix: '', description: '' }); setShowForm(true); };
  const openEdit = (c: AssetCategory) => { setEditing(c); setForm({ name: c.name, codePrefix: c.codePrefix, description: c.description ?? '' }); setShowForm(true); };

  return (
    <ManageGate canEnter={canEnter}>
      <AppShell>
        <div className="p-4 md:p-6 max-w-6xl mx-auto">
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2">
              <Tags className="h-5 w-5 text-teal-600" /> Danh mục tài sản
            </h1>
            {canManage && (
              <button onClick={openCreate}
                className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 transition cursor-pointer">
                <Plus className="h-4 w-4" /> Thêm danh mục
              </button>
            )}
          </div>
          {error && <p className="mb-3 text-xs text-rose-600">{error}</p>}
          <div className="bg-white border border-slate-200 rounded-2xl overflow-x-auto shadow-xs">
            <table className="w-full text-sm min-w-[640px]">
              <thead><tr className="text-left text-xs text-slate-400 border-b border-slate-100">
                <th className="px-4 py-2.5">Tên</th><th className="px-4 py-2.5">Tiền tố mã</th>
                <th className="px-4 py-2.5">Mô tả</th><th className="px-4 py-2.5 text-right">Đang có</th>
                {canManage && <th className="px-4 py-2.5 text-right">Thao tác</th>}
              </tr></thead>
              <tbody>
                {categories.map((c) => (
                  <tr key={c.categoryId} className="border-b border-slate-50 hover:bg-slate-50">
                    <td className="px-4 py-2.5 font-medium">{c.name}</td>
                    <td className="px-4 py-2.5 font-mono text-xs">{c.codePrefix}</td>
                    <td className="px-4 py-2.5 text-xs text-slate-500">{c.description ?? '—'}</td>
                    <td className="px-4 py-2.5 text-right text-xs">{countOf(c.categoryId)}</td>
                    {canManage && (
                      <td className="px-4 py-2.5 text-right">
                        <div className="inline-flex gap-1">
                          <button onClick={() => openEdit(c)} aria-label={`Sửa ${c.name}`}
                            className="p-1.5 text-slate-400 hover:text-teal-700 rounded-lg transition cursor-pointer">
                            <Pencil className="h-4 w-4" />
                          </button>
                          <button onClick={() => { setError(''); setDeleteTarget(c); }} aria-label={`Xóa ${c.name}`}
                            className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg transition cursor-pointer">
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
                {categories.length === 0 && <tr><td colSpan={5} className="px-4 py-6 text-center text-xs text-slate-400">Chưa có danh mục.</td></tr>}
              </tbody>
            </table>
          </div>

          {showForm && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
              <div className="fixed inset-0 bg-slate-900/50" onClick={() => setShowForm(false)} />
              <form onSubmit={async (e) => {
                e.preventDefault();
                if (editing) await assetService.updateCategory(editing.categoryId, { name: form.name, description: form.description || undefined });
                else await assetService.createCategory({ name: form.name, codePrefix: form.codePrefix, description: form.description || undefined });
                setShowForm(false); load();
              }} className="relative bg-white rounded-2xl p-5 w-full max-w-md space-y-2.5 shadow-2xl">
                <div className="flex items-center justify-between">
                  <h2 className="font-bold text-slate-800">{editing ? 'Sửa danh mục' : 'Thêm danh mục'}</h2>
                  <button type="button" onClick={() => setShowForm(false)} className="p-1 text-slate-400 hover:text-slate-700 cursor-pointer" aria-label="Đóng"><X className="h-4 w-4" /></button>
                </div>
                <input required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Tên (vd Laptop)" className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Tên danh mục" />
                {!editing && (
                  <input required value={form.codePrefix} onChange={(e) => setForm({ ...form, codePrefix: e.target.value.toUpperCase() })} placeholder="Tiền tố mã (vd LT)" maxLength={10} className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono" aria-label="Tiền tố mã" />
                )}
                <input value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} placeholder="Mô tả…" className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm" aria-label="Mô tả" />
                <button type="submit" className="w-full py-2.5 rounded-xl bg-teal-600 text-white text-sm font-semibold hover:bg-teal-700 transition cursor-pointer">
                  {editing ? 'Lưu' : 'Thêm'}
                </button>
              </form>
            </div>
          )}

          <ConfirmDialog
            open={deleteTarget !== null}
            title={`Xóa danh mục ${deleteTarget?.name}?`}
            body="Loại còn tài sản trong kho sẽ bị chặn xóa. Chỉ xóa được loại trống."
            confirmLabel="Xóa danh mục"
            busy={busy}
            onClose={() => !busy && setDeleteTarget(null)}
            onConfirm={async () => {
              if (!deleteTarget) return;
              setBusy(true);
              try {
                await assetService.deleteCategory(deleteTarget.categoryId);
                setDeleteTarget(null); load();
              } catch (err: any) {
                setError(err?.message || 'Không xóa được danh mục');
                setDeleteTarget(null);
              } finally { setBusy(false); }
            }}
          />
        </div>
      </AppShell>
    </ManageGate>
  );
}
