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
import { Hand, Inbox, CheckCircle2, XCircle } from 'lucide-react';

export default function TicketQueuesPage() {
  const { currentUser, can } = useAuth();
  const canHandle = can('IT_TICKET_HANDLE');
  const { nameOf } = useTicketDirectory();
  const [tickets, setTickets] = useState<ItTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [category, setCategory] = useState('');
  const [status, setStatus] = useState('OPEN');
  const [selected, setSelected] = useState<ItTicket | null>(null);
  const [resolveNote, setResolveNote] = useState('');
  const [resolving, setResolving] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try { setTickets(await ticketService.queue('QUEUE')); } catch { /* giữ trống */ } finally { setLoading(false); }
  };

  useEffect(() => { if (currentUser && canHandle) load(); }, [currentUser?.userId, canHandle]);

  // ponytail: mặc định chỉ hiện Chờ nhận (đơn người khác đã nhận thì qua tab Đang xử lý xem) — HIGH ghim lên đầu
  const filtered = useMemo(
    () => tickets
      .filter((t) => (!status || t.status === status) && (!category || t.category === category))
      .sort((a, b) => (b.priority === 'HIGH' ? 1 : 0) - (a.priority === 'HIGH' ? 1 : 0)
        || b.createdAt.localeCompare(a.createdAt)),
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
          <Inbox className="h-5 w-5 text-teal-600" /> Hàng chờ xử lý
        </h1>
        <div className="flex flex-wrap gap-2 mb-4">
          <select value={status} onChange={(e) => setStatus(e.target.value)}
            className="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-white text-slate-700" aria-label="Lọc trạng thái">
            <option value="OPEN">Chờ nhận</option>
            <option value="IN_PROGRESS">Đang xử lý</option>
            <option value="">Tất cả</option>
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
          filtered.length === 0 ? <p className="text-sm text-slate-400">Không có ticket nào.</p> :
          <div className="space-y-3">
            {filtered.map((t) => (
              <TicketCard key={t.ticketId} ticket={t}
                reporterName={nameOf(t.reporterId)}
                handlerName={t.assigneeId ? nameOf(t.assigneeId) : undefined}
                onOpen={() => setSelected(t)}
                footer={<>
                  {t.status === 'OPEN' && (
                    <button onClick={async () => { await ticketService.claim(t.ticketId); load(); }}
                      className="inline-flex items-center gap-1.5 text-xs font-semibold px-3.5 py-2 rounded-xl bg-teal-600 text-white hover:bg-teal-700 transition cursor-pointer">
                      <Hand className="h-3.5 w-3.5" /> Nhận ticket
                    </button>
                  )}
                  {t.status === 'IN_PROGRESS' && resolving !== t.ticketId && (
                    <button onClick={() => { setResolving(t.ticketId); setResolveNote(''); }}
                      className="inline-flex items-center gap-1.5 text-xs font-semibold px-3.5 py-2 rounded-xl bg-emerald-600 text-white hover:bg-emerald-700 transition cursor-pointer">
                      <CheckCircle2 className="h-3.5 w-3.5" /> Hoàn thành
                    </button>
                  )}
                  {(t.status === 'OPEN' || t.status === 'IN_PROGRESS') && (
                    <button onClick={async () => { await ticketService.cancel(t.ticketId); load(); }}
                      className="inline-flex items-center gap-1.5 text-xs font-semibold px-3.5 py-2 rounded-xl bg-white border border-slate-200 text-slate-500 hover:text-rose-600 hover:border-rose-200 transition cursor-pointer">
                      <XCircle className="h-3.5 w-3.5" /> Hủy
                    </button>
                  )}
                </>}>
              </TicketCard>
            ))}
            {filtered.map((t) => resolving === t.ticketId && (
              <div key={`resolve-${t.ticketId}`} className="-mt-1 bg-emerald-50/60 border border-emerald-100 rounded-2xl p-3 flex flex-col sm:flex-row gap-2">
                <input value={resolveNote} onChange={(e) => setResolveNote(e.target.value)}
                  placeholder="Ghi chú xử lý (VD: đã thay mực, in lại bình thường)"
                  className="flex-1 text-sm border border-slate-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500" />
                <button onClick={async () => { await ticketService.resolve(t.ticketId, resolveNote); setResolving(null); load(); }}
                  className="text-xs font-semibold px-4 py-2 rounded-xl bg-emerald-600 text-white cursor-pointer">Xong</button>
                <button onClick={() => setResolving(null)}
                  className="text-xs font-semibold px-4 py-2 rounded-xl bg-white border border-slate-200 text-slate-500 cursor-pointer">Bỏ</button>
              </div>
            ))}
          </div>}
        {selected && <TicketDetailModal ticket={selected} onClose={() => setSelected(null)} />}
      </div>
    </AppShell>
  );
}
