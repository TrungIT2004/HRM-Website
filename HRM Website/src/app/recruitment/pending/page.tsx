'use client';

import React, { useEffect, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { adminService, PendingUserItem } from '@/services/adminService';
import { UserPlus } from 'lucide-react';

export default function PendingUsersPage() {
  const [rows, setRows] = useState<PendingUserItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminService.getPendingUsers('PENDING')
      .then(res => setRows(res ?? []))
      .catch(() => setRows([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-6xl mx-auto">
        <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
          <UserPlus className="h-5 w-5 text-violet-600" /> Hồ sơ chờ duyệt
        </h1>
        <div className="bg-white border border-slate-200 rounded-2xl shadow-xs overflow-hidden">
          {loading ? <p className="text-sm text-slate-400 p-5">Đang tải…</p>
            : rows.length === 0 ? <p className="text-sm text-slate-400 p-5 text-center">Không có hồ sơ nào chờ duyệt.</p>
            : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm min-w-[720px]">
                  <thead>
                    <tr className="text-left text-xs text-slate-500 border-b border-slate-100">
                      <th className="px-4 py-2.5 font-semibold">HỌ TÊN</th>
                      <th className="px-4 py-2.5 font-semibold">EMAIL CÁ NHÂN</th>
                      <th className="px-4 py-2.5 font-semibold">PHÒNG BAN</th>
                      <th className="px-4 py-2.5 font-semibold">CHỨC DANH</th>
                      <th className="px-4 py-2.5 font-semibold">NGƯỜI TẠO</th>
                      <th className="px-4 py-2.5 font-semibold">NGÀY TẠO</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map(r => (
                      <tr key={r.pendingId} className="border-b border-slate-50 hover:bg-slate-50 transition">
                        <td className="px-4 py-2.5 font-medium">{r.fullName || `${r.firstName} ${r.lastName}`}</td>
                        <td className="px-4 py-2.5 text-slate-600">{r.personalEmail}</td>
                        <td className="px-4 py-2.5 text-slate-600">{r.departmentName}</td>
                        <td className="px-4 py-2.5 text-slate-600">{r.jobTitle}</td>
                        <td className="px-4 py-2.5 text-slate-600">{r.createdByName ?? '—'}</td>
                        <td className="px-4 py-2.5 text-slate-600">{r.createdAt ? new Date(r.createdAt).toLocaleDateString('vi-VN') : '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          <p className="text-xs text-slate-400 px-4 py-3">Tổng {rows.length} hồ sơ chờ duyệt — duyệt/từ chối ở trang Duyệt cấp tài khoản.</p>
        </div>
      </div>
    </AppShell>
  );
}
