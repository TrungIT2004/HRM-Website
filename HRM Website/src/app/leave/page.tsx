'use client';

import React, { useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { calculateLeavePreview } from '@/mock/leaves';
import { LeaveRequest, LeaveRequestStatus } from '@/types';
import {
  CalendarDays,
  Plus,
  CheckCircle2,
  XCircle,
  Clock,
  AlertCircle,
  Calendar,
  Sparkles,
  Search,
  Filter,
  Trash2,
  FileCheck,
  Building2,
  User,
  X,
  Send
} from 'lucide-react';

export default function LeavePage() {
  const { currentUser, isHR, isManager, isExecutive } = useAuth();
  const { leaveRequests, submitLeaveRequest, handleLeaveRequest, cancelLeaveRequest } = useHRMData();

  const [activeTab, setActiveTab] = useState<'my' | 'approvals' | 'company'>('my');
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  // Form states for creating leave request
  const [fromDate, setFromDate] = useState('2026-09-15');
  const [toDate, setToDate] = useState('2026-09-16');
  const [reason, setReason] = useState('');

  // Filter states matching LeaveFilterRequest (status, fromDate, toDate, keyword)
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [filterFromDate, setFilterFromDate] = useState<string>('');
  const [filterToDate, setFilterToDate] = useState<string>('');
  const [filterKeyword, setFilterKeyword] = useState<string>('');
  const [filterDept, setFilterDept] = useState<string>('ALL');

  // Rejection modal
  const [rejectingReq, setRejectingReq] = useState<LeaveRequest | null>(null);
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

  // Live calculation preview
  const preview = currentUser ? calculateLeavePreview(currentUser, fromDate, toDate) : null;
  const isChairman = currentUser?.job === 'Chairman';

  // Helper applying LeaveFilterRequest
  const applyLeaveFilter = (requests: LeaveRequest[], allowDept: boolean = false) => {
    return requests.filter(r => {
      const matchStatus = filterStatus === 'ALL' || r.status === filterStatus;
      const matchFrom = !filterFromDate || r.toDate >= filterFromDate;
      const matchTo = !filterToDate || r.fromDate <= filterToDate;
      const matchKeyword = !filterKeyword ||
        r.requestorName.toLowerCase().includes(filterKeyword.toLowerCase()) ||
        r.requestorCode.toLowerCase().includes(filterKeyword.toLowerCase()) ||
        r.reason.toLowerCase().includes(filterKeyword.toLowerCase());
      const matchDept = !allowDept || filterDept === 'ALL' || r.requestorDepartment === filterDept;

      return matchStatus && matchFrom && matchTo && matchKeyword && matchDept;
    });
  };

  // Phân quyền theo chuẩn Spring Boot LeaveService & LeaveRequestSpecification:
  // 1. Đơn của tôi: Ai cũng xem được đơn của chính mình
  const rawMyRequests = leaveRequests.filter(r => r.requestorId === currentUser?.userId);
  const myRequests = applyLeaveFilter(rawMyRequests);

  // 2. Hộp thư Duyệt đơn (approvals):
  const rawApprovalRequests = leaveRequests.filter(r => {
    if (!currentUser) return false;
    if (r.requestorId === currentUser.userId) return false; // Không tự duyệt đơn của mình

    if (isExecutive) {
      if (currentUser.job.includes('Chairman')) {
        return r.requestorDepartment === 'Executive Leadership' && (r.requestorJob.includes('Director') || r.requestorJob.includes('Deputy'));
      }
      if (currentUser.job.includes('Director') && !currentUser.job.includes('Deputy')) {
        return (r.requestorDepartment === 'Executive Leadership' && r.requestorJob.includes('Deputy')) || r.requestorJob.startsWith('Department Head');
      }
      if (currentUser.job.includes('Deputy')) {
        return r.requestorJob.startsWith('Department Head');
      }
      return r.status === 'pending';
    }

    if (isManager) {
      return r.requestorDepartment === currentUser.department && !r.requestorJob.startsWith('Department Head') && r.status === 'pending';
    }

    return false;
  });
  const approvalRequests = applyLeaveFilter(rawApprovalRequests);

  // 3. Toàn công ty (company):
  const rawCompanyRequests = isHR ? leaveRequests : [];
  const companyRequests = applyLeaveFilter(rawCompanyRequests, true);

  const handleCreateSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser || !preview) return;

    if (isChairman) {
      showToast('Quy định: Chủ tịch Hội đồng Quản trị không tạo đơn xin nghỉ phép!');
      return;
    }

    if (!preview.isSufficientAnnualLeave) {
      showToast('Cảnh báo: Bạn không đủ quỹ phép năm để thực hiện yêu cầu này!');
      return;
    }

    submitLeaveRequest({
      requestorId: currentUser.userId,
      requestorName: currentUser.fullName,
      requestorCode: currentUser.employeeCode,
      requestorDepartment: currentUser.department,
      requestorJob: currentUser.job,
      requestorEmail: currentUser.email,
      fromDate,
      toDate,
      paidLeaveDays: preview.workDays,
      totalWorkingDays: preview.workDays,
      reason: reason || 'Nghỉ giải quyết công việc cá nhân'
    });

    setIsCreateModalOpen(false);
    setReason('');
    showToast('Đã gửi đơn xin nghỉ phép thành công! Đang chờ Quản lý phê duyệt.');
  };

  const handleApprove = (req: LeaveRequest) => {
    handleLeaveRequest(req.requestId, 'accepted');
    showToast(`Đã duyệt đơn nghỉ phép cho ${req.requestorName}`);
  };

  const handleRejectSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!rejectingReq) return;
    handleLeaveRequest(rejectingReq.requestId, 'rejected', rejectionReason || 'Không phù hợp với kế hoạch nhân sự');
    setRejectingReq(null);
    setRejectionReason('');
    showToast(`Đã từ chối đơn nghỉ phép của ${rejectingReq.requestorName}`);
  };

  const statusBadge = (status: LeaveRequestStatus) => {
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
            <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-1 rounded-full border border-indigo-200 mb-2">
              <CalendarDays className="h-3.5 w-3.5" />
              <span>Phân hệ Nghỉ Phép Tự Động (Spring Boot /api/leave)</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Quản Lý Đơn Xin Nghỉ Phép
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Tính toán ngày nghỉ trừ cuối tuần & ngày lễ, kiểm tra quỹ phép năm tức thời và quy trình duyệt phân cấp.
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            {isChairman ? (
              <span className="text-xs font-semibold text-slate-500 bg-slate-100 px-3.5 py-2 rounded-xl border border-slate-200">
                Chủ tịch HĐQT (Miễn chấm công & nghỉ phép)
              </span>
            ) : (
              <button
                onClick={() => setIsCreateModalOpen(true)}
                className="inline-flex items-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
              >
                <Plus className="h-4 w-4" />
                <span>Tạo đơn nghỉ phép mới</span>
              </button>
            )}
            {isHR && (
              <button
                onClick={() => showToast('Đã xuất file báo cáo nghỉ phép: ACT_Bao_Cao_Nghi_Phep.xlsx thành công!')}
                className="flex items-center gap-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-emerald-500/20 transition cursor-pointer"
              >
                <FileCheck className="h-4 w-4" />
                <span>Xuất Báo Cáo (Excel)</span>
              </button>
            )}
          </div>
        </div>

        {/* Quota Summary Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="rounded-2xl bg-white p-5 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Tổng Quỹ Phép Năm</span>
              <div className="mt-1 text-2xl font-black text-slate-900">
                {currentUser?.annualLeaveDays || 12} ngày
              </div>
            </div>
            <div className="p-3 rounded-xl bg-blue-50 text-blue-600"><Calendar className="h-6 w-6" /></div>
          </div>

          <div className="rounded-2xl bg-white p-5 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Phép Đã Sử Dụng</span>
              <div className="mt-1 text-2xl font-black text-amber-600">
                {currentUser?.usedLeaveDays || 0} ngày
              </div>
            </div>
            <div className="p-3 rounded-xl bg-amber-50 text-amber-600"><Clock className="h-6 w-6" /></div>
          </div>

          <div className="rounded-2xl bg-white p-5 border border-slate-200 shadow-xs flex items-center justify-between">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase tracking-wider">Phép Còn Lại</span>
              <div className="mt-1 text-2xl font-black text-emerald-600">
                {(currentUser?.annualLeaveDays || 12) - (currentUser?.usedLeaveDays || 0)} ngày
              </div>
            </div>
            <div className="p-3 rounded-xl bg-emerald-50 text-emerald-600"><CheckCircle2 className="h-6 w-6" /></div>
          </div>
        </div>

        {/* Tabs */}
        <div className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-xs font-bold">
          <button
            onClick={() => setActiveTab('my')}
            className={`px-4 py-2 rounded-xl transition cursor-pointer ${
              activeTab === 'my' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            Đơn của tôi ({myRequests.length})
          </button>
          {(isManager || isExecutive) && (
            <button
              onClick={() => setActiveTab('approvals')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'approvals' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <span>Hộp thư Duyệt đơn</span>
              {approvalRequests.length > 0 && (
                <span className="rounded-full bg-amber-500 text-white text-[10px] px-1.5 py-0.2 font-bold">
                  {approvalRequests.length}
                </span>
              )}
            </button>
          )}
          {isHR && (
            <button
              onClick={() => setActiveTab('company')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer ${
                activeTab === 'company' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              Toàn công ty ({companyRequests.length})
            </button>
          )}
        </div>

        {/* Unified Filter Toolbar matching LeaveFilterRequest */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
              <Filter className="h-4 w-4 text-indigo-600" />
              <span>Bộ lọc đơn nghỉ phép (DTO LeaveFilterRequest)</span>
            </div>
            {(filterStatus !== 'ALL' || filterFromDate || filterToDate || filterKeyword || filterDept !== 'ALL') && (
              <button
                onClick={handleResetFilters}
                className="text-xs text-blue-600 hover:text-blue-800 font-semibold cursor-pointer"
              >
                Xóa bộ lọc
              </button>
            )}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 text-xs">
            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">Từ ngày</label>
              <input
                type="date"
                value={filterFromDate}
                onChange={e => setFilterFromDate(e.target.value)}
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden font-mono"
              />
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">Đến ngày</label>
              <input
                type="date"
                value={filterToDate}
                onChange={e => setFilterToDate(e.target.value)}
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden font-mono"
              />
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">Trạng thái đơn</label>
              <select
                value={filterStatus}
                onChange={e => setFilterStatus(e.target.value)}
                className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
              >
                <option value="ALL">Tất cả trạng thái</option>
                <option value="pending">🟡 Đang chờ duyệt (PENDING)</option>
                <option value="accepted">🟢 Đã chấp thuận (ACCEPTED)</option>
                <option value="rejected">🔴 Đã từ chối (REJECTED)</option>
              </select>
            </div>

            <div className="sm:col-span-3">
              <label className="block text-[11px] font-medium text-slate-500 mb-1">
                {activeTab === 'company' ? 'Phòng ban' : 'Tìm kiếm'}
              </label>
              {activeTab === 'company' ? (
                <select
                  value={filterDept}
                  onChange={e => setFilterDept(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
                >
                  <option value="ALL">Tất cả phòng ban</option>
                  <option value="Executive Leadership">Executive Leadership</option>
                  <option value="Human Resources">Human Resources</option>
                  <option value="Information Technology">Information Technology</option>
                  <option value="Sales & Marketing">Sales & Marketing</option>
                  <option value="Finance & Accounting">Finance & Accounting</option>
                  <option value="Customer Support">Customer Support</option>
                </select>
              ) : (
                <div className="relative">
                  <Search className="h-4 w-4 text-slate-400 absolute left-2.5 top-2.5" />
                  <input
                    type="text"
                    value={filterKeyword}
                    onChange={e => setFilterKeyword(e.target.value)}
                    placeholder="Tìm tên, mã, lý do..."
                    className="w-full rounded-xl border border-slate-200 py-2 pl-8 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                  />
                </div>
              )}
            </div>

            {activeTab === 'company' && (
              <div className="sm:col-span-12">
                <div className="relative">
                  <Search className="h-4 w-4 text-slate-400 absolute left-3 top-2.5" />
                  <input
                    type="text"
                    value={filterKeyword}
                    onChange={e => setFilterKeyword(e.target.value)}
                    placeholder="Tìm kiếm theo tên nhân viên, mã nhân viên, lý do nghỉ..."
                    className="w-full rounded-xl border border-slate-200 py-2 pl-9 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                  />
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Tab 1: My Requests */}
        {activeTab === 'my' && (
          <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between">
              <h3 className="text-xs font-bold text-slate-800">Lịch sử nộp đơn của tôi (DTO StaffLeaveResponse)</h3>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Thời gian nghỉ</th>
                    <th className="py-3 px-4 text-center">Số ngày trừ phép</th>
                    <th className="py-3 px-4">Lý do</th>
                    <th className="py-3 px-4">Người duyệt</th>
                    <th className="py-3 px-4">Trạng thái</th>
                    <th className="py-3 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {myRequests.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="py-8 text-center text-slate-400 text-xs">
                        Không tìm thấy đơn nghỉ phép nào phù hợp với bộ lọc.
                      </td>
                    </tr>
                  ) : (
                    myRequests.map(req => (
                      <tr key={req.requestId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900 font-mono">{req.fromDate} → {req.toDate}</div>
                          <div className="text-[10px] text-slate-400">Nộp: {req.createdAt} • Công lịch: {req.totalWorkingDays || req.paidLeaveDays} ngày</div>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <span className="font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded">
                            {req.paidLeaveDays} ngày
                          </span>
                        </td>
                        <td className="py-3 px-4 text-slate-600 max-w-xs">
                          <div>{req.reason}</div>
                          {req.rejectionReason && (
                            <div className="text-[11px] text-red-600 font-medium mt-0.5">Lý do từ chối: {req.rejectionReason}</div>
                          )}
                        </td>
                        <td className="py-3 px-4 text-slate-600">
                          {req.approverName ? `${req.approverName} (${req.approverJob || 'Quản lý'})` : 'Chờ phân công'}
                        </td>
                        <td className="py-3 px-4">
                          {statusBadge(req.status)}
                        </td>
                        <td className="py-3 px-4 text-right">
                          {req.status === 'pending' ? (
                            <button
                              onClick={() => cancelLeaveRequest(req.requestId)}
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

        {/* Tab 2: Approvals (Manager / Executive) */}
        {activeTab === 'approvals' && (
          <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between">
              <h3 className="text-xs font-bold text-slate-800">Danh sách đơn cần phê duyệt cấp quản lý (DTO ManagerLeaveResponse)</h3>
              <span className="text-xs text-amber-700 font-semibold">{approvalRequests.length} đơn chờ xử lý</span>
            </div>

            {approvalRequests.length === 0 ? (
              <div className="p-8 text-center text-xs text-slate-500">
                Hiện tại không có đơn xin nghỉ phép nào cần bạn phê duyệt.
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3 px-4">Nhân sự</th>
                      <th className="py-3 px-4">Phòng ban & Chức danh</th>
                      <th className="py-3 px-4">Thời gian</th>
                      <th className="py-3 px-4 text-center">Số ngày nghỉ</th>
                      <th className="py-3 px-4 text-center">Quỹ phép còn</th>
                      <th className="py-3 px-4">Lý do nghỉ</th>
                      <th className="py-3 px-4 text-right">Phê duyệt</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {approvalRequests.map(req => (
                      <tr key={req.requestId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900">{req.requestorName}</div>
                          <div className="text-[10px] text-slate-400 font-mono">{req.requestorCode}</div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="font-medium text-slate-800">{req.requestorJob}</div>
                          <div className="text-[10px] text-slate-500">{req.requestorDepartment}</div>
                        </td>
                        <td className="py-3 px-4 font-mono font-medium text-slate-800">{req.fromDate} → {req.toDate}</td>
                        <td className="py-3 px-4 text-center font-bold text-blue-600">{req.paidLeaveDays} ngày</td>
                        <td className="py-3 px-4 text-center">
                          <span className="font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">
                            {req.remainingAnnualLeaveDays ?? 12} ngày
                          </span>
                        </td>
                        <td className="py-3 px-4 text-slate-600 max-w-xs">{req.reason}</td>
                        <td className="py-3 px-4 text-right">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => handleApprove(req)}
                              className="rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white px-3 py-1.5 text-xs font-bold transition cursor-pointer shadow-xs"
                            >
                              Duyệt
                            </button>
                            <button
                              onClick={() => {
                                setRejectingReq(req);
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

        {/* Tab 3: Company All */}
        {activeTab === 'company' && isHR && (
          <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between">
              <h3 className="text-xs font-bold text-slate-800">Theo dõi nghỉ phép toàn công ty (DTO HrLeaveResponse)</h3>
              <span className="text-xs text-slate-500">{companyRequests.length} đơn</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Nhân sự</th>
                    <th className="py-3 px-4">Liên hệ</th>
                    <th className="py-3 px-4">Phòng ban</th>
                    <th className="py-3 px-4">Thời gian</th>
                    <th className="py-3 px-4 text-center">Số ngày</th>
                    <th className="py-3 px-4 text-center">Phép còn</th>
                    <th className="py-3 px-4">Người duyệt</th>
                    <th className="py-3 px-4">Trạng thái</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {companyRequests.map(req => (
                    <tr key={req.requestId} className="hover:bg-slate-50/80 transition">
                      <td className="py-3 px-4">
                        <div className="font-bold text-slate-900">{req.requestorName}</div>
                        <div className="text-[10px] text-slate-400 font-mono">{req.requestorCode} • {req.requestorJob}</div>
                      </td>
                      <td className="py-3 px-4 font-mono text-[11px] text-slate-600">
                        <div>{req.requestorEmail || `${req.requestorCode.toLowerCase()}@act.com`}</div>
                        <div className="text-[10px] text-slate-400">{req.requestorPhoneNumber || '0901234567'}</div>
                      </td>
                      <td className="py-3 px-4 text-slate-600">{req.requestorDepartment}</td>
                      <td className="py-3 px-4 font-mono font-medium">{req.fromDate} → {req.toDate}</td>
                      <td className="py-3 px-4 text-center font-bold text-blue-600">{req.paidLeaveDays} ngày</td>
                      <td className="py-3 px-4 text-center font-bold text-emerald-600">{req.remainingAnnualLeaveDays ?? 12}</td>
                      <td className="py-3 px-4 text-slate-600">
                        {req.approverName ? `${req.approverName} (${req.approverJob || 'Quản lý'})` : '—'}
                      </td>
                      <td className="py-3 px-4">{statusBadge(req.status)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Modal Tạo Đơn Nghỉ Phép Mới với Live Calculation Preview */}
        {isCreateModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-xl rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2 text-indigo-600 font-bold text-sm">
                  <CalendarDays className="h-5 w-5" />
                  <span>Tạo Đơn Xin Nghỉ Phép (Spring Boot /api/leave)</span>
                </div>
                <button
                  onClick={() => setIsCreateModalOpen(false)}
                  className="rounded-full p-1 text-slate-400 hover:bg-slate-100 transition"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <form onSubmit={handleCreateSubmit} className="mt-4 space-y-4 text-xs">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Từ ngày</label>
                    <input
                      type="date"
                      value={fromDate}
                      onChange={e => setFromDate(e.target.value)}
                      required
                      className="w-full rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Đến ngày</label>
                    <input
                      type="date"
                      value={toDate}
                      onChange={e => setToDate(e.target.value)}
                      required
                      className="w-full rounded-xl border border-slate-300 p-2 text-xs font-mono text-slate-800"
                    />
                  </div>
                </div>

                {/* Live Preview Box (Tự động loại trừ T7/CN và ngày lễ) */}
                {preview && (
                  <div className="rounded-2xl bg-indigo-50/70 p-4 border border-indigo-100 space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-indigo-900 flex items-center gap-1.5">
                        <Sparkles className="h-4 w-4 text-indigo-600" />
                        <span>Xem trước tính toán ngày phép (LeavePreviewResponse)</span>
                      </span>
                    </div>

                    <div className="grid grid-cols-3 gap-2 text-[11px] pt-1">
                      <div className="bg-white p-2 rounded-lg border border-indigo-100 text-center">
                        <span className="text-slate-400 block">Tổng ngày lịch:</span>
                        <span className="font-bold text-slate-900 text-xs">{preview.requestedLeaveDays} ngày</span>
                      </div>
                      <div className="bg-white p-2 rounded-lg border border-indigo-100 text-center">
                        <span className="text-slate-400 block">Nghỉ T7/CN & Lễ:</span>
                        <span className="font-bold text-amber-600 text-xs">{preview.restDays + preview.holidayDays} ngày</span>
                      </div>
                      <div className="bg-white p-2 rounded-lg border border-indigo-100 text-center">
                        <span className="text-indigo-600 block font-bold">Thực tính nghỉ:</span>
                        <span className="font-black text-indigo-700 text-xs">{preview.workDays} ngày</span>
                      </div>
                    </div>

                    <div className="pt-2 border-t border-indigo-200/60 flex items-center justify-between text-[11px]">
                      <span>Quỹ phép còn lại: <strong>{preview.remainingAnnualLeaveDays} ngày</strong></span>
                      <span>Sau khi nghỉ còn: <strong className={preview.remainingAfterThisRequest < 0 ? 'text-red-600' : 'text-emerald-700'}>{preview.remainingAfterThisRequest} ngày</strong></span>
                    </div>

                    {!preview.isSufficientAnnualLeave && (
                      <div className="flex items-center gap-1 text-[11px] font-bold text-red-600">
                        <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                        <span>Số ngày nghỉ vượt quá quỹ phép năm còn lại của bạn!</span>
                      </div>
                    )}
                  </div>
                )}

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Lý do xin nghỉ</label>
                  <textarea
                    rows={3}
                    value={reason}
                    onChange={e => setReason(e.target.value)}
                    required
                    placeholder="Nhập lý do chi tiết (ví dụ: việc gia đình, khám sức khỏe, giải quyết việc riêng...)"
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
                    disabled={!preview?.isSufficientAnnualLeave}
                    className="flex items-center gap-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white px-5 py-2 font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
                  >
                    <Send className="h-4 w-4" />
                    <span>Gửi đơn xin nghỉ</span>
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Modal Từ Chối Đơn Nghỉ */}
        {rejectingReq && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl border border-slate-200">
              <h3 className="text-sm font-bold text-red-600 flex items-center gap-2 mb-2">
                <XCircle className="h-5 w-5" />
                <span>Từ chối đơn xin nghỉ phép</span>
              </h3>
              <p className="text-xs text-slate-600 mb-4">
                Nhân viên: <strong>{rejectingReq.requestorName}</strong> ({rejectingReq.fromDate} → {rejectingReq.toDate})
              </p>

              <form onSubmit={handleRejectSubmit} className="space-y-4 text-xs">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">Lý do từ chối (Bắt buộc)</label>
                  <textarea
                    rows={3}
                    value={rejectionReason}
                    onChange={e => setRejectionReason(e.target.value)}
                    required
                    placeholder="Nhập lý do từ chối để thông báo lại cho nhân viên..."
                    className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
                  />
                </div>

                <div className="flex items-center justify-end gap-2.5 pt-2">
                  <button
                    type="button"
                    onClick={() => setRejectingReq(null)}
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
