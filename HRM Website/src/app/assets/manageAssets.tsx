'use client';

import React, { useEffect, useMemo, useRef, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { assetService } from '@/services/assetService';
import { Asset, AssetAssignment, AssetCategory, AssetRequest, AssetTimelineEvent } from '@/types';
import { formatDateVN } from '@/utils/format';
import { ShieldAlert } from 'lucide-react';

// ponytail: 1 hook dùng chung cho 4 routes quản lý — mỗi route tự lọc phần mình cần, khỏi fetch riêng lẻ
export function useManageAssets() {
  const { currentUser, isSysAdmin, can, allUsers } = useAuth();
  const canManage = isSysAdmin || can('MANAGE_ASSETS');
  const canEnter = isSysAdmin || can('VIEW_ASSETS') || canManage;

  const [assets, setAssets] = useState<Asset[]>([]);
  const [categories, setCategories] = useState<AssetCategory[]>([]);
  const [requests, setRequests] = useState<AssetRequest[]>([]);
  const [urgent, setUrgent] = useState<AssetRequest[]>([]);
  const [due, setDue] = useState<AssetAssignment[]>([]);
  const [pendingReturns, setPendingReturns] = useState<AssetAssignment[]>([]);

  const userName = (id?: string) => allUsers.find((u) => u.userId === id)?.fullName ?? (id ? id.slice(0, 8) : '—');
  const catName = (id?: string) => categories.find((c) => c.categoryId === id)?.name ?? '—';
  const assetLabel = (id?: string) => { const a = assets.find((x) => x.assetId === id); return a ? `${a.assetCode} — ${a.name}` : (id ?? '—'); };

  const load = async () => {
    try {
      const [a, c, p, pr] = await Promise.all([
        assetService.listAssets(), assetService.listCategories(),
        assetService.pendingRequests(), assetService.pendingReturns(),
      ]);
      setAssets(a); setCategories(c); setRequests(p); setPendingReturns(pr);
      const [u, d] = await Promise.all([assetService.urgentRequests(7), assetService.dueReturns(7)]);
      setUrgent(u); setDue(d);
    } catch { /* rớt mạng: giữ trống */ }
  };

  useEffect(() => { if (currentUser && canEnter) load(); }, [currentUser?.userId, canEnter]);

  return {
    canManage, canEnter, assets, categories, requests,
    pending: useMemo(() => requests.filter((r) => r.status === 'pending'), [requests]),
    approved: useMemo(() => requests.filter((r) => r.status === 'approved'), [requests]),
    urgent, due, pendingReturns, userName, catName, assetLabel, load,
  };
}

export function ManageGate({ canEnter, children }: { canEnter: boolean; children: React.ReactNode }) {
  if (!canEnter) {
    return (
      <AppShell>
        <div className="p-6 max-w-xl mx-auto text-center text-sm text-slate-500">
          <ShieldAlert className="h-8 w-8 mx-auto mb-2 text-slate-300" />
          Bạn cần quyền xem/quản lý tài sản (VIEW_ASSETS hoặc MANAGE_ASSETS) để vào trang này.
        </div>
      </AppShell>
    );
  }
  return <>{children}</>;
}

// Combobox tìm kiếm tài sản theo mã/tên — native input + listbox, không thêm lib
export function AssetCombobox({ assets, value, onPick, placeholder }: {
  assets: Asset[];
  value: string;
  onPick: (assetId: string) => void;
  placeholder?: string;
}) {
  const [q, setQ] = useState('');
  const [open, setOpen] = useState(false);
  const [hi, setHi] = useState(0);
  const boxRef = useRef<HTMLDivElement>(null);
  const picked = assets.find((a) => a.assetId === value);

  const matches = useMemo(() => {
    const k = q.trim().toLowerCase();
    const list = k
      ? assets.filter((a) => `${a.assetCode} ${a.name}`.toLowerCase().includes(k))
      : assets;
    return list.slice(0, 20); // ponytail: cắt 20 gợi ý — đủ nhanh tay, thêm phân trang khi kho > vài nghìn
  }, [assets, q]);

  useEffect(() => {
    const close = (e: MouseEvent) => { if (!boxRef.current?.contains(e.target as Node)) setOpen(false); };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, []);

  return (
    <div ref={boxRef} className="relative w-full md:w-96">
      <input
        value={open ? q : (picked ? `${picked.assetCode} — ${picked.name}` : q)}
        onChange={(e) => { setQ(e.target.value); setOpen(true); setHi(0); }}
        onFocus={() => setOpen(true)}
        onKeyDown={(e) => {
          if (e.key === 'ArrowDown') { e.preventDefault(); setHi((h) => Math.min(h + 1, matches.length - 1)); }
          else if (e.key === 'ArrowUp') { e.preventDefault(); setHi((h) => Math.max(h - 1, 0)); }
          else if (e.key === 'Enter' && open && matches[hi]) { onPick(matches[hi].assetId); setOpen(false); }
          else if (e.key === 'Escape') setOpen(false);
        }}
        placeholder={placeholder ?? 'Gõ mã hoặc tên để tìm…'}
        role="combobox" aria-expanded={open} aria-activedescendant={open && matches[hi] ? matches[hi].assetId : undefined}
        aria-label="Tìm tài sản"
        className="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:border-teal-600 focus:outline-none"
      />
      {open && matches.length > 0 && (
        <ul role="listbox" className="absolute z-20 mt-1 w-full bg-white border border-slate-200 rounded-xl shadow-lg max-h-60 overflow-y-auto py-1">
          {matches.map((a, i) => (
            <li key={a.assetId} id={a.assetId} role="option" aria-selected={a.assetId === value}
              onMouseDown={() => { onPick(a.assetId); setOpen(false); }}
              className={`px-3 py-2 text-sm cursor-pointer ${i === hi ? 'bg-teal-50 text-teal-800' : 'text-slate-700'}`}>
              <span className="font-mono text-xs text-slate-400 mr-2">{a.assetCode}</span>{a.name}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export function TimelineList({ events }: { events: AssetTimelineEvent[] }) {
  const KIND_LABEL: Record<string, string> = { created: 'Nhập kho', assign: 'Cấp phát', return: 'Thu hồi', maintenance: 'Bảo trì', inventory: 'Kiểm kê' };
  return (
    <div className="relative pl-6 space-y-3 before:absolute before:left-2 before:top-1 before:bottom-1 before:w-px before:bg-slate-200">
      {events.map((e, i) => (
        <div key={i} className="relative bg-white border border-slate-200 rounded-2xl p-3.5 shadow-xs">
          <span className="absolute -left-6 top-4 h-2.5 w-2.5 rounded-full bg-teal-500 ring-4 ring-teal-50" />
          <div className="text-xs font-semibold text-teal-700">{KIND_LABEL[e.kind] ?? e.kind} · {formatDateVN(e.at)}</div>
          <div className="text-sm font-medium text-slate-800 mt-0.5">{e.title}</div>
          {e.actor && <div className="text-xs text-slate-500">{e.actor}</div>}
          {e.note && <div className="text-xs text-slate-600 mt-1">{e.note}</div>}
        </div>
      ))}
    </div>
  );
}
