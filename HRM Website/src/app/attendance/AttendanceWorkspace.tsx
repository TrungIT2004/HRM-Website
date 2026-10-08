'use client';

import React, { useState, useRef, useEffect } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { AttendanceRecord, AttendanceStatus } from '@/types';
import { attendanceService } from '@/services/attendanceService';
import MyOverviewTab from '@/components/attendance/MyOverviewTab';
import WorkShiftTab from '@/components/attendance/WorkShiftTab';
import {
  Clock,
  Camera,
  FileSpreadsheet,
  Edit3,
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
  Pencil,
  UserCheck,
  LayoutGrid,
  CalendarDays
} from 'lucide-react';
import { formatDateVN } from '@/utils/format';
import { DATE_PRESETS, DatePreset, dateRangeFor, fillDateInputs } from '@/utils/dateRange';

export type AttendanceTab = 'overview' | 'daily' | 'schedule';

// ponytail: workspace cá nhân — chỉ số liệu của chính mình, vào thẳng route con.
export default function AttendanceWorkspace({ tab }: { tab: AttendanceTab }) {
  const { currentUser, isHR, isExecutive } = useAuth();
  const { attendances } = useHRMData(); // ponytail: mock fallback khi API lỗi

  // ponytail: tab cố định theo route (/overview, /daily, /schedule, /summary, /requests)
  // ponytail: trang cá nhân chỉ xem của mình — scope cố định, không pill chuyển phạm vi

  // Xem nhanh + mặc định: my/dept = tuần hiện tại T2-CN, company = hôm nay.
  // Khoảng ngày + format ISO nằm ở utils/dateRange (dùng chung với Nghỉ phép / Làm thêm giờ).
  const applyDatePreset = (p: DatePreset) => {
    const r = dateRangeFor(p);
    setAppliedDailyFilters(prev => ({ ...prev, ...r }));
    syncDailyFormDates(r);
  };
  const defaultDatesFor = (tab: string) => dateRangeFor(tab === 'company' ? 'today' : 'week');

  // Daily filter form ref — reads values on submit
  const dailyFormRef = useRef<HTMLFormElement>(null);
  const [appliedDailyFilters, setAppliedDailyFilters] = useState({
    ...dateRangeFor('week'),
    status: 'ALL',
    keyword: '',
    dept: 'ALL'
  });

  // Dữ liệu daily từ API thật, rớt mạng mới dùng mock
  const [dailyRecords, setDailyRecords] = useState<AttendanceRecord[]>([]);
  const [isDailyLoading, setIsDailyLoading] = useState(false);

  // ponytail: trang cá nhân chỉ gọi API của mình
  const fetchDaily = async (f = appliedDailyFilters) => {
    setIsDailyLoading(true);
    try {
      const params = {
        startDate: f.startDate || undefined,
        endDate: f.endDate || undefined,
        status: f.status !== 'ALL' ? f.status : undefined,
        keyword: f.keyword || undefined,
        size: 200
      };
      const res = await attendanceService.getMyAttendances(params);
      setDailyRecords(Array.isArray(res?.content) ? res.content : []);
    } catch {
      setDailyRecords(attendances);
    } finally {
      setIsDailyLoading(false);
    }
  };

  useEffect(() => {
    if (tab === 'daily') {
      fetchDaily();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, appliedDailyFilters, currentUser?.userId]);

  const syncDailyFormDates = (r: { startDate: string; endDate: string }) => {
    fillDateInputs(dailyFormRef.current, r);
  };

  const handleApplyDailyFilters = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const fd = new FormData(dailyFormRef.current!);
    setAppliedDailyFilters({
      startDate: fd.get('startDate') as string || '',
      endDate: fd.get('endDate') as string || '',
      status: fd.get('status') as string || 'ALL',
      keyword: fd.get('keyword') as string || '',
      dept: fd.get('dept') as string || 'ALL'
    });
  };

  const handleResetDailyFilters = () => {
    const d = defaultDatesFor('my');
    setAppliedDailyFilters({ ...d, status: 'ALL', keyword: '', dept: 'ALL' });
    dailyFormRef.current?.reset();
    syncDailyFormDates(d);
  };

  const [editingRecord, setEditingRecord] = useState<AttendanceRecord | null>(null);
  // ponytail: trang cá nhân không có bảng tổng hợp công tháng (nằm bên quản lý)
  const [editForm, setEditForm] = useState({
    clockInTime: '',
    clockOutTime: '',
    status: 'SUFFICIENT' as AttendanceStatus,
    reason: ''
  });

  const [toastMsg, setToastMsg] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToastMsg(msg);
    setToastType(type);
    setTimeout(() => setToastMsg(''), 4000);
  };



  // ponytail: scope cố định 'my' ở trên, không cần effect reset nữa

  // Bộ lọc chuẩn Spring Boot AttendanceFilterRequest
  const applyDailyFilter = (records: AttendanceRecord[], allowDeptFilter: boolean = false) => {
    return records.filter(a => {
      const matchKeyword = 
        !appliedDailyFilters.keyword || 
        ((a.userName || a.fullName)?.toLowerCase() || '').includes(appliedDailyFilters.keyword.toLowerCase()) ||
        (a.employeeCode?.toLowerCase() || '').includes(appliedDailyFilters.keyword.toLowerCase());

      const matchDept = !allowDeptFilter || appliedDailyFilters.dept === 'ALL' || a.department === appliedDailyFilters.dept;
      const matchStatus = appliedDailyFilters.status === 'ALL' || a.status === appliedDailyFilters.status;
      const matchStart = !appliedDailyFilters.startDate || a.workDate >= appliedDailyFilters.startDate;
      const matchEnd = !appliedDailyFilters.endDate || a.workDate <= appliedDailyFilters.endDate;

      return matchKeyword && matchDept && matchStatus && matchStart && matchEnd;
    });
  };

  // ponytail: trang cá nhân chỉ xem của mình — không có bảng phòng ban / toàn cty / tổng hợp công
  const myAttendances = applyDailyFilter(dailyRecords.filter(a => !a.userId || a.userId === currentUser?.userId));

  const handleOpenEdit = (record: AttendanceRecord) => {
    setEditingRecord(record);
    setEditForm({
      clockInTime: record.clockInTime || '08:30:00',
      clockOutTime: record.clockOutTime || '17:30:00',
      status: record.status,
      reason: record.editedReason || 'Lỗi thiết bị nhận diện khuôn mặt'
    });
  };

  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingRecord) return;
    if (!editingRecord.attendanceId) {
      showToast('Bản ghi này không có ID, không thể điều chỉnh', 'error');
      return;
    }
    try {
      await attendanceService.editAttendance(editingRecord.attendanceId, {
        clockInTime: editForm.clockInTime,
        clockOutTime: editForm.clockOutTime,
        status: editForm.status,
        reason: editForm.reason
      });
      setEditingRecord(null);
      showToast(`Đã cập nhật bản ghi chấm công cho ${editingRecord.userName}`);
      fetchDaily();
    } catch (err: any) {
      showToast('Lỗi điều chỉnh: ' + (err.message || 'Không thể cập nhật'), 'error');
    }
  };

  // ponytail: trang cá nhân chỉ xuất excel chấm công của mình
  const handleExportExcel = async () => {
    try {
      await attendanceService.exportAttendances({
        startDate: appliedDailyFilters.startDate,
        endDate: appliedDailyFilters.endDate,
        status: appliedDailyFilters.status !== 'ALL' ? appliedDailyFilters.status : undefined,
        keyword: appliedDailyFilters.keyword || undefined
      });
      showToast('Đã tải xuống file báo cáo Excel thành công!');
    } catch (err: any) {
      showToast('Lỗi xuất Excel: ' + (err.message || 'Không thể tải file'), 'error');
    }
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
      case 'PAID_LEAVE':
        return <span className="inline-flex items-center gap-1 rounded-full bg-indigo-100 text-indigo-800 px-2.5 py-0.5 text-[11px] font-bold">Nghỉ Phép (Có Lương)</span>;
      case 'UNPAID_LEAVE':
        return <span className="inline-flex items-center gap-1 rounded-full bg-slate-200 text-slate-700 px-2.5 py-0.5 text-[11px] font-bold">Nghỉ Không Lương</span>;
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
          <div className={`fixed top-20 right-6 z-50 rounded-2xl text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold animate-in slide-in-from-top-4 ${toastType === 'error' ? 'bg-rose-600' : 'bg-emerald-600'}`}>
            {toastType === 'error' ? <AlertCircle className="h-5 w-5" /> : <CheckCircle2 className="h-5 w-5" />}
            <span>{toastMsg}</span>
          </div>
        )}

        {/* ponytail: bỏ banner cam — mỗi trang con đã có tiêu đề riêng, nút về /home nằm trên Navbar */}

        {/* ponytail: điều hướng tab đã chuyển lên sidebar (/overview, /daily, /schedule) */}

        {/* Tab Content: Overview cá nhân */}
        {tab === 'overview' && (
          <MyOverviewTab />
        )}

        {/* Tab Content: Shifts */}
        {tab === 'schedule' && (
          <WorkShiftTab />
        )}

        {/* ponytail: bỏ pill chuyển scope — trang cá nhân chỉ xem của mình */}

        {/* Unified Daily Filter Bar matching AttendanceFilterRequest */}
        {tab === 'daily' && (
          <form ref={dailyFormRef} onSubmit={handleApplyDailyFilters} className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
                <Filter className="h-4 w-4 text-blue-600" />
                <span>Bộ lọc điểm danh hàng ngày</span>
              </div>
              <div className="flex items-center gap-2">
                {(appliedDailyFilters.startDate || appliedDailyFilters.endDate || appliedDailyFilters.status !== 'ALL' || appliedDailyFilters.keyword || appliedDailyFilters.dept !== 'ALL') && (
                  <button
                    type="button"
                    onClick={handleResetDailyFilters}
                    className="text-xs text-blue-600 hover:text-blue-800 font-semibold cursor-pointer"
                  >
                    Xóa bộ lọc
                  </button>
                )}
                <button
                  type="button"
                  onClick={() => handleExportExcel()}
                  className="flex items-center gap-1 px-3 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-xs font-bold shadow-xs transition cursor-pointer"
                >
                  <Download className="h-3.5 w-3.5" />
                  <span>Xuất Excel</span>
                </button>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2 text-xs">
              <span className="text-[11px] font-medium text-slate-500">Xem nhanh:</span>
              {DATE_PRESETS.map(([k, label]) => (
                <button
                  key={k}
                  type="button"
                  onClick={() => applyDatePreset(k)}
                  className="px-3 py-1 rounded-full border border-slate-200 text-slate-600 hover:bg-blue-50 hover:text-blue-700 hover:border-blue-300 font-semibold transition cursor-pointer"
                >
                  {label}
                </button>
              ))}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 text-xs">
              <div className="sm:col-span-3">
                <label className="block text-[11px] font-medium text-slate-500 mb-1">Từ ngày</label>
                <input
                  type="date"
                  name="startDate"
                  defaultValue={appliedDailyFilters.startDate}
                  className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden font-mono"
                />
              </div>

              <div className="sm:col-span-3">
                <label className="block text-[11px] font-medium text-slate-500 mb-1">Đến ngày</label>
                <input
                  type="date"
                  name="endDate"
                  defaultValue={appliedDailyFilters.endDate}
                  className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden font-mono"
                />
              </div>

              <div className="sm:col-span-3">
                <label className="block text-[11px] font-medium text-slate-500 mb-1">Trạng thái chấm công</label>
                <select
                  name="status"
                  defaultValue="ALL"
                  className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
                >
                  <option value="ALL">Tất cả trạng thái</option>
                  <option value="NOT_CHECKED">Chưa điểm danh</option>
                  <option value="WORKING">Đang làm việc</option>
                  <option value="SUFFICIENT">Đúng giờ</option>
                  <option value="LATE">Đi trễ</option>
                  <option value="EARLY">Về sớm</option>
                  <option value="LATE_AND_EARLY">Đi trễ & Về sớm</option>
                  <option value="MISSING">Quên chấm công</option>
                  <option value="UNEXCUSED_ABSENCE">Nghỉ không phép</option>
                  <option value="PAID_LEAVE">Nghỉ phép có lương</option>
                  <option value="UNPAID_LEAVE">Nghỉ không lương</option>
                  <option value="HOLIDAY">Nghỉ Lễ</option>
                  <option value="BUSINESS_TRIP">Đi công tác</option>
                  <option value="ADJUSTED">Đã điều chỉnh</option>
                </select>
              </div>

              <div className="sm:col-span-3">
                <label className="block text-[11px] font-medium text-slate-500 mb-1">
                  Tìm kiếm
                </label>
                <div className="relative">
                  <Search className="h-4 w-4 text-slate-400 absolute left-2.5 top-2.5" />
                  <input
                    type="text"
                    name="keyword"
                    placeholder="Tìm ghi chú, mã..."
                    className="w-full rounded-xl border border-slate-200 py-2 pl-8 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                  />
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                type="button"
                onClick={handleResetDailyFilters}
                className="px-3.5 py-1.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-xs font-semibold transition cursor-pointer"
              >
                Đặt lại
              </button>
              <button
                type="submit"
                className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-xs transition cursor-pointer"
              >
                <Search className="h-3.5 w-3.5" />
                <span>Tìm kiếm & Lọc</span>
              </button>
            </div>
          </form>
        )}


        {tab === 'daily' && isDailyLoading && (
          <div className="rounded-2xl bg-blue-50 border border-blue-200 px-4 py-2.5 text-xs font-semibold text-blue-700 flex items-center gap-2">
            <span className="h-3.5 w-3.5 rounded-full border-2 border-blue-600 border-t-transparent animate-spin" />
            <span>Đang tải dữ liệu chấm công từ máy chủ...</span>
          </div>
        )}

        {/* Tab 1: Chấm công cá nhân */}
        {tab === 'daily' && (
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
                      <th className="py-3 px-4">Ghi chú / Điều chỉnh</th>
                      {(isHR || isExecutive) && (
                        <th className="py-3 px-4 text-right">Thao tác</th>
                      )}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {myAttendances.length === 0 && (
                      <tr><td colSpan={6} className="py-8 text-center text-xs text-slate-400">Không có bản ghi chấm công trong khoảng thời gian này.</td></tr>
                    )}
                    {myAttendances.map((record, idx) => (
                      <tr key={record.attendanceId || `${record.workDate}-${record.clockInTime || idx}`} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4 font-bold text-slate-900 font-mono">
                          {formatDateVN(record.workDate)}
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
                        <td className="py-3 px-4 text-slate-500 text-[11px]">
                          {record.isEdited ? (
                            <span className="text-cyan-700 font-medium">
                              Sửa bởi {record.editorName || 'HR'}: {record.editedReason || 'Đã điều chỉnh'}
                            </span>
                          ) : (
                            <span className="text-slate-400">—</span>
                          )}
                        </td>
                        {(isHR || isExecutive) && (
                          <td className="py-3 px-4 text-right">
                            {record.attendanceId ? (
                              <button
                                onClick={() => handleOpenEdit(record)}
                                className="p-1.5 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition cursor-pointer"
                                title="Sửa bản ghi chấm công"
                              >
                                <Edit3 className="h-3.5 w-3.5" />
                              </button>
                            ) : (
                              <span className="text-slate-300" title="Bản ghi xem nhanh, sửa ở tab Toàn công ty">—</span>
                            )}
                          </td>
                        )}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ponytail: trang cá nhân không có bảng phòng ban / toàn cty / tổng hợp công / quản lý đơn */}

        {/* Modal Sửa Bản Ghi Chấm Công (Dành riêng cho HR - EditAttendanceRequest) */}
        {editingRecord && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-lg rounded-3xl bg-white p-6 shadow-2xl border border-slate-200">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2 text-blue-600 font-bold text-sm">
                  <Edit3 className="h-4 w-4" />
                  <span>Điều chỉnh giờ công</span>
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
                    {editingRecord.userName} ({editingRecord.employeeCode}) - Ngày {formatDateVN(editingRecord.workDate)}
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
                    <option value="SUFFICIENT">Đúng giờ</option>
                    <option value="LATE">Đi trễ</option>
                    <option value="EARLY">Về sớm</option>
                    <option value="ADJUSTED">Đã điều chỉnh</option>
                    <option value="PAID_LEAVE">Nghỉ phép có lương</option>
                    <option value="UNPAID_LEAVE">Nghỉ không lương</option>
                    <option value="BUSINESS_TRIP">Công tác</option>
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
      </div>
    </AppShell>
  );
}
