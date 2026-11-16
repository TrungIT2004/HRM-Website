'use client';

import React, { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { ticketService } from '@/services/ticketService';
import { ItTicket } from '@/types';
import { IT_CATEGORY_LABEL } from './labels';
import { TicketCard } from './TicketCard';
import { TicketDetailModal } from './TicketDetail';
import { useTicketDirectory } from './useTicketDirectory';
import { FileText, Plus, XCircle } from 'lucide-react';

export default function MyTicketsPage() {
  const { currentUser } = useAuth();
  const { nameOf } = useTicketDirectory();
  const [tickets, setTickets] = useState<ItTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');
  const [selected, setSelected] = useState<ItTicket | null>(null);

  const load = async () => {
    setLoading(true);
    try { setTickets(await ticketService.myTickets()); } catch { /* giữ trống */ } finally { setLoading(false); }
  };

  useEffect(() => { if (currentUser) load(); }, [currentUser?.userId]);

  const filtered = useMemo(
    () => tickets.filter((t) => (!status || t.status === status) && (!category || t.category === category)),
    [tickets, status, category],
  );

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-5xl mx-auto">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2">
            <FileText className="h-5 w-5 text-teal-600" /> Đơn của tôi
          </h1>
          <Link href="/tickets/new"
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 transition">
            <Plus className="h-4 w-4" /> Tạo ticket
          </Link>
        </div>
        <div className="flex flex-wrap gap-2 mb-4">
          <select value={status} onChange={(e) => setStatus(e.target.value)}
            className="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-white text-slate-700" aria-label="Lọc trạng thái">
            <option value="">Tất cả trạng thái</option>
            <option value="OPEN">Chờ nhận</option>
            <option value="IN_PROGRESS">Đang xử lý</option>
            <option value="DONE">Hoàn thành</option>
            <option value="CANCELLED">Đã hủy</option>
          </select>
          <select value={category} onChange={(e) => setCategory(e.target.value)}
            className="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-white text-slate-700" aria-label="Lọc loại sự cố">
            <option value="">Tất cả loại</option>
            {Object.entries(IT_CATEGORY_LABEL).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </div>
        {loading ? <p className="text-sm text-slate-400">Đang tải…</p> :
          filtered.length === 0 ? <p className="text-sm text-slate-400">Chưa có ticket nào.</p> :
          <div className="space-y-3">
            {filtered.map((t) => (
              <TicketCard key={t.ticketId} ticket={t}
                handlerName={t.assigneeId ? nameOf(t.assigneeId) : undefined}
                onOpen={() => setSelected(t)}
                footer={(t.status === 'OPEN' || t.status === 'IN_PROGRESS') ? (
                  <button onClick={async () => { await ticketService.cancel(t.ticketId); load(); }}
                    className="inline-flex items-center gap-1.5 text-xs font-semibold px-3.5 py-2 rounded-xl bg-white border border-slate-200 text-slate-500 hover:text-rose-600 hover:border-rose-200 transition cursor-pointer" aria-label="Hủy ticket">
                    <XCircle className="h-3.5 w-3.5" /> Hủy đơn
                  </button>
                ) : undefined} />
            ))}
          </div>}
        {selected && <TicketDetailModal ticket={selected} onClose={() => setSelected(null)} />}
      </div>
    </AppShell>
  );
}
