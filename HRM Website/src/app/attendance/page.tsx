'use client';

import React, { useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { MOCK_MONTHLY_SUMMARIES } from '@/mock/attendances';
import { AttendanceRecord, AttendanceStatus, MonthlyTimesheetSummary } from '@/types';
import {
  Clock,
  Camera,
  Calendar,
  FileSpreadsheet,
  Edit3,
  Trash2,
  Filter,
  Search,
  CheckCircle2,
  AlertCircle,
  Sparkles,
  Building2,
  Save,
  X,
  TrendingUp,
  Download,
  Lock,
  UserCheck
} from 'lucide-react';
import FaceScanModal from '@/components/layout/FaceScanModal';

export default function AttendancePage() {
  const { currentUser, isHR, isManager, isExecutive } = useAuth();
  const { attendances, editAttendanceRecord, deleteAttendanceRecord } = useHRMData();

  // Tab State: 'my' (Cá nhân) | 'dept' (Phòng ban) | 'company' (Toàn cty) | 'summary' (Tổng hợp công)
  const [activeTab, setActiveTab] = useState<'my' | 'dept' | 'company' | 'summary'>('my');
  const [isFaceModalOpen, setIsFaceModalOpen] = useState(false);

  // Daily attendance filters matching AttendanceFilterRequest (startDate, endDate, status, keyword, departmentNames)
  const [filterStartDate, setFilterStartDate] = useState('');
  const [filterEndDate, setFilterEndDate] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [filterKeyword, setFilterKeyword] = useState('');
  const [filterDept, setFilterDept] = useState('ALL');

  // Monthly summary filters matching MonthlyTimesheetFilterRequest (month, year, department, keyword)
  const [summaryMonth, setSummaryMonth] = useState<number>(9);
  const [summaryYear, setSummaryYear] = useState<number>(2026);
  const [summaryDept, setSummaryDept] = useState('ALL');
  const [summaryKeyword, setSummaryKeyword] = useState('');

  // Edit Modal State (HR only)
  const [editingRecord, setEditingRecord] = useState<AttendanceRecord | null>(null);
  const [editForm, setEditForm] = useState({
    clockInTime: '',
    clockOutTime: '',
    status: 'SUFFICIENT' as AttendanceStatus,
    reason: ''
  });

  const [toastMsg, setToastMsg] = useState('');

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };

  const handleResetDailyFilters = () => {
    setFilterStartDate('');
    setFilterEndDate('');
    setFilterStatus('ALL');
    setFilterKeyword('');
    setFilterDept('ALL');
  };

  // Reset tab if role switches and tab is no longer permitted
  React.useEffect(() => {
    if (!isHR && !isExecutive && activeTab === 'company') {
      setActiveTab('my');
    }
    if (!isManager && !isExecutive && activeTab === 'dept') {
      setActiveTab('my');
    }
  }, [isHR, isManager, isExecutive, activeTab]);

  // Bộ lọc chuẩn Spring Boot AttendanceFilterRequest
  const applyDailyFilter = (records: AttendanceRecord[], allowDeptFilter: boolean = false) => {
    return records.filter(a => {
      const matchKeyword = 
        !filterKeyword || 
        a.userName.toLowerCase().includes(filterKeyword.toLowerCase()) ||
        a.employeeCode.toLowerCase().includes(filterKeyword.toLowerCase());

      const matchDept = !allowDeptFilter || filterDept === 'ALL' || a.department === filterDept;
      const matchStatus = filterStatus === 'ALL' || a.status === filterStatus;
      const matchStart = !filterStartDate || a.workDate >= filterStartDate;
      const matchEnd = !filterEndDate || a.workDate <= filterEndDate;

      return matchKeyword && matchDept && matchStatus && matchStart && matchEnd;
    });
  };

  // 1. Chấm công cá nhân (Ai cũng xem được của mình)
  const myAttendances = applyDailyFilter(attendances.filter(a => a.userId === currentUser?.userId));

  // 2. Chấm công phòng ban (Chỉ Trưởng phòng & Ban Giám Đốc)
  const deptAttendances = applyDailyFilter(attendances.filter(a => {
    if (isExecutive) return true;
    return a.department === currentUser?.department;
  }));

  // 3. Chấm công toàn công ty (Chỉ HR & Ban Giám Đốc)
  const companyAttendances = applyDailyFilter(attendances, true);

  // 4. Dữ liệu Tổng Hợp Công Tháng (Phân quyền bảo mật theo Spring Boot AttendanceService dòng 460-520):
  const myMonthlySummary: MonthlyTimesheetSummary | undefined = MOCK_MONTHLY_SUMMARIES.find(
    s => s.userId === currentUser?.userId && s.month === summaryMonth && s.year === summaryYear
  );

  const visibleMonthlySummaries: MonthlyTimesheetSummary[] = (isHR || isExecutive
    ? MOCK_MONTHLY_SUMMARIES
    : isManager
    ? MOCK_MONTHLY_SUMMARIES.filter(s => s.department === currentUser?.department)
    : myMonthlySummary ? [myMonthlySummary] : []
  ).filter(s => {
    const matchK = !summaryKeyword || s.fullName.toLowerCase().includes(summaryKeyword.toLowerCase()) || s.employeeCode.toLowerCase().includes(summaryKeyword.toLowerCase());
    const matchD = summaryDept === 'ALL' || s.department === summaryDept;
    const matchM = s.month === Number(summaryMonth);
    const matchY = s.year === Number(summaryYear);
    return matchK && matchD && matchM && matchY;
  });

  const handleOpenEdit = (record: AttendanceRecord) => {
    setEditingRecord(record);
    setEditForm({
      clockInTime: record.clockInTime || '08:30:00',
      clockOutTime: record.clockOutTime || '17:30:00',
      status: record.status,
      reason: record.editedReason || 'Lỗi thiết bị nhận diện khuôn mặt'
    });
  };

  const handleSaveEdit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingRecord) return;
    editAttendanceRecord(
      editingRecord.attendanceId,
      {
        clockInTime: editForm.clockInTime,
        clockOutTime: editForm.clockOutTime,
        status: editForm.status
      },
      editForm.reason
    );
    setEditingRecord(null);
    showToast(`Đã cập nhật bản ghi chấm công cho ${editingRecord.userName}`);
  };

  const handleExportExcel = (type: 'daily' | 'monthly') => {
    const filename = type === 'daily' 
      ? `ACT_Bao_Cao_Cham_Cong_${Date.now()}.xlsx` 
      : `ACT_Bang_Tong_Hop_Cong_Thang_9_${Date.now()}.xlsx`;
    showToast(`Đã xuất file báo cáo ${filename} thành công!`);
  };

  const statusBadge = (status: AttendanceStatus) => {
    switch (status) {
      case 'SUFFICIENT':
        return <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 text-emerald-800 px-2.5 py-0.5 text-[11px] font-bold">Đúng giờ</span>;
      case 'WORKING':
        return <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 text-blue-800 px-2.5 py-0.5 text-[11px] font-bold">Đang làm việc</span>;
      case 'LATE':
        return <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 text-amber-800 px-2.5 py-0.5 text-[11px] font-bold">Đi trễ</span>;
      case 'EARLY':
        return <span className="inline-flex items-center gap-1 rounded-full bg-orange-100 text-orange-800 px-2.5 py-0.5 text-[11px] font-bold">Về sớm</span>;
      case 'HOLIDAY':
        return <span className="inline-flex items-center gap-1 rounded-full bg-purple-100 text-purple-800 px-2.5 py-0.5 text-[11px] font-bold">Nghỉ Lễ</span>;
      case 'LEAVE':
        return <span className="inline-flex items-center gap-1 rounded-full bg-indigo-100 text-indigo-800 px-2.5 py-0.5 text-[11px] font-bold">Nghỉ Phép</span>;
      case 'ADJUSTED':
        return <span className="inline-flex items-center gap-1 rounded-full bg-cyan-100 text-cyan-800 px-2.5 py-0.5 text-[11px] font-bold">Đã điều chỉnh</span>;
      default:
        return <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 text-slate-700 px-2.5 py-0.5 text-[11px] font-medium">{status}</span>;
    }
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Toast Notification */}
        {toastMsg && (
          <div className="fixed top-20 right-6 z-50 rounded-2xl bg-emerald-600 text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold animate-in slide-in-from-top-4">
            <CheckCircle2 className="h-5 w-5" />
            <span>{toastMsg}</span>
          </div>
        )}

        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full border border-blue-200 mb-2">
              <Clock className="h-3.5 w-3.5" />
              <span>Dữ liệu Chấm công & Giờ làm Đồng bộ Trực tiếp</span>
            </div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              Chấm Công & Bảng Tổng Hợp Công
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Theo dõi giờ vào/ra, điểm danh ca kíp, phê duyệt và xuất báo cáo công tháng chuẩn phân quyền Spring Boot.
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            <button
              onClick={() => setIsFaceModalOpen(true)}
              className="flex items-center gap-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-orange-500/20 transition cursor-pointer"
            >
              <Clock className="h-4 w-4" />
              <span>Mô phỏng Ghi Nhận Chấm Công</span>
            </button>
            {(isHR || isExecutive) && (
              <button
                onClick={() => handleExportExcel(activeTab === 'summary' ? 'monthly' : 'daily')}
                className="flex items-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-emerald-500/20 transition cursor-pointer"
              >
                <FileSpreadsheet className="h-4 w-4" />
                <span>Xuất Excel</span>
              </button>
            )}
          </div>
        </div>

        {/* Navigation Tabs with Strict Role Badges */}
        <div className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-xs font-bold">
          {/* Tab 1: Mọi nhân viên */}
          <button
            onClick={() => setActiveTab('my')}
            className={`px-4 py-2 rounded-xl transition cursor-pointer ${
              activeTab === 'my' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            Chấm công của tôi ({myAttendances.length})
          </button>

          {/* Tab 2: Chỉ Trưởng phòng & BGĐ */}
          {isManager && (
            <button
              onClick={() => setActiveTab('dept')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'dept' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <span>Phòng {currentUser?.department}</span>
              <span className="text-[10px] font-normal opacity-80">({deptAttendances.length})</span>
            </button>
          )}

          {/* Tab 3: Chỉ HR & BGĐ */}
          {(isHR || isExecutive) && (
            <button
              onClick={() => setActiveTab('company')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'company' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <span>Toàn công ty</span>
              <span className="text-[10px] font-normal opacity-80">({attendances.length})</span>
            </button>
          )}

          {/* Tab 4: Tự động đổi phạm vi hiển thị theo vai trò */}
          <button
            onClick={() => setActiveTab('summary')}
            className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'summary' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            {isHR || isExecutive ? (
              <span>Tổng hợp công toàn công ty (HR)</span>
            ) : isManager ? (
              <span>Tổng hợp công phòng {currentUser?.department}</span>
            ) : (
              <span>Tổng hợp công tháng của tôi</span>
            )}
          </button>
        </div>

        {/* Unified Daily Filter Bar matching AttendanceFilterRequest */}
        {activeTab !== 'summary' && (
          <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
                <Filter className="h-4 w-4 text-blue-600" />
                <span>Bộ lọc điểm danh hàng ngày (DTO AttendanceFilterRequest)</span>
              </div>
              {(filterStartDate || filterEndDate || filterStatus !== 'ALL' || filterKeyword || filterDept !== 'ALL') && (
                <button
                  onClick={handleResetDailyFilters}
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
                  value={filterStartDate}
                  onChange={e => setFilterStartDate(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden font-mono"
                />
              </div>

              <div className="sm:col-span-3">
                <label className="block text-[11px] font-medium text-slate-500 mb-1">Đến ngày</label>
                <input
                  type="date"
                  value={filterEndDate}
                  onChange={e => setFilterEndDate(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden font-mono"
                />
              </div>

              <div className="sm:col-span-3">
                <label className="block text-[11px] font-medium text-slate-500 mb-1">Trạng thái chấm công</label>
                <select
                  value={filterStatus}
                  onChange={e => setFilterStatus(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
                >
                  <option value="ALL">Tất cả trạng thái</option>
                  <option value="SUFFICIENT">Đúng giờ (SUFFICIENT)</option>
                  <option value="WORKING">Đang làm việc (WORKING)</option>
                  <option value="LATE">Đi trễ (LATE)</option>
                  <option value="EARLY">Về sớm (EARLY)</option>
                  <option value="LEAVE">Nghỉ phép (LEAVE)</option>
                  <option value="HOLIDAY">Nghỉ Lễ (HOLIDAY)</option>
                  <option value="ADJUSTED">Đã điều chỉnh (ADJUSTED)</option>
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
                      placeholder="Tìm ghi chú, mã..."
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
                      placeholder="Tìm kiếm theo tên nhân viên, mã nhân viên..."
                      className="w-full rounded-xl border border-slate-200 py-2 pl-9 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Tab 1: Chấm công cá nhân */}
        {activeTab === 'my' && (
          <div className="space-y-4">
            <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
              <div className="p-4 border-b border-slate-100 flex items-center justify-between">
                <h3 className="text-xs font-bold text-slate-800">
                  Lịch sử điểm danh cá nhân: {currentUser?.fullName} ({currentUser?.employeeCode})
                </h3>
                <span className="text-[11px] text-slate-400">Ca làm việc: {currentUser?.shiftName}</span>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3 px-4">Ngày làm việc</th>
                      <th className="py-3 px-4">Giờ Vào Ca</th>
                      <th className="py-3 px-4">Giờ Ra Ca</th>
                      <th className="py-3 px-4">Trạng thái</th>
                      <th className="py-3 px-4">Phương thức Xác thực</th>
                      <th className="py-3 px-4">Ghi chú / Điều chỉnh</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {myAttendances.map(record => (
                      <tr key={record.attendanceId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4 font-bold text-slate-900 font-mono">
                          {record.workDate}
                        </td>
                        <td className="py-3 px-4 font-mono font-bold text-slate-800">
                          {record.clockInTime || '—'}
                        </td>
                        <td className="py-3 px-4 font-mono font-bold text-slate-800">
                          {record.clockOutTime || '—'}
                        </td>
                        <td className="py-3 px-4">
                          {statusBadge(record.status)}
                        </td>
                        <td className="py-3 px-4">
                          {record.faceRecognitionVerified ? (
                            <span className="inline-flex items-center gap-1 text-emerald-700 font-medium text-[11px]">
                              <CheckCircle2 className="h-3.5 w-3.5" />
                              Face ID ({record.faceConfidence}%)
                            </span>
                          ) : (
                            <span className="text-slate-400 text-[11px]">Thủ công</span>
                          )}
                        </td>
                        <td className="py-3 px-4 text-slate-500 text-[11px]">
                          {record.isEdited ? (
                            <span className="text-cyan-700 font-medium">
                              Sửa bởi {record.editorName}: {record.editedReason}
                            </span>
                          ) : (
                            record.deviceLocation || 'Bình thường'
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Tab 2: Chấm công Phòng ban (Chỉ Trưởng phòng & BGĐ) */}
        {activeTab === 'dept' && isManager && (
          <div className="space-y-4">
            <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
              <div className="p-4 border-b border-slate-100 flex items-center justify-between">
                <h3 className="text-xs font-bold text-slate-800">
                  Điểm danh nhân viên Phòng: {currentUser?.department}
                </h3>
                <span className="text-[11px] text-slate-400 font-medium">Quyền: Trưởng phòng</span>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3 px-4">Nhân sự</th>
                      <th className="py-3 px-4">Ngày</th>
                      <th className="py-3 px-4">Giờ Vào</th>
                      <th className="py-3 px-4">Giờ Ra</th>
                      <th className="py-3 px-4">Trạng thái</th>
                      <th className="py-3 px-4">Xác thực Face ID</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {deptAttendances.map(record => (
                      <tr key={record.attendanceId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900">{record.userName}</div>
                          <div className="text-[10px] text-slate-400 font-mono">{record.employeeCode} • {record.job}</div>
                        </td>
                        <td className="py-3 px-4 font-mono font-medium">{record.workDate}</td>
                        <td className="py-3 px-4 font-mono font-bold text-slate-800">{record.clockInTime || '—'}</td>
                        <td className="py-3 px-4 font-mono font-bold text-slate-800">{record.clockOutTime || '—'}</td>
                        <td className="py-3 px-4">{statusBadge(record.status)}</td>
                        <td className="py-3 px-4">
                          {record.faceRecognitionVerified ? (
                            <span className="text-emerald-700 font-medium text-[11px] flex items-center gap-1">
                              <CheckCircle2 className="h-3.5 w-3.5" /> Face ID ({record.faceConfidence}%)
                            </span>
                          ) : (
                            <span className="text-slate-400 text-[11px]">Thủ công</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Tab 3: Chấm công Toàn công ty (Chỉ HR & Ban Giám Đốc) */}
        {activeTab === 'company' && (isHR || isExecutive) && (
          <div className="space-y-4">
            {/* Table */}
            <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3 px-4">Nhân sự</th>
                      <th className="py-3 px-4">Phòng ban</th>
                      <th className="py-3 px-4">Ngày</th>
                      <th className="py-3 px-4">Vào / Ra</th>
                      <th className="py-3 px-4">Trạng thái</th>
                      <th className="py-3 px-4">Xác thực</th>
                      <th className="py-3 px-4 text-right">Quyền HR</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {companyAttendances.map(record => (
                      <tr key={record.attendanceId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900">{record.userName}</div>
                          <div className="text-[10px] text-slate-400 font-mono">{record.employeeCode}</div>
                        </td>
                        <td className="py-3 px-4 text-slate-600">{record.department}</td>
                        <td className="py-3 px-4 font-mono font-medium">{record.workDate}</td>
                        <td className="py-3 px-4 font-mono">
                          <span className="font-bold text-slate-800">{record.clockInTime || '—'}</span>
                          <span className="text-slate-400 mx-1">→</span>
                          <span className="font-bold text-slate-800">{record.clockOutTime || '—'}</span>
                        </td>
                        <td className="py-3 px-4">{statusBadge(record.status)}</td>
                        <td className="py-3 px-4">
                          {record.faceRecognitionVerified ? (
                            <span className="text-emerald-700 font-medium text-[11px] flex items-center gap-1">
                              <CheckCircle2 className="h-3.5 w-3.5" /> Face ID
                            </span>
                          ) : (
                            <span className="text-slate-400 text-[11px]">Thủ công</span>
                          )}
                        </td>
                        <td className="py-3 px-4 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              onClick={() => handleOpenEdit(record)}
                              className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition cursor-pointer"
                              title="Sửa bản ghi chấm công (HR)"
                            >
                              <Edit3 className="h-3.5 w-3.5" />
                            </button>
                            <button
                              onClick={() => deleteAttendanceRecord(record.attendanceId)}
                              className="p-1.5 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 transition cursor-pointer"
                              title="Xóa bản ghi (HR)"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Tab 4: Bảng Tổng Hợp Công Tháng (Phân Quyền Tuyệt Đối) */}
        {activeTab === 'summary' && (
          <div className="space-y-4">
            {/* Monthly Timesheet Filter Toolbar (DTO MonthlyTimesheetFilterRequest) */}
            <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
                  <FileSpreadsheet className="h-4 w-4 text-emerald-600" />
                  <span>Bộ lọc bảng tổng hợp công tháng (DTO MonthlyTimesheetFilterRequest)</span>
                </div>
                {(summaryMonth !== 9 || summaryYear !== 2026 || summaryDept !== 'ALL' || summaryKeyword) && (
                  <button
                    onClick={() => {
                      setSummaryMonth(9);
                      setSummaryYear(2026);
                      setSummaryDept('ALL');
                      setSummaryKeyword('');
                    }}
                    className="text-xs text-blue-600 hover:text-blue-800 font-semibold cursor-pointer"
                  >
                    Mặc định tháng 09/2026
                  </button>
                )}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 text-xs">
                <div className="sm:col-span-3">
                  <label className="block text-[11px] font-medium text-slate-500 mb-1">Tháng làm việc</label>
                  <select
                    value={summaryMonth}
                    onChange={e => setSummaryMonth(Number(e.target.value))}
                    className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
                  >
                    {Array.from({ length: 12 }, (_, i) => i + 1).map(m => (
                      <option key={m} value={m}>Tháng {m < 10 ? `0${m}` : m}</option>
                    ))}
                  </select>
                </div>

                <div className="sm:col-span-3">
                  <label className="block text-[11px] font-medium text-slate-500 mb-1">Năm</label>
                  <select
                    value={summaryYear}
                    onChange={e => setSummaryYear(Number(e.target.value))}
                    className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
                  >
                    <option value={2025}>Năm 2025</option>
                    <option value={2026}>Năm 2026</option>
                  </select>
                </div>

                {(isHR || isExecutive) && (
                  <div className="sm:col-span-3">
                    <label className="block text-[11px] font-medium text-slate-500 mb-1">Phòng ban</label>
                    <select
                      value={summaryDept}
                      onChange={e => setSummaryDept(e.target.value)}
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
                  </div>
                )}

                {(isManager || isHR || isExecutive) && (
                  <div className={isHR || isExecutive ? "sm:col-span-3" : "sm:col-span-6"}>
                    <label className="block text-[11px] font-medium text-slate-500 mb-1">Tìm kiếm nhân sự</label>
                    <div className="relative">
                      <Search className="h-4 w-4 text-slate-400 absolute left-2.5 top-2.5" />
                      <input
                        type="text"
                        value={summaryKeyword}
                        onChange={e => setSummaryKeyword(e.target.value)}
                        placeholder="Tìm theo tên, mã NV..."
                        className="w-full rounded-xl border border-slate-200 py-2 pl-8 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                      />
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Nếu là Nhân Viên Thường: Xem Thẻ Chi Tiết Đầy Đủ 11 Chỉ Số của chính mình */}
            {!isManager && !isHR && !isExecutive && (
              myMonthlySummary ? (
                <div className="rounded-3xl bg-white p-6 sm:p-8 border border-slate-200 shadow-sm max-w-4xl mx-auto space-y-6">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-slate-100 gap-3">
                    <div>
                      <span className="text-[11px] font-bold text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full border border-blue-200">
                        Bảng Công Cá Nhân Tháng {summaryMonth < 10 ? `0${summaryMonth}` : summaryMonth}/{summaryYear} (API /summary/me)
                      </span>
                      <h2 className="text-xl font-black text-slate-900 mt-2">{myMonthlySummary.fullName}</h2>
                      <p className="text-xs text-slate-500">{myMonthlySummary.employeeCode} • {myMonthlySummary.job} • {myMonthlySummary.department}</p>
                    </div>
                    <div className="sm:text-right p-3 bg-blue-50 rounded-2xl border border-blue-100">
                      <span className="text-xs text-blue-700 block font-medium">Tổng giờ tính lương (totalPaidHours):</span>
                      <span className="text-3xl font-black text-blue-900">{myMonthlySummary.totalPaidHours}h</span>
                    </div>
                  </div>

                  {/* 11 Fields DTO Matrix */}
                  <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3 text-xs">
                    <div className="p-3.5 bg-slate-50 rounded-2xl border border-slate-200">
                      <span className="text-[11px] text-slate-400 block font-medium">Công chuẩn tháng</span>
                      <span className="text-lg font-black text-slate-900">{myMonthlySummary.standardWorkingDays} ngày</span>
                      <span className="text-[10px] text-slate-400 block mt-0.5">standardWorkingDays</span>
                    </div>

                    <div className="p-3.5 bg-blue-50 rounded-2xl border border-blue-100">
                      <span className="text-[11px] text-blue-600 block font-medium">Công thực tế</span>
                      <span className="text-lg font-black text-blue-700">{myMonthlySummary.actualWorkedDays} ngày</span>
                      <span className="text-[10px] text-blue-400 block mt-0.5">actualWorkedDays</span>
                    </div>

                    <div className="p-3.5 bg-indigo-50 rounded-2xl border border-indigo-100">
                      <span className="text-[11px] text-indigo-600 block font-medium">Giờ làm việc thực tế</span>
                      <span className="text-lg font-black text-indigo-700">{myMonthlySummary.totalActualHours} giờ</span>
                      <span className="text-[10px] text-indigo-400 block mt-0.5">totalActualHours</span>
                    </div>

                    <div className="p-3.5 bg-orange-50 rounded-2xl border border-orange-100">
                      <span className="text-[11px] text-orange-700 block font-medium">Giờ làm thêm (OT)</span>
                      <span className="text-lg font-black text-orange-800">{myMonthlySummary.overtimeHours} giờ</span>
                      <span className="text-[10px] text-orange-400 block mt-0.5">overtimeHours</span>
                    </div>

                    <div className="p-3.5 bg-amber-50 rounded-2xl border border-amber-100">
                      <span className="text-[11px] text-amber-700 block font-medium">Đi trễ (Lần / Phút)</span>
                      <span className="text-lg font-black text-amber-800">{myMonthlySummary.lateCount} lần ({myMonthlySummary.totalLateMinutes}p)</span>
                      <span className="text-[10px] text-amber-500 block mt-0.5">lateCount & totalLateMinutes</span>
                    </div>

                    <div className="p-3.5 bg-yellow-50 rounded-2xl border border-yellow-100">
                      <span className="text-[11px] text-yellow-700 block font-medium">Về sớm</span>
                      <span className="text-lg font-black text-yellow-800">{myMonthlySummary.earlyDepartureCount} lần</span>
                      <span className="text-[10px] text-yellow-500 block mt-0.5">earlyDepartureCount</span>
                    </div>

                    <div className="p-3.5 bg-red-50 rounded-2xl border border-red-100">
                      <span className="text-[11px] text-red-600 block font-medium">Vắng mặt không phép</span>
                      <span className="text-lg font-black text-red-700">{myMonthlySummary.absentDays} ngày</span>
                      <span className="text-[10px] text-red-400 block mt-0.5">absentDays</span>
                    </div>

                    <div className="p-3.5 bg-cyan-50 rounded-2xl border border-cyan-100">
                      <span className="text-[11px] text-cyan-700 block font-medium">Nghỉ phép có lương</span>
                      <span className="text-lg font-black text-cyan-800">{myMonthlySummary.paidLeaveDays} ngày</span>
                      <span className="text-[10px] text-cyan-400 block mt-0.5">paidLeaveDays</span>
                    </div>

                    <div className="p-3.5 bg-slate-100 rounded-2xl border border-slate-200">
                      <span className="text-[11px] text-slate-500 block font-medium">Nghỉ không lương</span>
                      <span className="text-lg font-black text-slate-700">{myMonthlySummary.unpaidLeaveDays} ngày</span>
                      <span className="text-[10px] text-slate-400 block mt-0.5">unpaidLeaveDays</span>
                    </div>

                    <div className="p-3.5 bg-emerald-50 rounded-2xl border border-emerald-100 sm:col-span-2 lg:col-span-3 flex items-center justify-between">
                      <div>
                        <span className="text-[11px] text-emerald-700 block font-medium">Quỹ phép năm còn lại</span>
                        <span className="text-base font-black text-emerald-900">{myMonthlySummary.remainingAnnualLeaveDays} ngày phép</span>
                        <span className="text-[10px] text-emerald-600 block mt-0.5">remainingAnnualLeaveDays (Đã trừ các đơn nghỉ hợp lệ)</span>
                      </div>
                      <CheckCircle2 className="h-6 w-6 text-emerald-600" />
                    </div>
                  </div>
                </div>
              ) : (
                <div className="p-8 text-center text-xs text-slate-500 bg-white rounded-2xl border border-slate-200">
                  Không tìm thấy bản ghi tổng hợp công cho Tháng {summaryMonth}/{summaryYear}.
                </div>
              )
            )}

            {/* Nếu là Quản lý / HR / Giám đốc: Xem Bảng Tổng Hợp Đầy Đủ 11 Cột */}
            {(isManager || isHR || isExecutive) && (
              <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
                <div className="p-4 border-b border-slate-100 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                  <div>
                    <h3 className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                      <span>Bảng tổng hợp công Tháng {summaryMonth < 10 ? `0${summaryMonth}` : summaryMonth}/{summaryYear}</span>
                      <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[10px] text-blue-700 font-semibold border border-blue-200">
                        {isHR || isExecutive ? 'Toàn công ty (HR)' : `Phòng ${currentUser?.department}`}
                      </span>
                    </h3>
                    <p className="text-[11px] text-slate-500">
                      {isHR || isExecutive 
                        ? 'Dữ liệu toàn công ty (API /api/attendances/summary/company) - Hiển thị đủ 11 chỉ số DTO MonthlyTimesheetSummaryResponse' 
                        : `Chỉ hiển thị các nhân sự thuộc phòng ${currentUser?.department} (API /api/attendances/summary/department)`}
                    </p>
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleExportExcel('monthly')}
                      className="flex items-center gap-1.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white px-3 py-1.5 text-xs font-bold transition cursor-pointer"
                    >
                      <Download className="h-3.5 w-3.5" />
                      <span>Xuất Excel Báo Cáo</span>
                    </button>
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                      <tr>
                        <th className="py-3 px-3">Nhân sự</th>
                        <th className="py-3 px-3">Phòng ban</th>
                        <th className="py-3 px-2 text-center" title="standardWorkingDays">Công Chuẩn</th>
                        <th className="py-3 px-2 text-center" title="actualWorkedDays">Công Thực</th>
                        <th className="py-3 px-2 text-center" title="lateCount / totalLateMinutes">Đi Trễ</th>
                        <th className="py-3 px-2 text-center" title="earlyDepartureCount">Về Sớm</th>
                        <th className="py-3 px-2 text-center" title="absentDays">Vắng KP</th>
                        <th className="py-3 px-2 text-center" title="paidLeaveDays">Phép Hưởng Lương</th>
                        <th className="py-3 px-2 text-center" title="unpaidLeaveDays">Nghỉ Không Lương</th>
                        <th className="py-3 px-2 text-center" title="remainingAnnualLeaveDays">Phép Còn</th>
                        <th className="py-3 px-2 text-center" title="totalActualHours">Giờ Thực Làm</th>
                        <th className="py-3 px-2 text-center" title="overtimeHours">Giờ OT</th>
                        <th className="py-3 px-3 text-right font-black" title="totalPaidHours">Tổng Giờ Tính Lương</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 text-slate-700">
                      {visibleMonthlySummaries.map(item => (
                        <tr key={item.userId} className="hover:bg-slate-50/80 transition">
                          <td className="py-3 px-3">
                            <div className="font-bold text-slate-900">{item.fullName}</div>
                            <div className="text-[10px] text-slate-400 font-mono">{item.employeeCode}</div>
                          </td>
                          <td className="py-3 px-3 text-slate-600">{item.department}</td>
                          <td className="py-3 px-2 text-center font-bold text-slate-800">{item.standardWorkingDays}</td>
                          <td className="py-3 px-2 text-center font-bold text-blue-600">{item.actualWorkedDays}</td>
                          <td className="py-3 px-2 text-center">
                            {item.lateCount > 0 ? (
                              <span className="text-amber-700 font-bold bg-amber-50 px-1.5 py-0.5 rounded text-[11px]">
                                {item.lateCount} lần ({item.totalLateMinutes}p)
                              </span>
                            ) : (
                              <span className="text-slate-400">0</span>
                            )}
                          </td>
                          <td className="py-3 px-2 text-center">
                            {item.earlyDepartureCount > 0 ? (
                              <span className="text-yellow-700 font-bold bg-yellow-50 px-1.5 py-0.5 rounded text-[11px]">
                                {item.earlyDepartureCount} lần
                              </span>
                            ) : (
                              <span className="text-slate-400">0</span>
                            )}
                          </td>
                          <td className="py-3 px-2 text-center">
                            {item.absentDays > 0 ? (
                              <span className="text-red-700 font-bold bg-red-50 px-1.5 py-0.5 rounded text-[11px]">
                                {item.absentDays}
                              </span>
                            ) : (
                              <span className="text-slate-400">0</span>
                            )}
                          </td>
                          <td className="py-3 px-2 text-center font-bold text-indigo-600">{item.paidLeaveDays}</td>
                          <td className="py-3 px-2 text-center text-slate-500">{item.unpaidLeaveDays || 0}</td>
                          <td className="py-3 px-2 text-center font-bold text-emerald-600">{item.remainingAnnualLeaveDays}</td>
                          <td className="py-3 px-2 text-center font-mono font-medium text-slate-700">{item.totalActualHours}h</td>
                          <td className="py-3 px-2 text-center font-bold text-orange-600">{item.overtimeHours}h</td>
                          <td className="py-3 px-3 text-right font-black text-blue-900 bg-blue-50/50">{item.totalPaidHours}h</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Modal Sửa Bản Ghi Chấm Công (Dành riêng cho HR - EditAttendanceRequest) */}
        {editingRecord && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-lg rounded-3xl bg-white p-6 shadow-2xl border border-slate-200">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2 text-blue-600 font-bold text-sm">
                  <Edit3 className="h-4 w-4" />
                  <span>Điều chỉnh giờ công (API /api/attendances/edit)</span>
                </div>
                <button
                  onClick={() => setEditingRecord(null)}
                  className="rounded-full p-1 text-slate-400 hover:bg-slate-100 transition"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <form onSubmit={handleSaveEdit} className="mt-4 space-y-4 text-xs">
                <div>
                  <span className="text-slate-400 block font-medium">Nhân sự</span>
                  <span className="font-bold text-sm text-slate-900 block">
                    {editingRecord.userName} ({editingRecord.employeeCode}) - Ngày {editingRecord.workDate}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Giờ vào thực tế</label>
                    <input
                      type="text"
                      value={editForm.clockInTime}
                      onChange={e => setEditForm({ ...editForm, clockInTime: e.target.value })}
                      placeholder="08:30:00"
                      className="w-full rounded-xl border border-slate-300 p-2 font-mono text-xs text-slate-800"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Giờ ra thực tế</label>
                    <input
                      type="text"
                      value={editForm.clockOutTime}
                      onChange={e => setEditForm({ ...editForm, clockOutTime: e.target.value })}
                      placeholder="17:30:00"
                      className="w-full rounded-xl border border-slate-300 p-2 font-mono text-xs text-slate-800"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Trạng thái điều chỉnh</label>
                  <select
                    value={editForm.status}
                    onChange={e => setEditForm({ ...editForm, status: e.target.value as AttendanceStatus })}
                    className="w-full rounded-xl border border-slate-300 p-2 text-xs text-slate-800 bg-white"
                  >
                    <option value="SUFFICIENT">Đúng giờ (SUFFICIENT)</option>
                    <option value="LATE">Đi trễ (LATE)</option>
                    <option value="EARLY">Về sớm (EARLY)</option>
                    <option value="ADJUSTED">Đã điều chỉnh (ADJUSTED)</option>
                    <option value="LEAVE">Nghỉ phép (LEAVE)</option>
                    <option value="BUSINESS_TRIP">Công tác (BUSINESS_TRIP)</option>
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-slate-700 mb-1">Lý do điều chỉnh (Bắt buộc cho HR)</label>
                  <textarea
                    rows={3}
                    value={editForm.reason}
                    onChange={e => setEditForm({ ...editForm, reason: e.target.value })}
                    required
                    placeholder="Ví dụ: Lỗi camera nhận diện khuôn mặt, Quên quẹt mặt lúc vào ca..."
                    className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
                  />
                </div>

                <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2.5">
                  <button
                    type="button"
                    onClick={() => setEditingRecord(null)}
                    className="rounded-xl px-4 py-2 font-bold text-slate-600 hover:bg-slate-100 transition"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    className="flex items-center gap-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-5 py-2 font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
                  >
                    <Save className="h-4 w-4" />
                    <span>Lưu điều chỉnh</span>
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Face Scan Simulator */}
        {isFaceModalOpen && (
          <FaceScanModal onClose={() => setIsFaceModalOpen(false)} />
        )}
      </div>
    </AppShell>
  );
}
