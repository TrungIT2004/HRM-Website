'use client';

import React from 'react';
import AppShell from '@/components/layout/AppShell';
import { formatDateVN } from '@/utils/format';
import { useManageAssets, ManageGate } from '../../manageAssets';
import { Bell, History } from 'lucide-react';

export default function AssetRemindersPage() {
  const { canEnter, urgent, due, userName, catName, assetLabel } = useManageAssets();
  const urgentPending = urgent.filter((r) => r.status === 'pending');

  return (
    <ManageGate canEnter={canEnter}>
      <AppShell>
        <div className="p-4 md:p-6 max-w-6xl mx-auto">
          <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
            <Bell className="h-5 w-5 text-teal-600" /> Nhắc việc
          </h1>
          <div className="grid gap-4 md:grid-cols-2">
            <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs">
              <h3 className="text-sm font-semibold text-slate-700 mb-2 flex items-center gap-1.5"><Bell className="h-4 w-4 text-amber-500" /> Đơn cần gấp (7 ngày)</h3>
              {urgentPending.map((r) => (
                <div key={r.requestId} className="text-xs py-1.5 border-b border-slate-50">{catName(r.categoryId)} — {userName(r.requestorId)} · cần trước {formatDateVN(r.neededByDate!)}</div>
              ))}
              {urgentPending.length === 0 && <p className="text-xs text-slate-400">Không có.</p>}
            </div>
            <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs">
              <h3 className="text-sm font-semibold text-slate-700 mb-2 flex items-center gap-1.5"><History className="h-4 w-4 text-blue-500" /> Sắp đến hạn trả (7 ngày)</h3>
              {due.map((a) => (
                <div key={a.assignmentId} className="text-xs py-1.5 border-b border-slate-50">{assetLabel(a.assetId)} — {a.scope === 'DEPARTMENT' ? 'Cả phòng ban' : userName(a.userId ?? undefined)} · hạn {formatDateVN(a.expectedReturnDate!)}</div>
              ))}
              {due.length === 0 && <p className="text-xs text-slate-400">Không có.</p>}
            </div>
          </div>
        </div>
      </AppShell>
    </ManageGate>
  );
}
