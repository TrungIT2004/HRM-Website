'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { 
  Users, 
  Search, 
  Filter, 
  Building2, 
  Mail, 
  Phone, 
  ArrowUpRight, 
  LayoutGrid, 
  Table as TableIcon,
  ShieldCheck,
  CheckCircle2,
  Clock,
  UserCheck
} from 'lucide-react';
import { DepartmentName, TodayAttendanceStatus } from '@/types';

export default function EmployeeDirectoryPage() {
  const { allUsers, isHR, isExecutive } = useAuth();
  const { employeeDetails } = useHRMData();

  const [keyword, setKeyword] = useState('');
  const [selectedDept, setSelectedDept] = useState<string>('ALL');
  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');

  const departments = [
    'Executive Leadership',
    'Human Resources',
    'Information Technology',
    'Sales & Marketing',
    'Finance & Accounting',
    'Customer Support'
  ];

  const todayStatusBadge = (status?: TodayAttendanceStatus) => {
    switch (status) {
      case 'WORKING':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-bold text-emerald-700 border border-emerald-200">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span>Đang làm việc</span>
          </span>
        );
      case 'ON_LEAVE':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-0.5 text-[11px] font-bold text-amber-700 border border-amber-200">
            <span className="h-1.5 w-1.5 rounded-full bg-amber-500" />
            <span>Nghỉ phép</span>
          </span>
        );
      case 'ABSENT':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-2.5 py-0.5 text-[11px] font-bold text-red-700 border border-red-200">
            <span className="h-1.5 w-1.5 rounded-full bg-red-500" />
            <span>Vắng mặt</span>
          </span>
        );
      case 'NOT_CHECKED':
      default:
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-2.5 py-0.5 text-[11px] font-medium text-slate-600 border border-slate-200">
            <span className="h-1.5 w-1.5 rounded-full bg-slate-400" />
            <span>Chưa chấm công</span>
          </span>
        );
    }
  };

  const filteredUsers = allUsers.filter(user => {
    const matchKeyword = 
      user.fullName.toLowerCase().includes(keyword.toLowerCase()) ||
      user.employeeCode.toLowerCase().includes(keyword.toLowerCase()) ||
      user.email.toLowerCase().includes(keyword.toLowerCase()) ||
      user.job.toLowerCase().includes(keyword.toLowerCase());

    const matchDept = selectedDept === 'ALL' || user.department === selectedDept;
    const matchStatus = selectedStatus === 'ALL' || user.todayStatus === selectedStatus;

    return matchKeyword && matchDept && matchStatus;
  });

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full border border-blue-200 mb-2">
              <Users className="h-3.5 w-3.5" />
              <span>Cơ sở dữ liệu nhân sự ACT</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Danh Bạ Nhân Sự Công Ty
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Tra cứu hồ sơ công khai, trạng thái chấm công hiện tại và thông tin công tác của toàn thể nhân sự (DTO EmployeePublicProfile).
            </p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded-xl border transition cursor-pointer ${
                viewMode === 'grid' 
                  ? 'bg-blue-50 border-blue-200 text-blue-700 shadow-xs' 
                  : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
              }`}
              title="Chế độ Lưới"
            >
              <LayoutGrid className="h-4 w-4" />
            </button>
            <button
              onClick={() => setViewMode('table')}
              className={`p-2 rounded-xl border transition cursor-pointer ${
                viewMode === 'table' 
                  ? 'bg-blue-50 border-blue-200 text-blue-700 shadow-xs' 
                  : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
              }`}
              title="Chế độ Bảng"
            >
              <TableIcon className="h-4 w-4" />
            </button>
          </div>
        </div>

        {/* Filter & Search Bar - Matching Backend Employee DTO Filtering */}
        <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 bg-white p-3.5 rounded-2xl border border-slate-200 shadow-xs">
          <div className="relative sm:col-span-6">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <Search className="h-4 w-4 text-slate-400" />
            </div>
            <input
              type="text"
              value={keyword}
              onChange={e => setKeyword(e.target.value)}
              placeholder="Tìm theo tên, mã NV (EXEC001, IT002...), email hoặc chức vụ..."
              className="block w-full rounded-xl border border-slate-200 py-2 pl-9 pr-3 text-xs text-slate-900 placeholder:text-slate-400 focus:border-blue-600 focus:outline-hidden focus:ring-1 focus:ring-blue-600"
            />
          </div>

          <div className="sm:col-span-3">
            <select
              value={selectedDept}
              onChange={e => setSelectedDept(e.target.value)}
              className="block w-full rounded-xl border border-slate-200 py-2 px-3 text-xs text-slate-900 bg-white focus:border-blue-600 focus:outline-hidden focus:ring-1 focus:ring-blue-600"
            >
              <option value="ALL">Tất cả phòng ban ({allUsers.length})</option>
              {departments.map(dept => (
                <option key={dept} value={dept}>
                  {dept}
                </option>
              ))}
            </select>
          </div>

          <div className="sm:col-span-3">
            <select
              value={selectedStatus}
              onChange={e => setSelectedStatus(e.target.value)}
              className="block w-full rounded-xl border border-slate-200 py-2 px-3 text-xs text-slate-900 bg-white focus:border-blue-600 focus:outline-hidden focus:ring-1 focus:ring-blue-600"
            >
              <option value="ALL">Tất cả trạng thái hôm nay</option>
              <option value="WORKING">🟢 Đang làm việc (WORKING)</option>
              <option value="ON_LEAVE">🟡 Nghỉ phép (ON_LEAVE)</option>
              <option value="NOT_CHECKED">⚪ Chưa chấm công (NOT_CHECKED)</option>
              <option value="ABSENT">🔴 Vắng mặt (ABSENT)</option>
            </select>
          </div>
        </div>

        {/* Status Count Summary Chips */}
        <div className="flex flex-wrap items-center gap-2 text-xs">
          <span className="text-slate-400 text-[11px] font-medium">Thống kê nhanh hôm nay:</span>
          <span className="inline-flex items-center gap-1 bg-emerald-50 text-emerald-800 px-2.5 py-1 rounded-lg border border-emerald-200 font-semibold text-[11px]">
            <span className="h-2 w-2 rounded-full bg-emerald-500" />
            Đang làm việc: {allUsers.filter(u => u.todayStatus === 'WORKING').length}
          </span>
          <span className="inline-flex items-center gap-1 bg-amber-50 text-amber-800 px-2.5 py-1 rounded-lg border border-amber-200 font-semibold text-[11px]">
            <span className="h-2 w-2 rounded-full bg-amber-500" />
            Nghỉ phép: {allUsers.filter(u => u.todayStatus === 'ON_LEAVE').length}
          </span>
          <span className="inline-flex items-center gap-1 bg-slate-100 text-slate-700 px-2.5 py-1 rounded-lg border border-slate-200 font-semibold text-[11px]">
            <span className="h-2 w-2 rounded-full bg-slate-400" />
            Chưa chấm: {allUsers.filter(u => u.todayStatus === 'NOT_CHECKED').length}
          </span>
          <span className="inline-flex items-center gap-1 bg-red-50 text-red-800 px-2.5 py-1 rounded-lg border border-red-200 font-semibold text-[11px]">
            <span className="h-2 w-2 rounded-full bg-red-500" />
            Vắng mặt: {allUsers.filter(u => u.todayStatus === 'ABSENT').length}
          </span>
        </div>

        {/* Grid View */}
        {viewMode === 'grid' && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredUsers.map(user => {
              const detail = employeeDetails[user.userId];
              const isLead = user.department === 'Executive Leadership' || user.job.includes('Department Head');

              return (
                <div
                  key={user.userId}
                  className="rounded-2xl bg-white p-5 border border-slate-200/80 shadow-xs hover:shadow-md hover:border-blue-300 transition-all duration-200 flex flex-col justify-between group"
                >
                  <div>
                    {/* Header with Avatar, Name, Code & Today Status */}
                    <div className="flex items-start justify-between gap-3 mb-3">
                      <div className="flex items-center gap-3">
                        <div className={`flex h-11 w-11 items-center justify-center rounded-2xl font-black text-sm text-white shadow-sm ${
                          user.department === 'Executive Leadership' 
                            ? 'bg-purple-600 shadow-purple-500/20' 
                            : user.department === 'Human Resources'
                            ? 'bg-blue-600 shadow-blue-500/20'
                            : isLead
                            ? 'bg-amber-600 shadow-amber-500/20'
                            : 'bg-slate-700 shadow-slate-500/20'
                        }`}>
                          {user.lastName?.[0] || user.fullName?.[0]}
                        </div>
                        <div>
                          <h3 className="text-sm font-bold text-slate-900 group-hover:text-blue-600 transition">
                            {user.fullName}
                          </h3>
                          <span className="text-[11px] font-mono text-slate-400 font-medium">
                            {user.employeeCode}
                          </span>
                        </div>
                      </div>

                      <div className="flex flex-col items-end gap-1">
                        <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${
                          user.department === 'Executive Leadership'
                            ? 'bg-purple-50 text-purple-700 border-purple-200'
                            : user.department === 'Human Resources'
                            ? 'bg-blue-50 text-blue-700 border-blue-200'
                            : isLead
                            ? 'bg-amber-50 text-amber-700 border-amber-200'
                            : 'bg-slate-50 text-slate-600 border-slate-200'
                        }`}>
                          {user.department === 'Executive Leadership' ? 'BGĐ' : isLead ? 'Trưởng phòng' : 'Nhân viên'}
                        </span>
                        {todayStatusBadge(user.todayStatus)}
                      </div>
                    </div>

                    {/* DTO Public Profile Detailed Fields */}
                    <div className="space-y-1.5 text-xs text-slate-600 border-t border-slate-100 pt-3 mb-4">
                      <div className="flex items-center gap-2">
                        <Building2 className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                        <span className="truncate font-medium text-slate-700">{user.job}</span>
                      </div>
                      <div className="flex items-center gap-2 text-slate-500 text-[11px]">
                        <span className="pl-5.5">{user.department}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Mail className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                        <span className="truncate font-mono text-[11px] text-slate-600">{user.email}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Phone className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                        <span className="font-mono text-[11px] text-slate-600">{user.phoneNumber || detail?.profile?.phoneNumber || '0901234567'}</span>
                      </div>
                      <div className="flex items-center justify-between text-[11px] text-slate-500 pt-1 border-t border-slate-100/60">
                        <span className="flex items-center gap-1">
                          <UserCheck className="h-3 w-3 text-slate-400" />
                          {user.gender || 'Nam'} • {user.birthDate || '1990-01-01'}
                        </span>
                        <span className="flex items-center gap-1 font-mono">
                          <Clock className="h-3 w-3 text-slate-400" />
                          {user.shiftName || 'Ca Hành Chính'}
                        </span>
                      </div>
                    </div>
                  </div>

                  <Link
                    href={`/employees/${user.userId}`}
                    className="flex items-center justify-between rounded-xl bg-slate-50 hover:bg-blue-50 hover:text-blue-700 text-slate-700 p-2.5 text-xs font-bold transition border border-slate-200/60"
                  >
                    <span>Xem Hồ sơ chi tiết (5 Tab)</span>
                    <ArrowUpRight className="h-4 w-4" />
                  </Link>
                </div>
              );
            })}
          </div>
        )}

        {/* Table View */}
        {viewMode === 'table' && (
          <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="py-3.5 px-4">Nhân sự</th>
                    <th className="py-3.5 px-4">Mã NV</th>
                    <th className="py-3.5 px-4">Trạng thái hôm nay</th>
                    <th className="py-3.5 px-4">Chức vụ & Phòng ban</th>
                    <th className="py-3.5 px-4">Email & SĐT</th>
                    <th className="py-3.5 px-4">Giới tính & Ngày sinh</th>
                    <th className="py-3.5 px-4">Ca làm việc</th>
                    <th className="py-3.5 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {filteredUsers.map(user => {
                    const detail = employeeDetails[user.userId];
                    return (
                      <tr key={user.userId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2.5">
                            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-100 text-blue-700 font-bold text-xs">
                              {user.lastName?.[0] || user.fullName?.[0]}
                            </div>
                            <div>
                              <div className="font-bold text-slate-900">{user.fullName}</div>
                              <div className="text-[10px] text-slate-400">{user.department}</div>
                            </div>
                          </div>
                        </td>
                        <td className="py-3 px-4 font-mono font-bold text-slate-700">
                          {user.employeeCode}
                        </td>
                        <td className="py-3 px-4">
                          {todayStatusBadge(user.todayStatus)}
                        </td>
                        <td className="py-3 px-4">
                          <div className="font-medium text-slate-800">{user.job}</div>
                          <div className="text-[11px] text-slate-500">{user.department}</div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="font-mono text-[11px] text-slate-700">{user.email}</div>
                          <div className="font-mono text-[10px] text-slate-400">{user.phoneNumber || detail?.profile?.phoneNumber || '0901234567'}</div>
                        </td>
                        <td className="py-3 px-4 text-slate-600">
                          <div>{user.gender || 'Nam'}</div>
                          <div className="text-[10px] text-slate-400">{user.birthDate || '1990-01-01'}</div>
                        </td>
                        <td className="py-3 px-4">
                          <span className="text-[11px] bg-slate-100 text-slate-700 px-2 py-0.5 rounded-md font-medium">
                            {user.shiftName}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-right">
                          <Link
                            href={`/employees/${user.userId}`}
                            className="inline-flex items-center gap-1 text-xs font-bold text-blue-600 hover:text-blue-800"
                          >
                            <span>Chi tiết</span>
                            <ArrowUpRight className="h-3.5 w-3.5" />
                          </Link>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
