'use client';

import React, { useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { isHoliday } from '@/mock/holidays';
import { OvertimeRecord, OvertimeStatus } from '@/types';
import {
  Briefcase,
  Plus,
  CheckCircle2,
  XCircle,
  Clock,
  AlertCircle,
  FileSpreadsheet,
  Trash2,
  Sparkles,
  Building2,
  Calendar,
  X,
  Send,
  Moon,
  Filter,
  Search,
  RotateCcw,
  Phone,
  Mail
} from 'lucide-react';

export default function OvertimePage() {
  const { currentUser, isHR, isManager, isExecutive } = useAuth();
  const { overtimeRecords, submitOvertimeRequest, handleOvertimeRequest, cancelOvertimeRequest } = useHRMData();

  const [activeTab, setActiveTab] = useState<'my' | 'approvals' | 'company'>('my');
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  // OT Request form states
  const [otDate, setOtDate] = useState('2026-09-08');
  const [startTime, setStartTime] = useState('18:30');
  const [endTime, setEndTime] = useState('21:30');
  const [reason, setReason] = useState('');

  // Filter states matching OvertimeFilterRequest (status, fromDate, toDate, keyword)
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [filterFromDate, setFilterFromDate] = useState<string>('');
  const [filterToDate, setFilterToDate] = useState<string>('');
  const [filterKeyword, setFilterKeyword] = useState<string>('');
  const [filterDept, setFilterDept] = useState<string>('ALL');

  // Rejection modal
  const [rejectingOT, setRejectingOT] = useState<OvertimeRecord | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  const [toastMsg, setToastMsg] = useState('');

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };

  const handleResetFilters = () => {
    setFilterStatus('ALL');
    setFilterFromDate('');
    setFilterToDate('');
    setFilterKeyword('');
    setFilterDept('ALL');
  };

  // Reset tab if role switches and tab is no longer permitted
  React.useEffect(() => {
    if (!isHR && activeTab === 'company') {
      setActiveTab('my');
    }
    if (!isManager && !isExecutive && activeTab === 'approvals') {
      setActiveTab('my');
    }
  }, [isHR, isManager, isExecutive, activeTab]);

  // Helper calculating multiplier based on date & time
  const calculateMultiplier = (dateStr: string, sTime: string, eTime: string) => {
    const d = new Date(dateStr);
    const dayOfWeek = d.getDay();
    const holiday = isHoliday(dateStr);

    const isHoli = !!holiday;
    const isWknd = dayOfWeek === 0 || dayOfWeek === 6;
    const startHour = parseInt(sTime.split(':')[0] || '0', 10);
    const isNight = startHour >= 22 || startHour < 6;

    let mult = 1.5;
    if (isHoli) mult = 3.0;
    else if (isWknd) mult = 2.0;
    if (isNight) mult += 0.3;

    return { multiplier: mult, isHoliday: isHoli, isWeekend: isWknd, isNightTime: isNight };
  };

  const currentRate = calculateMultiplier(otDate, startTime, endTime);

  // Hours calculation
  const sH = parseInt(startTime.split(':')[0] || '0', 10) + parseInt(startTime.split(':')[1] || '0', 10) / 60;
  const eH = parseInt(endTime.split(':')[0] || '0', 10) + parseInt(endTime.split(':')[1] || '0', 10) / 60;
  const totalHours = Math.max(0, Number((eH - sH).toFixed(1)));

  // Helper applying OvertimeFilterRequest
  const applyOTFilter = (records: OvertimeRecord[], allowDept: boolean = false) => {
    return records.filter(o => {
      const matchStatus = filterStatus === 'ALL' || o.status === filterStatus;
      const matchFrom = !filterFromDate || o.approvedDate >= filterFromDate;
      const matchTo = !filterToDate || o.approvedDate <= filterToDate;
      const matchKeyword = !filterKeyword ||
        o.requestorName.toLowerCase().includes(filterKeyword.toLowerCase()) ||
        o.requestorCode.toLowerCase().includes(filterKeyword.toLowerCase()) ||
        o.reason.toLowerCase().includes(filterKeyword.toLowerCase());
      const matchDept = !allowDept || filterDept === 'ALL' || o.requestorDepartment === filterDept;

      return matchStatus && matchFrom && matchTo && matchKeyword && matchDept;
    });
  };

  // Phân quyền theo chuẩn Spring Boot OvertimeService & OvertimeSpecification:
  // 1. Đơn của tôi: Chỉ xem đơn của chính mình
  const rawMyOTs = overtimeRecords.filter(o => o.requestorId === currentUser?.userId);
  const myOTs = applyOTFilter(rawMyOTs);

  // 2. Hộp thư Duyệt OT (approvals):
  const rawApprovalOTs = overtimeRecords.filter(o => {
    if (!currentUser) return false;
    if (o.requestorId === currentUser.userId) return false; // Không tự duyệt đơn của mình

    if (isExecutive) {
      if (currentUser.job.includes('Chairman')) {
        return o.requestorDepartment === 'Executive Leadership' && (o.requestorJob.includes('Director') || o.requestorJob.includes('Deputy'));
      }
      if (currentUser.job.includes('Director') && !currentUser.job.includes('Deputy')) {
        return (o.requestorDepartment === 'Executive Leadership' && o.requestorJob.includes('Deputy')) || o.requestorJob.startsWith('Department Head');
      }
      if (currentUser.job.includes('Deputy')) {
        return o.requestorJob.startsWith('Department Head');
      }
      return o.status === 'pending';
    }

    if (isManager) {
      return o.requestorDepartment === currentUser.department && !o.requestorJob.startsWith('Department Head') && o.status === 'pending';
    }

    return false;
  });
  const approvalOTs = applyOTFilter(rawApprovalOTs);

  // 3. Toàn công ty (company):
  const rawCompanyOTs = isHR ? overtimeRecords : [];
  const companyOTs = applyOTFilter(rawCompanyOTs, true);

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser) return;

    if (totalHours <= 0) {
      showToast('Thời gian tăng ca kết thúc phải lớn hơn thời gian bắt đầu!');
      return;
    }

    submitOvertimeRequest({
      requestorId: currentUser.userId,
      requestorName: currentUser.fullName,
      requestorCode: currentUser.employeeCode,
      requestorDepartment: currentUser.department,
      requestorJob: currentUser.job,
      approvedDate: otDate,
      approvedStartTime: startTime,
      approvedEndTime: endTime,
      registeredHours: totalHours,
      reason: reason || 'Hoàn thành tiến độ dự án',
      isHoliday: currentRate.isHoliday,
      isWeekend: currentRate.isWeekend,
      isNightTime: currentRate.isNightTime,
      multiplier: currentRate.multiplier
    });

    setIsCreateModalOpen(false);
    setReason('');
    showToast('Đã nộp đơn đăng ký làm thêm giờ thành công!');
  };

  const handleApprove = (ot: OvertimeRecord) => {
    handleOvertimeRequest(ot.overtimeRecordId, 'accepted');
    showToast(`Đã duyệt đơn làm thêm giờ cho ${ot.requestorName}`);
  };

  const handleRejectSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!rejectingOT) return;
    handleOvertimeRequest(rejectingOT.overtimeRecordId, 'rejected', rejectionReason || 'Không có nhu cầu tăng ca');
    setRejectingOT(null);
    setRejectionReason('');
    showToast(`Đã từ chối đơn làm thêm giờ của ${rejectingOT.requestorName}`);
  };

  const handleExportExcel = () => {
    showToast('Đã xuất file báo cáo OT: ACT_Bao_Cao_OT_Thang_9.xlsx thành công!');
  };

  const statusBadge = (status: OvertimeStatus) => {
    switch (status) {
      case 'accepted':
        return <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 text-emerald-800 px-2.5 py-0.5 text-[11px] font-bold">Đã duyệt</span>;
      case 'pending':
        return <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 text-amber-800 px-2.5 py-0.5 text-[11px] font-bold">Chờ duyệt</span>;
      case 'rejected':
        return <span className="inline-flex items-center gap-1 rounded-full bg-red-100 text-red-800 px-2.5 py-0.5 text-[11px] font-bold">Từ chối</span>;
    }
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Toast */}
        {toastMsg && (
          <div className="fixed top-20 right-6 z-50 rounded-2xl bg-slate-900 text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold animate-in slide-in-from-top-4">
            <CheckCircle2 className="h-5 w-5 text-emerald-400" />
            <span>{toastMsg}</span>
          </div>
        )}

        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-orange-600 bg-orange-50 px-2.5 py-1 rounded-full border border-orange-200 mb-2">
              <Briefcase className="h-3.5 w-3.5" />
              <span>Phân hệ Làm Thêm Giờ (Spring Boot /api/overtime)</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Quản Lý Làm Thêm Giờ (OT)
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Hệ số đa tầng theo luật lao động: 1.5x ngày thường, 2.0x cuối tuần, 3.0x ngày lễ và phụ cấp ca đêm.
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              onClick={() => setIsCreateModalOpen(true)}
              className="inline-flex items-center gap-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-orange-500/20 transition cursor-pointer"
            >
              <Plus className="h-4 w-4" />
              <span>Đăng ký tăng ca mới</span>
            </button>
            {isHR && (
              <button
                onClick={handleExportExcel}
                className="flex items-center gap-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-emerald-500/20 transition cursor-pointer"
              >
                <FileSpreadsheet className="h-4 w-4" />
                <span>Xuất Excel</span>
              </button>
            )}
          </div>
        </div>

        {/* Multiplier Info Card */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
          <div className="p-3.5 rounded-2xl bg-white border border-slate-200 shadow-xs">
            <span className="text-slate-400 block font-medium">OT Ngày thường</span>
            <span className="mt-1 text-xl font-black text-blue-600 block">150% (1.5x)</span>
            <span className="text-[10px] text-slate-500">Sau giờ hành chính</span>
          </div>
          <div className="p-3.5 rounded-2xl bg-white border border-slate-200 shadow-xs">
            <span className="text-slate-400 block font-medium">OT Cuối tuần</span>
            <span className="mt-1 text-xl font-black text-indigo-600 block">200% (2.0x)</span>
            <span className="text-[10px] text-slate-500">Thứ 7 & Chủ Nhật</span>
          </div>
          <div className="p-3.5 rounded-2xl bg-white border border-slate-200 shadow-xs">
            <span className="text-slate-400 block font-medium">OT Ngày lễ tết</span>
            <span className="mt-1 text-xl font-black text-orange-600 block">300% (3.0x)</span>
            <span className="text-[10px] text-slate-500">Theo lịch nghỉ quốc gia</span>
          </div>
          <div className="p-3.5 rounded-2xl bg-white border border-slate-200 shadow-xs">
            <span className="text-slate-400 block font-medium">Phụ cấp ca đêm</span>
            <span className="mt-1 text-xl font-black text-purple-600 block">+30% Lương</span>
            <span className="text-[10px] text-slate-500">Từ 22:00 đến 06:00</span>
          </div>
        </div>

        {/* Tabs */}
        <div className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-xs font-bold">
          <button
            onClick={() => setActiveTab('my')}
            className={`px-4 py-2 rounded-xl transition cursor-pointer ${
              activeTab === 'my' ? 'bg-orange-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            Đơn tăng ca của tôi ({myOTs.length})
          </button>
          {(isManager || isExecutive) && (
            <button
              onClick={() => setActiveTab('approvals')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'approvals' ? 'bg-orange-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <span>Hộp thư Duyệt OT</span>
              {approvalOTs.length > 0 && (
                <span className="rounded-full bg-amber-500 text-white text-[10px] px-1.5 py-0.2 font-bold">
                  {approvalOTs.length}
                </span>
              )}
            </button>
          )}
          {isHR && (
            <button
              onClick={() => setActiveTab('company')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                activeTab === 'company' ? 'bg-orange-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              Toàn công ty ({companyOTs.length})
            </button>
          )}
        </div>

        {/* Unified Filter Toolbar matching OvertimeFilterRequest */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
              <Filter className="h-4 w-4 text-orange-600" />
              <span>Bộ lọc làm thêm giờ (DTO OvertimeFilterRequest: status, fromDate, toDate, keyword)</span>
            </div>
            {(filterStatus !== 'ALL' || filterFromDate || filterToDate || filterKeyword || filterDept !== 'ALL') && (
              <button
                onClick={handleResetFilters}
                className="text-xs text-slate-500 hover:text-orange-600 flex items-center gap-1 font-semibold cursor-pointer"
              >
                <RotateCcw className="h-3 w-3" />
                <span>Đặt lại bộ lọc</span>
              </button>
            )}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-3 text-xs">
            {/* Status */}
            <div>
              <label className="block text-[11px] font-bold text-slate-600 mb-1">Trạng thái (status)</label>
              <select
                value={filterStatus}
                onChange={e => setFilterStatus(e.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 bg-slate-50 font-medium text-slate-800 focus:bg-white focus:border-orange-500 transition"
              >
                <option value="ALL">Tất cả trạng thái</option>
                <option value="pending">Chờ phê duyệt (pending)</option>
                <option value="accepted">Đã phê duyệt (accepted)</option>
                <option value="rejected">Bị từ chối (rejected)</option>
              </select>
            </div>

            {/* fromDate */}
            <div>
              <label className="block text-[11px] font-bold text-slate-600 mb-1">Từ ngày (fromDate)</label>
              <input
                type="date"
                value={filterFromDate}
                onChange={e => setFilterFromDate(e.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 bg-slate-50 font-medium text-slate-800 focus:bg-white focus:border-orange-500 transition"
              />
            </div>

            {/* toDate */}
            <div>
              <label className="block text-[11px] font-bold text-slate-600 mb-1">Đến ngày (toDate)</label>
              <input
                type="date"
                value={filterToDate}
                onChange={e => setFilterToDate(e.target.value)}
                className="w-full rounded-xl border border-slate-200 px-3 py-2 bg-slate-50 font-medium text-slate-800 focus:bg-white focus:border-orange-500 transition"
              />
            </div>

            {/* Keyword */}
            <div>
              <label className="block text-[11px] font-bold text-slate-600 mb-1">Từ khóa (keyword)</label>
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-3.5 w-3.5 text-slate-400" />
                <input
                  type="text"
                  placeholder="Tên, mã NV, lý do..."
                  value={filterKeyword}
                  onChange={e => setFilterKeyword(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 pl-8 pr-3 py-2 bg-slate-50 font-medium text-slate-800 focus:bg-white focus:border-orange-500 transition"
                />
              </div>
            </div>

            {/* Department filter for HR company tab */}
            {activeTab === 'company' && isHR && (
              <div className="sm:col-span-2 md:col-span-4">
                <label className="block text-[11px] font-bold text-slate-600 mb-1">Lọc theo phòng ban</label>
                <select
                  value={filterDept}
                  onChange={e => setFilterDept(e.target.value)}
                  className="w-full sm:w-72 rounded-xl border border-slate-200 px-3 py-2 bg-slate-50 font-medium text-slate-800 focus:bg-white focus:border-orange-500 transition"
                >
                  <option value="ALL">Tất cả phòng ban</option>
                  <option value="Executive Leadership">Ban Giám Đốc (Executive Leadership)</option>
                  <option value="Human Resources">Phòng Nhân Sự (Human Resources)</option>
                  <option value="Information Technology">Phòng Công Nghệ (Information Technology)</option>
                  <option value="Sales & Marketing">Phòng Sales & Marketing</option>
                  <option value="Finance & Accounting">Phòng Tài Chính - Kế Toán</option>
                  <option value="Operations">Phòng Vận Hành (Operations)</option>
                </select>
              </div>
            )}
          </div>
        </div>

        {/* Tab 1: My OTs (StaffOvertimeResponse) */}
        {activeTab === 'my' && (
          <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between">
              <div>
                <h3 className="text-xs font-bold text-slate-800">Lịch sử làm thêm giờ của tôi (DTO StaffOvertimeResponse)</h3>
                <p className="text-[11px] text-slate-400">Hiển thị chi tiết giờ đăng ký, giờ thực tế, hệ số và người duyệt</p>
              </div>
              <span className="text-xs font-semibold text-slate-500">{myOTs.length} đơn</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Ngày tăng ca</th>
                    <th className="py-3 px-4">Khung giờ đăng ký</th>
                    <th className="py-3 px-4">Giờ quẹt thẻ</th>
                    <th className="py-3 px-4">Số giờ (ĐK / TT)</th>
                    <th className="py-3 px-4">Hệ số & Chế độ</th>
                    <th className="py-3 px-4">Người duyệt</th>
                    <th className="py-3 px-4">Lý do & Phản hồi</th>
                    <th className="py-3 px-4">Trạng thái</th>
                    <th className="py-3 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {myOTs.length === 0 ? (
                    <tr>
                      <td colSpan={9} className="py-8 text-center text-slate-400">
                        Không có đơn làm thêm giờ nào phù hợp với bộ lọc.
                      </td>
                    </tr>
                  ) : (
                    myOTs.map(ot => (
                      <tr key={ot.overtimeRecordId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4 font-mono font-bold text-slate-900 whitespace-nowrap">
                          {ot.approvedDate}
                        </td>
                        <td className="py-3 px-4 font-mono text-slate-800 whitespace-nowrap">
                          {ot.approvedStartTime} → {ot.approvedEndTime}
                        </td>
                        <td className="py-3 px-4 font-mono whitespace-nowrap">
                          {ot.clockInTime ? (
                            <span className="text-emerald-700 font-semibold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                              {ot.clockInTime} - {ot.clockOutTime || 'Chưa ra'}
                            </span>
                          ) : (
                            <span className="text-slate-400 italic">Chưa điểm danh</span>
                          )}
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <span className="font-bold text-orange-600">{ot.registeredHours}h</span>
                          {ot.totalActualHours ? (
                            <span className="text-slate-500 text-[11px] ml-1">({ot.totalActualHours}h TT)</span>
                          ) : null}
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="flex items-center gap-1.5 flex-wrap">
                            <span className="font-bold text-slate-900 bg-slate-100 px-2 py-0.5 rounded font-mono">
                              {ot.multiplier}x
                            </span>
                            {ot.isHoliday && (
                              <span className="rounded bg-orange-100 text-orange-800 text-[10px] px-1.5 py-0.5 font-bold">Ngày Lễ</span>
                            )}
                            {ot.isWeekend && (
                              <span className="rounded bg-indigo-100 text-indigo-800 text-[10px] px-1.5 py-0.5 font-bold">Cuối tuần</span>
                            )}
                            {ot.isNightTime && (
                              <span className="rounded bg-purple-100 text-purple-800 text-[10px] px-1.5 py-0.5 font-bold flex items-center gap-0.5">
                                <Moon className="h-2.5 w-2.5" /> Đêm
                              </span>
                            )}
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          {ot.approverName ? (
                            <div>
                              <div className="font-semibold text-slate-900">{ot.approverName}</div>
                              {ot.approverJob && <div className="text-[10px] text-slate-400">{ot.approverJob}</div>}
                            </div>
                          ) : (
                            <span className="text-slate-400">—</span>
                          )}
                        </td>
                        <td className="py-3 px-4 max-w-xs">
                          <div className="text-slate-700 truncate" title={ot.reason}>{ot.reason}</div>
                          {ot.rejectionReason && (
                            <div className="text-[11px] text-red-600 font-semibold mt-0.5 bg-red-50 p-1 rounded">
                              Từ chối: {ot.rejectionReason}
                            </div>
                          )}
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          {statusBadge(ot.status)}
                        </td>
                        <td className="py-3 px-4 text-right whitespace-nowrap">
                          {ot.status === 'pending' ? (
                            <button
                              onClick={() => cancelOvertimeRequest(ot.overtimeRecordId)}
                              className="text-red-600 hover:text-red-800 font-bold text-xs cursor-pointer"
                            >
                              Hủy đơn
                            </button>
                          ) : (
                            <span className="text-slate-400">—</span>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Tab 2: Approvals (ManagerOvertimeResponse) */}
        {activeTab === 'approvals' && (isManager || isExecutive) && (
          <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between">
              <div>
                <h3 className="text-xs font-bold text-slate-800">Hộp thư Duyệt làm thêm giờ (DTO ManagerOvertimeResponse)</h3>
                <p className="text-[11px] text-slate-400">Phê duyệt tăng ca theo cấp quản lý phòng ban / Ban Giám Đốc</p>
              </div>
              <span className="text-xs text-amber-700 font-semibold">{approvalOTs.length} đơn chờ xử lý</span>
            </div>

            {approvalOTs.length === 0 ? (
              <div className="p-8 text-center text-xs text-slate-500">
                Hiện tại không có đơn làm thêm giờ nào phù hợp với bộ lọc.
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3 px-4">Nhân sự</th>
                      <th className="py-3 px-4">Phòng ban & Vị trí</th>
                      <th className="py-3 px-4">Ngày & Khung giờ</th>
                      <th className="py-3 px-4">Giờ quẹt thẻ</th>
                      <th className="py-3 px-4">Số giờ</th>
                      <th className="py-3 px-4">Hệ số</th>
                      <th className="py-3 px-4">Lý do tăng ca</th>
                      <th className="py-3 px-4 text-right">Hành động</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {approvalOTs.map(ot => (
                      <tr key={ot.overtimeRecordId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="font-bold text-slate-900">{ot.requestorName}</div>
                          <div className="text-[10px] text-slate-400 font-mono">{ot.requestorCode}</div>
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="font-medium text-slate-800">{ot.requestorDepartment}</div>
                          <div className="text-[10px] text-slate-400">{ot.requestorJob}</div>
                        </td>
                        <td className="py-3 px-4 font-mono whitespace-nowrap">
                          <div className="font-bold text-slate-900">{ot.approvedDate}</div>
                          <div className="text-[11px] text-slate-500">{ot.approvedStartTime} - {ot.approvedEndTime}</div>
                        </td>
                        <td className="py-3 px-4 font-mono whitespace-nowrap">
                          {ot.clockInTime ? (
                            <span className="text-emerald-700 font-semibold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                              {ot.clockInTime} - {ot.clockOutTime || 'Chưa ra'}
                            </span>
                          ) : (
                            <span className="text-slate-400 italic">Chưa điểm danh</span>
                          )}
                        </td>
                        <td className="py-3 px-4 font-bold text-orange-600 whitespace-nowrap">
                          {ot.registeredHours}h
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="flex items-center gap-1">
                            <span className="font-bold text-slate-900 bg-slate-100 px-2 py-0.5 rounded font-mono">
                              {ot.multiplier}x
                            </span>
                            {ot.isHoliday && <span className="rounded bg-orange-100 text-orange-800 text-[10px] px-1 font-bold">Lễ</span>}
                            {ot.isWeekend && <span className="rounded bg-indigo-100 text-indigo-800 text-[10px] px-1 font-bold">T7/CN</span>}
                            {ot.isNightTime && <Moon className="h-3 w-3 text-purple-600" />}
                          </div>
                        </td>
                        <td className="py-3 px-4 text-slate-600 max-w-xs">{ot.reason}</td>
                        <td className="py-3 px-4 text-right whitespace-nowrap">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => handleApprove(ot)}
                              className="rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 text-xs font-bold transition cursor-pointer"
                            >
                              Duyệt OT
                            </button>
                            <button
                              onClick={() => {
                                setRejectingOT(ot);
                                setRejectionReason('');
                              }}
                              className="rounded-lg bg-red-50 hover:bg-red-100 text-red-700 px-3 py-1.5 text-xs font-bold transition cursor-pointer"
                            >
                              Từ chối
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* Tab 3: Company All (HrOvertimeResponse) */}
        {activeTab === 'company' && isHR && (
          <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between">
              <div>
                <h3 className="text-xs font-bold text-slate-800">Báo cáo làm thêm giờ toàn công ty (DTO HrOvertimeResponse)</h3>
                <p className="text-[11px] text-slate-400">Đầy đủ thông tin liên lạc, giờ phê duyệt tổng, giờ thực tế, người phê duyệt</p>
              </div>
              <span className="text-xs font-semibold text-slate-500">{companyOTs.length} bản ghi</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Nhân sự</th>
                    <th className="py-3 px-4">Liên hệ (Email / SĐT)</th>
                    <th className="py-3 px-4">Phòng ban & Vị trí</th>
                    <th className="py-3 px-4">Ngày & Khung giờ</th>
                    <th className="py-3 px-4">Quẹt thẻ thực tế</th>
                    <th className="py-3 px-4">Giờ duyệt / Thực tế</th>
                    <th className="py-3 px-4">Hệ số</th>
                    <th className="py-3 px-4">Người duyệt</th>
                    <th className="py-3 px-4">Lý do & Ghi chú</th>
                    <th className="py-3 px-4">Trạng thái</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {companyOTs.length === 0 ? (
                    <tr>
                      <td colSpan={10} className="py-8 text-center text-slate-400">
                        Không có dữ liệu tăng ca nào phù hợp với bộ lọc.
                      </td>
                    </tr>
                  ) : (
                    companyOTs.map(ot => (
                      <tr key={ot.overtimeRecordId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="font-bold text-slate-900">{ot.requestorName}</div>
                          <div className="text-[10px] text-slate-400 font-mono">{ot.requestorCode}</div>
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="flex items-center gap-1 text-[11px] text-slate-700">
                            <Mail className="h-3 w-3 text-slate-400" />
                            <span>{ot.requestorEmail || `${ot.requestorCode.toLowerCase()}@act.com`}</span>
                          </div>
                          <div className="flex items-center gap-1 text-[10px] text-slate-500 font-mono mt-0.5">
                            <Phone className="h-3 w-3 text-slate-400" />
                            <span>{ot.requestorPhoneNumber || '0901234567'}</span>
                          </div>
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="font-medium text-slate-800">{ot.requestorDepartment}</div>
                          <div className="text-[10px] text-slate-400">{ot.requestorJob}</div>
                        </td>
                        <td className="py-3 px-4 font-mono whitespace-nowrap">
                          <div className="font-semibold text-slate-900">{ot.approvedDate}</div>
                          <div className="text-[10px] text-slate-500">{ot.approvedStartTime} - {ot.approvedEndTime}</div>
                        </td>
                        <td className="py-3 px-4 font-mono whitespace-nowrap">
                          {ot.clockInTime ? (
                            <span className="text-emerald-700 font-semibold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                              {ot.clockInTime} - {ot.clockOutTime || 'Chưa ra'}
                            </span>
                          ) : (
                            <span className="text-slate-400 italic">Chưa điểm danh</span>
                          )}
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="font-bold text-orange-600">{ot.totalApprovedHours ?? ot.registeredHours}h duyệt</div>
                          <div className="text-[10px] text-slate-500">{ot.totalActualHours ?? ot.actualHours ?? 0}h thực tế</div>
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="flex items-center gap-1">
                            <span className="font-bold text-slate-900 bg-slate-100 px-2 py-0.5 rounded font-mono">
                              {ot.multiplier}x
                            </span>
                            {ot.isNightTime && <Moon className="h-3 w-3 text-purple-600" />}
                          </div>
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">
                          <div className="font-medium text-slate-800">{ot.approverName || '—'}</div>
                          {ot.approverJob && <div className="text-[10px] text-slate-400">{ot.approverJob}</div>}
                        </td>
                        <td className="py-3 px-4 max-w-xs">
                          <div className="text-slate-700 truncate" title={ot.reason}>{ot.reason}</div>
                          {ot.rejectionReason && (
                            <div className="text-[11px] text-red-600 font-semibold mt-0.5">
                              Lý do từ chối: {ot.rejectionReason}
                            </div>
                          )}
                        </td>
                        <td className="py-3 px-4 whitespace-nowrap">{statusBadge(ot.status)}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Modal Đăng Ký Tăng Ca Mới */}
        {isCreateModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-xl rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2 text-orange-600 font-bold text-sm">
                  <Briefcase className="h-5 w-5" />
                  <span>Đăng Ký Làm Thêm Giờ (Spring Boot /api/overtime)</span>
                </div>
                <button
                  onClick={() => setIsCreateModalOpen(false)}
                  className="rounded-full p-1 text-slate-400 hover:bg-slate-100 transition"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <form onSubmit={handleCreateSubmit} className="mt-4 space-y-4 text-xs">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Ngày làm thêm giờ</label>
                  <input
                    type="date"
                    value={otDate}
                    onChange={e => setOtDate(e.target.value)}
                    required
                    className="w-full rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Giờ bắt đầu</label>
                    <input
                      type="time"
                      value={startTime}
                      onChange={e => setStartTime(e.target.value)}
                      required
                      className="w-full rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Giờ kết thúc</label>
                    <input
                      type="time"
                      value={endTime}
                      onChange={e => setEndTime(e.target.value)}
                      required
                      className="w-full rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                    />
                  </div>
                </div>

                {/* Rate preview calculation */}
                <div className="rounded-2xl bg-orange-50/80 p-4 border border-orange-200/80 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-orange-900">Xem trước hệ số lương áp dụng:</span>
                    <span className="font-black text-sm text-orange-700 bg-white px-2.5 py-0.5 rounded-lg border border-orange-200">
                      Hệ số {currentRate.multiplier}x
                    </span>
                  </div>
                  <div className="grid grid-cols-3 gap-2 text-[11px] pt-1">
                    <div className="bg-white p-2 rounded-lg border border-orange-100 text-center">
                      <span className="text-slate-400 block">Thời lượng:</span>
                      <span className="font-bold text-slate-900 text-xs">{totalHours} giờ</span>
                    </div>
                    <div className="bg-white p-2 rounded-lg border border-orange-100 text-center">
                      <span className="text-slate-400 block">Phân loại ngày:</span>
                      <span className="font-bold text-orange-700 text-xs">
                        {currentRate.isHoliday ? 'Ngày Lễ (3.0x)' : currentRate.isWeekend ? 'Cuối tuần (2.0x)' : 'Ngày thường (1.5x)'}
                      </span>
                    </div>
                    <div className="bg-white p-2 rounded-lg border border-orange-100 text-center">
                      <span className="text-slate-400 block">Phụ cấp ca đêm:</span>
                      <span className="font-bold text-purple-700 text-xs">{currentRate.isNightTime ? '+30%' : 'Không'}</span>
                    </div>
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Lý do tăng ca</label>
                  <textarea
                    rows={3}
                    value={reason}
                    onChange={e => setReason(e.target.value)}
                    required
                    placeholder="Mô tả công việc cần làm thêm giờ (ví dụ: hoàn thành dự án gấp, trực ca kỹ thuật...)"
                    className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
                  />
                </div>

                <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2.5">
                  <button
                    type="button"
                    onClick={() => setIsCreateModalOpen(false)}
                    className="rounded-xl px-4 py-2 font-bold text-slate-600 hover:bg-slate-100 transition"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    className="flex items-center gap-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white px-5 py-2 font-bold shadow-md shadow-orange-500/20 transition cursor-pointer"
                  >
                    <Send className="h-4 w-4" />
                    <span>Nộp đơn đăng ký</span>
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Modal Từ Chối OT */}
        {rejectingOT && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl border border-slate-200">
              <h3 className="text-sm font-bold text-red-600 flex items-center gap-2 mb-2">
                <XCircle className="h-5 w-5" />
                <span>Từ chối đơn làm thêm giờ</span>
              </h3>
              <p className="text-xs text-slate-600 mb-4">
                Nhân viên: <strong>{rejectingOT.requestorName}</strong> ({rejectingOT.approvedDate} lúc {rejectingOT.approvedStartTime} - {rejectingOT.approvedEndTime})
              </p>

              <form onSubmit={handleRejectSubmit} className="space-y-4 text-xs">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Lý do từ chối (Bắt buộc)</label>
                  <textarea
                    rows={3}
                    value={rejectionReason}
                    onChange={e => setRejectionReason(e.target.value)}
                    required
                    placeholder="Nhập lý do từ chối..."
                    className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
                  />
                </div>

                <div className="flex items-center justify-end gap-2.5 pt-2">
                  <button
                    type="button"
                    onClick={() => setRejectingOT(null)}
                    className="rounded-xl px-4 py-2 font-bold text-slate-600 hover:bg-slate-100 transition"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    className="rounded-xl bg-red-600 hover:bg-red-700 text-white px-5 py-2 font-bold transition cursor-pointer"
                  >
                    Xác nhận từ chối
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
