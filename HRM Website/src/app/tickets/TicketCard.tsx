'use client';

import React from 'react';
import { ItTicket } from '@/types';
import { formatDateVN } from '@/utils/format';
import { itCategoryColor, itCategoryLabel, itStatusLabel } from './labels';
import { CalendarDays, User, Wrench } from 'lucide-react';

const STATUS_PILL: Record<string, string> = {
  OPEN: 'bg-amber-100 text-amber-800',
  IN_PROGRESS: 'bg-blue-100 text-blue-800',
  DONE: 'bg-emerald-100 text-emerald-800',
  CANCELLED: 'bg-slate-200 text-slate-600',
};

// ponytail: 1 card dùng chung cho /tickets, /queues, /done — chữ slate-800/700 thay vì slate-400/500 mờ
export function TicketCard({
  ticket,
  reporterName,
  handlerName,
  onOpen,
  footer,
}: {
  ticket: ItTicket;
  reporterName?: string;
  handlerName?: string;
  onOpen: () => void;
  footer?: React.ReactNode;
}) {
  const urgent = ticket.priority === 'HIGH';
  return (
    <div className={`bg-white rounded-2xl border p-4 shadow-xs border-l-4 transition hover:shadow-md ${
      urgent ? 'border-slate-200 border-l-rose-500' : 'border-slate-200 border-l-teal-500'
    }`}>
      <div className="flex flex-wrap items-center gap-1.5 mb-2">
        <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-700 bg-slate-100 px-2.5 py-1 rounded-lg">
          <span className="h-2 w-2 rounded-full" style={{ background: itCategoryColor(ticket.category) }} />
          {itCategoryLabel(ticket.category)}
        </span>
        {urgent ? (
          <span className="text-xs font-bold text-white bg-rose-600 px-2.5 py-1 rounded-lg">GẤP</span>
        ) : (
          <span className="text-xs font-medium text-slate-500 bg-slate-50 border border-slate-200 px-2.5 py-1 rounded-lg">Thường</span>
        )}
        <span className={`text-xs font-semibold px-2.5 py-1 rounded-lg ${STATUS_PILL[ticket.status] ?? 'bg-slate-100 text-slate-600'}`}>
          {itStatusLabel(ticket.status)}
        </span>
        <span className="ml-auto inline-flex items-center gap-1 text-xs font-medium text-slate-500">
          <CalendarDays className="h-3.5 w-3.5" />{formatDateVN(ticket.createdAt)}
        </span>
      </div>
      <button onClick={onOpen} className="text-left w-full cursor-pointer group">
        <div className="font-semibold text-slate-900 text-[15px] leading-snug group-hover:text-teal-700 transition">
          {ticket.deviceInfo}
        </div>
        <div className="text-sm text-slate-600 mt-1 line-clamp-2 leading-relaxed">{ticket.description}</div>
      </button>
      {(reporterName || handlerName) && (
        <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-2.5 text-xs font-medium text-slate-600">
          {reporterName && (
            <span className="inline-flex items-center gap-1.5"><User className="h-3.5 w-3.5 text-slate-400" />{reporterName}</span>
          )}
          {handlerName && (
            <span className="inline-flex items-center gap-1.5 text-teal-700"><Wrench className="h-3.5 w-3.5" />{handlerName} đang xử lý</span>
          )}
        </div>
      )}
      {footer && <div className="flex flex-wrap items-center gap-2 mt-3 pt-3 border-t border-slate-100">{footer}</div>}
    </div>
  );
}
