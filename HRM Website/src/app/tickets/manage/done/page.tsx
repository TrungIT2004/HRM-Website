'use client';

import React, { useEffect, useMemo, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { ticketService } from '@/services/ticketService';
import { ItTicket } from '@/types';
import { IT_CATEGORY_LABEL } from '../../labels';
import { TicketCard } from '../../TicketCard';
import { TicketDetailModal } from '../../TicketDetail';
import { useTicketDirectory } from '../../useTicketDirectory';
import { History } from 'lucide-react';

export default function TicketDonePage() {
  const { currentUser, can } = useAuth();
  const canHandle = can('IT_TICKET_HANDLE');
  const { nameOf } = useTicketDirectory();
  const [tickets, setTickets] = useState<ItTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');
  const [selected, setSelected] = useState<ItTicket | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const [done, cancelled] = await Promise.all([
        ticketService.queue('DONE'),
        ticketService.queue('CANCELLED'),
      ]);
      setTickets([...done, ...cancelled].sort((a, b) => b.createdAt.localeCompare(a.createdAt)));
    } catch { /* giữ trống */ } finally { setLoading(false); }
  };

  useEffect(() => { if (currentUser && canHandle) load(); }, [currentUser?.userId, canHandle]);

  const filtered = useMemo(
    () => tickets.filter((t) => (!status || t.status === status) && (!category || t.category === category)),
    [tickets, status, category],
  );

  if (currentUser && !canHandle) {
    return (
      <AppShell>
        <p className="p-6 text-sm text-slate-500">Bạn cần quyền xử lý IT ticket (IT_TICKET_HANDLE) để vào trang này.</p>
      </AppShell>
    );
  }

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-5xl mx-auto">
        <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
          <History className="h-5 w-5 text-teal-600" /> Đã xử lý
        </h1>
        <div className="flex flex-wrap gap-2 mb-4">
          <select value={status} onChange={(e) => setStatus(e.target.value)}
            className="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-white text-slate-700" aria-label="Lọc trạng thái">
            <option value="">Hoàn thành + Đã hủy</option>
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
                reporterName={nameOf(t.reporterId)}
                handlerName={t.assigneeId ? nameOf(t.assigneeId) : undefined}
                onOpen={() => setSelected(t)}
                footer={t.status === 'DONE' && t.resolveNote ? (
                  <span className="text-xs text-emerald-800 bg-emerald-50 border border-emerald-100 rounded-xl px-3 py-2 line-clamp-2">✓ {t.resolveNote}</span>
                ) : undefined} />
            ))}
          </div>}
        {selected && <TicketDetailModal ticket={selected} onClose={() => setSelected(null)} />}
      </div>
    </AppShell>
  );
}
