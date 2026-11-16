'use client';

import React from 'react';
import { ItTicket } from '@/types';
import { formatDateVN } from '@/utils/format';
import { ticketService } from '@/services/ticketService';
import { itCategoryLabel, itPriorityLabel, itStatusLabel } from './labels';
import { X } from 'lucide-react';

// ponytail: 1 modal dùng chung cho /tickets và /tickets/manage — table cắt gọn, chi tiết xem ở đây
export function TicketDetailModal({ ticket, onClose }: { ticket: ItTicket; onClose: () => void }) {
  const img = ticketService.resolveImage(ticket.imageUrl);
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-slate-900/60" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white/95 backdrop-blur px-5 py-4 border-b border-slate-100 flex items-start justify-between gap-3">
          <h2 className="font-bold text-slate-800 text-base leading-snug">{ticket.deviceInfo}</h2>
          <button onClick={onClose} className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg cursor-pointer" aria-label="Đóng">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="p-5 space-y-4">
          {img && (
            <div>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={img} alt="Ảnh hiện trạng thiết bị" className="w-full rounded-xl border border-slate-200 object-contain max-h-72" />
              <p className="text-xs text-slate-400 mt-1">Ảnh hiện trạng thiết bị</p>
            </div>
          )}
          <div className="flex flex-wrap gap-2">
            <span className="text-xs font-medium bg-slate-100 text-slate-700 px-2.5 py-1 rounded-lg">{itCategoryLabel(ticket.category)}</span>
            <span className={`text-xs font-medium px-2.5 py-1 rounded-lg ${ticket.priority === 'HIGH' ? 'bg-rose-100 text-rose-700' : 'bg-slate-100 text-slate-600'}`}>
              {ticket.priority === 'HIGH' ? 'Gấp' : 'Thường'}
            </span>
            <span className="text-xs font-medium bg-teal-50 text-teal-700 px-2.5 py-1 rounded-lg">{itStatusLabel(ticket.status)}</span>
          </div>
          <div>
            <p className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-1">Mô tả</p>
            <p className="text-sm text-slate-700 whitespace-pre-wrap bg-slate-50 border border-slate-100 rounded-xl p-3">{ticket.description}</p>
          </div>
          {ticket.location && (
            <InfoRow label="Vị trí" value={ticket.location} />
          )}
          <div className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
            <InfoRow label="Ngày gửi" value={formatDateVN(ticket.createdAt)} />
            {ticket.resolvedAt && <InfoRow label="Hoàn thành" value={formatDateVN(ticket.resolvedAt)} />}
          </div>
          {ticket.resolveNote && (
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-1">Ghi chú xử lý</p>
              <p className="text-sm text-slate-700 whitespace-pre-wrap bg-emerald-50 border border-emerald-100 rounded-xl p-3">{ticket.resolveNote}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-slate-400">{label}</p>
      <p className="font-medium text-slate-800 text-sm">{value}</p>
    </div>
  );
}

export { itCategoryLabel, itPriorityLabel, itStatusLabel };
