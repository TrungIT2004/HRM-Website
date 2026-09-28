'use client';

import React, { useState, useRef, useEffect } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { AttendanceRecord, AttendanceStatus, MonthlyTimesheetSummary } from '@/types';
import { attendanceService } from '@/services/attendanceService';
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
  Pencil,
  UserCheck
} from 'lucide-react';
import { formatDateVN } from '@/utils/format';
import ConfirmDialog from '@/components/ConfirmDialog';
import { DATE_PRESETS, DatePreset, dateRangeFor, fillDateInputs } from '@/utils/dateRange';
import { useTabFromUrl } from '@/utils/useTabFromUrl';
import { DEPARTMENTS } from '@/constants/departments';

export default function AttendancePage() {
  const { currentUser, isHR, isManager, isExecutive, can, isLoading: isAuthLoading } = useAuth();
  const { attendances } = useHRMData(); // ponytail: mock fallback khi API lỗi

  // Tab State: 'my' (Cá nhân) | 'dept' (Phòng ban) | 'company' (Toàn cty) | 'summary' (Tổng hợp công)
  const [activeTab, setActiveTab] = useTabFromUrl(['my', 'dept', 'company', 'summary'] as const, 'my');

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

  const fetchDaily = async (tab: typeof activeTab = activeTab, f = appliedDailyFilters) => {
    if (tab === 'summary') return;
    setIsDailyLoading(true);
    try {
      const params = {
        startDate: f.startDate || undefined,
        endDate: f.endDate || undefined,
        status: f.status !== 'ALL' ? f.status : undefined,
        keyword: f.keyword || undefined,
        departmentNames: tab === 'company' && f.dept !== 'ALL' ? [f.dept] : undefined,
        size: 200
      };
      const res = tab === 'my'
        ? await attendanceService.getMyAttendances(params)
        : tab === 'dept'
          ? await attendanceService.getDepartmentAttendances(params)
          : await attendanceService.getCompanyAttendances(params);
      setDailyRecords(Array.isArray(res?.content) ? res.content : []);
    } catch {
      setDailyRecords(attendances);
    } finally {
      setIsDailyLoading(false);
    }
  };

  useEffect(() => {
    fetchDaily();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, appliedDailyFilters, currentUser?.userId]);

  const syncDailyFormDates = (r: { startDate: string; endDate: string }) => {
    fillDateInputs(dailyFormRef.current, r);
  };

  const handleTabChange = (tab: typeof activeTab) => {
    setActiveTab(tab);
    const d = defaultDatesFor(tab);
    setAppliedDailyFilters(prev => ({ ...prev, ...d }));
    syncDailyFormDates(d);
  };

  // Monthly summary filter form ref
  const summaryFormRef = useRef<HTMLFormElement>(null);
  const currentDate = new Date();
  const [appliedSummaryFilters, setAppliedSummaryFilters] = useState({
    month: currentDate.getMonth() + 1,
    year: currentDate.getFullYear(),
    dept: 'ALL',
    keyword: ''
  });

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
    const d = defaultDatesFor(activeTab);
    setAppliedDailyFilters({ ...d, status: 'ALL', keyword: '', dept: 'ALL' });
    dailyFormRef.current?.reset();
    syncDailyFormDates(d);
  };

  const handleApplySummaryFilters = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const fd = new FormData(summaryFormRef.current!);
    setAppliedSummaryFilters({
      month: Number(fd.get('month')) || currentDate.getMonth() + 1,
      year: Number(fd.get('year')) || currentDate.getFullYear(),
      dept: fd.get('dept') as string || 'ALL',
      keyword: fd.get('keyword') as string || ''
    });
  };

  const handleResetSummaryFilters = () => {
    summaryFormRef.current?.reset();
    setAppliedSummaryFilters({ month: currentDate.getMonth() + 1, year: currentDate.getFullYear(), dept: 'ALL', keyword: '' });
  };

  const [editingRecord, setEditingRecord] = useState<AttendanceRecord | null>(null);
  // Bảng công tháng đang sửa (chỉ dòng Nháp mới sửa được).
  const [editingSheet, setEditingSheet] = useState<MonthlyTimesheetSummary | null>(null);
  const [sheetForm, setSheetForm] = useState({
    actualWorkedDays: '', actualWorkHours: '', totalActualOtHours: '', totalPaidOtHours: '',
    paidLeaveDays: '', unpaidLeaveDays: '', lateCount: '', earlyDepartureCount: '', absentDays: '', note: ''
  });
  const [savingSheet, setSavingSheet] = useState(false);

  // Dòng trên bảng đã mang đủ id + số liệu (mapTimesheetItem giữ timesheetId) nên
  // không cần gọi lại API tổng hợp — trước đây fetch lại rồi tìm theo userId nên luôn
  // rơi vào timesheetId = undefined và báo "Không tìm thấy bảng công để chỉnh sửa".
  const openEditSheet = (s: MonthlyTimesheetSummary) => {
    if (!s.timesheetId) { showToast('Bản ghi bảng công này thiếu mã — tải lại trang rồi thử lại', 'error'); return; }
    setEditingSheet(s);
    setSheetForm({
      actualWorkedDays: String(s.actualWorkedDays ?? 0),
      actualWorkHours: String(s.totalActualHours ?? 0),
      totalActualOtHours: String(s.overtimeHours ?? 0),
      totalPaidOtHours: String(s.totalPaidHours ?? 0),
      paidLeaveDays: String(s.paidLeaveDays ?? 0),
      unpaidLeaveDays: String(s.unpaidLeaveDays ?? 0),
      lateCount: String(s.lateCount ?? 0),
      earlyDepartureCount: String(s.earlyDepartureCount ?? 0),
      absentDays: String(s.absentDays ?? 0),
      note: s.note || ''
    });
  };

  const handleSaveSheet = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingSheet?.timesheetId) return;
    setSavingSheet(true);
    try {
      await attendanceService.editMonthlyTimesheet(editingSheet.timesheetId, {
        actualWorkedDays: Number(sheetForm.actualWorkedDays) || 0,
        actualWorkHours: Number(sheetForm.actualWorkHours) || 0,
        totalActualOtHours: Number(sheetForm.totalActualOtHours) || 0,
        totalPaidOtHours: Number(sheetForm.totalPaidOtHours) || 0,
        paidLeaveDays: Number(sheetForm.paidLeaveDays) || 0,
        unpaidLeaveDays: Number(sheetForm.unpaidLeaveDays) || 0,
        lateCount: Number(sheetForm.lateCount) || 0,
        earlyDepartureCount: Number(sheetForm.earlyDepartureCount) || 0,
        absentDays: Number(sheetForm.absentDays) || 0,
        note: sheetForm.note
      });
      showToast(`Đã cập nhật bảng công của ${editingSheet.fullName}!`);
      setEditingSheet(null);
      setSummaryRefreshKey(k => k + 1);
    } catch (err: any) {
      showToast('Lỗi cập nhật: ' + (err.response?.data?.msg || err.message || 'Không lưu được'), 'error');
    } finally {
      setSavingSheet(false);
    }
  };
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



  // Reset tab if role switches and tab is no longer permitted
  useEffect(() => {
    // ponytail: chờ isAuthLoading — xem giải thích ở leave/page.tsx (reset tab khi chưa có profile)
    if (isAuthLoading) return;
    if (!isHR && !isExecutive && !can('ATTENDANCE_VIEW_ALL') && activeTab === 'company') {
      handleTabChange('my');
    }
    if (!isManager && !isExecutive && activeTab === 'dept') {
      handleTabChange('my');
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthLoading, isHR, isManager, isExecutive, can, activeTab]);

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

  // 1. Chấm công cá nhân (Ai cũng xem được của mình)
  const myAttendances = applyDailyFilter((activeTab === 'my' ? dailyRecords : attendances).filter(a => !a.userId || a.userId === currentUser?.userId));

  // 2. Chấm công phòng ban (Chỉ Trưởng phòng & Ban Giám Đốc)
  const deptAttendances = applyDailyFilter((activeTab === 'dept' ? dailyRecords : attendances).filter(a => {
    if (isExecutive) return true;
    return a.department === currentUser?.department;
  }));

  // 3. Chấm công toàn công ty (Chỉ HR & Ban Giám Đốc)
  const companyAttendances = applyDailyFilter(activeTab === 'company' ? dailyRecords : attendances, true);

  // 4. Dữ liệu Tổng Hợp Công Tháng kết nối trực tiếp API Backend
  const [monthlySummaries, setMonthlySummaries] = React.useState<MonthlyTimesheetSummary[]>([]);
  const [isSummaryLoading, setIsSummaryLoading] = React.useState(false);
  // Vùng chọn trên bảng tổng hợp: rỗng = chốt/tính cả tháng, có phần tử = chỉ những dòng đã tick.
  const [selectedSummaryIds, setSelectedSummaryIds] = React.useState<string[]>([]);
  // Tăng sau khi chốt sổ để useEffect nạp lại bảng tổng hợp (tránh copy logic fetch ra ngoài).
  const [summaryRefreshKey, setSummaryRefreshKey] = React.useState(0);

  React.useEffect(() => {
    if (activeTab !== 'summary') return;
    const fetchSummaries = async () => {
      setIsSummaryLoading(true);
      try {
        const params = {
          month: Number(appliedSummaryFilters.month),
          year: Number(appliedSummaryFilters.year),
          size: 100
        };
        let res;
        if (isHR || isExecutive || can('ATTENDANCE_VIEW_ALL')) {
          res = await attendanceService.getCompanyMonthlySummary(params);
        } else if (isManager) {
          res = await attendanceService.getDepartmentMonthlySummary(params);
        } else {
          res = await attendanceService.getMyMonthlySummary(params);
        }
        if (res && res.content) {
          setMonthlySummaries(res.content);
        }
      } catch {
        setMonthlySummaries([]);
      } finally {
        setIsSummaryLoading(false);
      }
    };
    fetchSummaries();
  }, [activeTab, appliedSummaryFilters.month, appliedSummaryFilters.year, summaryRefreshKey, isHR, isExecutive, isManager]);

  // UUID từ token (profile) và từ response có thể lệch hoa/thường → so sánh đã chuẩn hoá,
  // không so thẳng `===` (lỗi này làm dòng của chính mình không được đẩy lên đầu / không tô màu).
  const selfId = (currentUser?.userId || '').trim().toLowerCase();
  const isSelf = (id?: string) => !!selfId && (id || '').trim().toLowerCase() === selfId;

  const visibleMonthlySummaries: MonthlyTimesheetSummary[] = monthlySummaries.filter(s => {
    const matchK = !appliedSummaryFilters.keyword || ((s.fullName || '')?.toLowerCase() || '').includes(appliedSummaryFilters.keyword.toLowerCase()) || ((s.employeeCode || '').toLowerCase() || '').includes(appliedSummaryFilters.keyword.toLowerCase());
    const matchD = appliedSummaryFilters.dept === 'ALL' || s.department === appliedSummaryFilters.dept;
    const matchM = s.month === Number(appliedSummaryFilters.month);
    const matchY = s.year === Number(appliedSummaryFilters.year);
    return matchK && matchD && matchM && matchY;
  // Dòng của chính mình đẩy lên đầu bảng.
  // ponytail: sort ở client (1 kỳ ~16 dòng, đã fetch size=100). > 1 trang thì chuyển sort xuống tầng DB.
  }).sort((a, b) => Number(isSelf(b.userId)) - Number(isSelf(a.userId)));

  // KHÔNG fallback sang bản ghi khác: `|| monthlySummaries[0]` khiến nhân viên không có
  // dữ liệu kỳ đó thấy số giờ của đồng nghiệp như của chính mình.
  const myMonthlySummary: MonthlyTimesheetSummary | undefined = monthlySummaries.find(
    s => isSelf(s.userId)
  );

  // Chỉ những dòng còn Nháp mới chọn được — đã chốt thì không tick lại.
  const selectableIds: string[] = visibleMonthlySummaries
    .filter(s => s.status !== 'LOCKED')
    .map(s => s.userId);
  const selectedVisibleCount = selectableIds.filter(id => selectedSummaryIds.includes(id)).length;

  // Kỳ chưa kết thúc (tháng hiện tại hoặc tương lai) thì khoá toàn bộ chuỗi chốt — chỉ
  // chốt được kỳ đã qua. Ví dụ hôm 27/09 thì tháng 09 vẫn đang chạy, chỉ chốt được từ 10/01 trở đi.
  const now = new Date();
  const isOpenPeriod =
    appliedSummaryFilters.year > now.getFullYear()
    || (appliedSummaryFilters.year === now.getFullYear()
      && appliedSummaryFilters.month >= now.getMonth() + 1);
  // Chưa bấm "Tính toán công tháng" thì không có gì để chốt.
  const hasSummaryData = monthlySummaries.length > 0;

  // ponytail: tháng chốt khi mọi dòng đã LOCKED (backend khóa theo từng nhân viên, không có flag cấp tháng)
  const isSummaryLocked = monthlySummaries.length > 0 && monthlySummaries.every(s => s.status === 'LOCKED');

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

  const handleDelete = async (attendanceId?: string) => {
    if (!attendanceId) {
      showToast('Bản ghi này không có ID, không thể xóa', 'error');
      return;
    }
    if (!confirm('Xóa vĩnh viễn bản ghi chấm công này?')) return;
    try {
      await attendanceService.deleteAttendance(attendanceId);
      showToast('Đã xóa bản ghi chấm công');
      fetchDaily();
    } catch (err: any) {
      showToast('Lỗi xóa: ' + (err.message || 'Không thể xóa'), 'error');
    }
  };

  const handleExportExcel = async (type: 'daily' | 'monthly') => {
    try {
      if (type === 'daily') {
        await attendanceService.exportAttendances({
          startDate: appliedDailyFilters.startDate,
          endDate: appliedDailyFilters.endDate,
          status: appliedDailyFilters.status !== 'ALL' ? appliedDailyFilters.status : undefined,
          keyword: appliedDailyFilters.keyword || undefined
        });
      } else {
        await attendanceService.exportCompanyMonthlySummary({
          month: appliedSummaryFilters.month,
          year: appliedSummaryFilters.year,
          keyword: appliedSummaryFilters.keyword || undefined
        });
      }
      showToast('Đã tải xuống file báo cáo Excel thành công!');
    } catch (err: any) {
      showToast('Lỗi xuất Excel: ' + (err.message || 'Không thể tải file'), 'error');
    }
  };

  const handleCalculateSummary = async () => {
    try {
      const res: any = await attendanceService.generateMonthlySummary(appliedSummaryFilters.month, appliedSummaryFilters.year);
      showToast(res?.msg || `Đã tính toán bảng công tháng ${appliedSummaryFilters.month}/${appliedSummaryFilters.year} thành công!`);
      // Tải lại bảng sau khi tính
      const params = { month: Number(appliedSummaryFilters.month), year: Number(appliedSummaryFilters.year), size: 100 };
      try {
        const list = (isHR || isExecutive || can('ATTENDANCE_VIEW_ALL'))
          ? await attendanceService.getCompanyMonthlySummary(params)
          : await attendanceService.getDepartmentMonthlySummary(params);
        if (list?.content) setMonthlySummaries(list.content);
      } catch { /* giữ dữ liệu cũ */ }
    } catch (err: any) {
      showToast('Lỗi tính công: ' + (err.message || 'Không thể tính toán'), 'error');
    }
  };

  const toggleSummaryRow = (userId: string) => {
    setSelectedSummaryIds(prev =>
      prev.includes(userId) ? prev.filter(id => id !== userId) : [...prev, userId]);
  };

  const toggleAllSummaryRows = (ids: string[]) => {
    setSelectedSummaryIds(prev => (ids.every(id => prev.includes(id)) ? [] : ids));
  };

  // Chốt sổ là hành động không hoàn tác (backend khoá từng bảng công) → hỏi lại trước.
  const [lockConfirm, setLockConfirm] = useState(false);
  const [lockingSheet, setLockingSheet] = useState(false);

  const handleLockTimesheet = async () => {
    const n = selectedSummaryIds.length;
    setLockConfirm(true);
    try {
      setLockingSheet(true);
      const res: any = await attendanceService.lockMonthlySummary(
        appliedSummaryFilters.month, appliedSummaryFilters.year, selectedSummaryIds);
      showToast(res?.msg || (n > 0
        ? `Đã chốt ${n} bảng công đã chọn!`
        : `Đã chốt sổ bảng công tháng ${appliedSummaryFilters.month}/${appliedSummaryFilters.year}!`));
      setSelectedSummaryIds([]);
      setSummaryRefreshKey(k => k + 1);
    } catch (err: any) {
      showToast('Lỗi chốt công: ' + (err.response?.data?.msg || err.message || 'Không thể chốt sổ'), 'error');
    } finally {
      setLockingSheet(false);
      setLockConfirm(false);
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
              Theo dõi giờ vào/ra, điểm danh ca kíp, phê duyệt và xuất báo cáo công tháng.
            </p>
          </div>
        </div>

        {/* Navigation Tabs with Strict Role Badges */}
        <div className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-xs font-bold">
          {/* Tab 1: Mọi nhân viên */}
          <button
            onClick={() => handleTabChange('my')}
            className={`px-4 py-2 rounded-xl transition cursor-pointer ${
              activeTab === 'my' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            Chấm công của tôi ({myAttendances.length})
          </button>

          {/* Tab 2: Trưởng phòng & BGĐ */}
          {(isManager || isExecutive) && (
            <button
              onClick={() => handleTabChange('dept')}
              className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'dept' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
              }`}
            >
              <span>Phòng {currentUser?.department}</span>
              <span className="text-[10px] font-normal opacity-80">({deptAttendances.length})</span>
            </button>
          )}

          {/* Tab 3: HR, BGĐ & người được cấp quyền */}
          {(isHR || isExecutive || can('ATTENDANCE_VIEW_ALL')) && (
            <button
              onClick={() => handleTabChange('company')}
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
            onClick={() => handleTabChange('summary')}
            className={`px-4 py-2 rounded-xl transition cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'summary' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            {isHR || isExecutive || can('ATTENDANCE_VIEW_ALL') ? (
              <span>Tổng hợp công toàn công ty</span>
            ) : isManager ? (
              <span>Tổng hợp công phòng {currentUser?.department}</span>
            ) : (
              <span>Tổng hợp công tháng của tôi</span>
            )}
          </button>
        </div>

        {/* Unified Daily Filter Bar matching AttendanceFilterRequest */}
        {activeTab !== 'summary' && (
          <form ref={dailyFormRef} onSubmit={handleApplyDailyFilters} className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
                <Filter className="h-4 w-4 text-blue-600" />
                <span>Bộ lọc điểm danh hàng ngày</span>
              </div>
              {(appliedDailyFilters.startDate || appliedDailyFilters.endDate || appliedDailyFilters.status !== 'ALL' || appliedDailyFilters.keyword || appliedDailyFilters.dept !== 'ALL') && (
                <button
                  type="button"
                  onClick={handleResetDailyFilters}
                  className="text-xs text-blue-600 hover:text-blue-800 font-semibold cursor-pointer"
                >
                  Xóa bộ lọc
                </button>
              )}
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
                  {activeTab === 'company' ? 'Phòng ban' : 'Tìm kiếm'}
                </label>
                {activeTab === 'company' ? (
                  <select
                    name="dept"
                    defaultValue="ALL"
                    className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
                  >
                    <option value="ALL">Tất cả phòng ban</option>
                    {DEPARTMENTS.map(d => (
                      <option key={d.dbName} value={d.dbName}>{d.label}</option>
                    ))}
                  </select>
                ) : (
                  <div className="relative">
                    <Search className="h-4 w-4 text-slate-400 absolute left-2.5 top-2.5" />
                    <input
                      type="text"
                      name="keyword"
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
                      name="keyword"
                      placeholder="Tìm kiếm theo tên nhân viên, mã nhân viên..."
                      className="w-full rounded-xl border border-slate-200 py-2 pl-9 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>
              )}
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


        {activeTab !== 'summary' && isDailyLoading && (
          <div className="rounded-2xl bg-blue-50 border border-blue-200 px-4 py-2.5 text-xs font-semibold text-blue-700 flex items-center gap-2">
            <span className="h-3.5 w-3.5 rounded-full border-2 border-blue-600 border-t-transparent animate-spin" />
            <span>Đang tải dữ liệu chấm công từ máy chủ...</span>
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
                      <th className="py-3 px-4">Mã NV</th>
                      <th className="py-3 px-4">Họ tên</th>
                      <th className="py-3 px-4">Vị trí</th>
                      <th className="py-3 px-4">Ngày</th>
                      <th className="py-3 px-4">Giờ Vào</th>
                      <th className="py-3 px-4">Giờ Ra</th>
                      <th className="py-3 px-4">Trạng thái</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {deptAttendances.length === 0 && (
                      <tr><td colSpan={7} className="py-8 text-center text-xs text-slate-400">Không có bản ghi chấm công trong khoảng thời gian này.</td></tr>
                    )}
                    {deptAttendances.map(record => (
                      <tr key={record.attendanceId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4 font-mono text-[11px] text-slate-500">{record.employeeCode}</td>
                        <td className="py-3 px-4 font-bold text-slate-900">{record.userName}</td>
                        <td className="py-3 px-4 text-slate-600">{record.job || '—'}</td>
                        <td className="py-3 px-4 font-mono font-medium">{formatDateVN(record.workDate)}</td>
                        <td className="py-3 px-4 font-mono font-bold text-slate-800">{record.clockInTime || '—'}</td>
                        <td className="py-3 px-4 font-mono font-bold text-slate-800">{record.clockOutTime || '—'}</td>
                        <td className="py-3 px-4">{statusBadge(record.status)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Tab 3: Chấm công Toàn công ty (Chỉ HR & Ban Giám Đốc) */}
        {activeTab === 'company' && (isHR || isExecutive || can('ATTENDANCE_VIEW_ALL')) && (
          <div className="space-y-4">
            {/* Table */}
            <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3 px-4">Mã NV</th>
                      <th className="py-3 px-4">Họ tên</th>
                      <th className="py-3 px-4">Phòng ban</th>
                      <th className="py-3 px-4">Ngày</th>
                      <th className="py-3 px-4">Vào / Ra</th>
                      <th className="py-3 px-4">Trạng thái</th>
                      <th className="py-3 px-4 text-right">Quyền HR</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 text-slate-700">
                    {companyAttendances.length === 0 && (
                      <tr><td colSpan={7} className="py-8 text-center text-xs text-slate-400">Không có bản ghi chấm công trong khoảng thời gian này.</td></tr>
                    )}
                    {companyAttendances.map(record => (
                      <tr key={record.attendanceId} className="hover:bg-slate-50/80 transition">
                        <td className="py-3 px-4 font-mono text-[11px] text-slate-500">{record.employeeCode}</td>
                        <td className="py-3 px-4 font-bold text-slate-900">{record.userName}</td>
                        <td className="py-3 px-4 text-slate-600">{record.department}</td>
                        <td className="py-3 px-4 font-mono font-medium">{formatDateVN(record.workDate)}</td>
                        <td className="py-3 px-4 font-mono">
                          <span className="font-bold text-slate-800">{record.clockInTime || '—'}</span>
                          <span className="text-slate-400 mx-1">→</span>
                          <span className="font-bold text-slate-800">{record.clockOutTime || '—'}</span>
                        </td>
                        <td className="py-3 px-4">{statusBadge(record.status)}</td>
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
                              onClick={() => handleDelete(record.attendanceId)}
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
            {/* Monthly Timesheet Filter Toolbar */}
            <form ref={summaryFormRef} onSubmit={handleApplySummaryFilters} className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-xs font-bold text-slate-800">
                  <FileSpreadsheet className="h-4 w-4 text-emerald-600" />
                  <span>Bộ lọc bảng tổng hợp công tháng</span>
                </div>
                {(appliedSummaryFilters.dept !== 'ALL' || appliedSummaryFilters.keyword) && (
                  <button
                    type="button"
                    onClick={handleResetSummaryFilters}
                    className="text-xs text-blue-600 hover:text-blue-800 font-semibold cursor-pointer"
                  >
                    Đặt lại
                  </button>
                )}
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 text-xs">
                <div className="sm:col-span-3">
                  <label className="block text-[11px] font-medium text-slate-500 mb-1">Tháng làm việc</label>
                  <select
                    name="month"
                    defaultValue={currentDate.getMonth() + 1}
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
                    name="year"
                    defaultValue={currentDate.getFullYear()}
                    className="w-full rounded-xl border border-slate-200 p-2 text-xs text-slate-800 bg-white focus:border-blue-600 focus:outline-hidden"
                  >
                    <option value={2025}>Năm 2025</option>
                    <option value={2026}>Năm 2026</option>
                  </select>
                </div>

                {(isHR || isExecutive || can('ATTENDANCE_VIEW_ALL')) && (
                  <div className="sm:col-span-3">
                    <label className="block text-[11px] font-medium text-slate-500 mb-1">Phòng ban</label>
                    <select
                      name="dept"
                      defaultValue="ALL"
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
                        name="keyword"
                        placeholder="Tìm theo tên, mã NV..."
                        className="w-full rounded-xl border border-slate-200 py-2 pl-8 pr-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-hidden"
                      />
                    </div>
                  </div>
                )}
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                <button
                  type="button"
                  onClick={handleResetSummaryFilters}
                  className="px-3.5 py-1.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-xs font-semibold transition cursor-pointer"
                >
                  Đặt lại
                </button>
                <button
                  type="submit"
                  className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-xs transition cursor-pointer"
                >
                  <Search className="h-3.5 w-3.5" />
                  <span>Tra cứu bảng công</span>
                </button>
              </div>
            </form>


            {/* Nếu là Nhân Viên Thường: Xem Thẻ Chi Tiết Đầy Đủ 11 Chỉ Số của chính mình */}
            {!isManager && !isHR && !isExecutive && (
              myMonthlySummary ? (
                <div className="rounded-3xl bg-white p-6 sm:p-8 border border-slate-200 shadow-sm max-w-4xl mx-auto space-y-6">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-slate-100 gap-3">
                    <div>
                      <span className="text-[11px] font-bold text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full border border-blue-200">
                        Bảng Công Cá Nhân Tháng {appliedSummaryFilters.month < 10 ? `0${appliedSummaryFilters.month}` : appliedSummaryFilters.month}/{appliedSummaryFilters.year}
                      </span>
                      <h2 className="text-xl font-black text-slate-900 mt-2">{myMonthlySummary.fullName || currentUser?.fullName}</h2>
                      <p className="text-xs text-slate-500">{(myMonthlySummary.employeeCode || currentUser?.employeeCode)} • {(myMonthlySummary.job || currentUser?.job)} • {(myMonthlySummary.department || currentUser?.department)}</p>
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
                  Không tìm thấy bản ghi tổng hợp công cho Tháng {appliedSummaryFilters.month}/{appliedSummaryFilters.year}.
                </div>
              )
            )}

            {/* Nếu là Quản lý / HR / Giám đốc / người được cấp quyền: Xem Bảng Tổng Hợp */}
            {(isManager || isHR || isExecutive || can('ATTENDANCE_VIEW_ALL')) && (
              <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
                <div className="p-4 border-b border-slate-100 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                  <div>
                    <h3 className="text-xs font-bold text-slate-900 flex items-center gap-1.5">
                      <span>Bảng tổng hợp công Tháng {appliedSummaryFilters.month < 10 ? `0${appliedSummaryFilters.month}` : appliedSummaryFilters.month}/{appliedSummaryFilters.year}</span>
                      <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[10px] text-blue-700 font-semibold border border-blue-200">
                        {isHR || isExecutive || can('ATTENDANCE_VIEW_ALL') ? 'Toàn công ty (HR)' : `Phòng ${currentUser?.department}`}
                      </span>
                      {isSummaryLocked && (
                        <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] text-amber-700 font-semibold border border-amber-300">
                          Đã chốt sổ 🔒
                        </span>
                      )}
                    </h3>
                    <p className="text-[11px] text-slate-500">
                      {isHR || isExecutive || can('ATTENDANCE_VIEW_ALL')
                        ? 'Dữ liệu toàn công ty - Hiển thị đủ 11 chỉ số tổng hợp công'
                        : `Chỉ hiển thị các nhân sự thuộc phòng ${currentUser?.department}`}
                    </p>
                  </div>
                  
                  <div className="flex flex-wrap items-center gap-2">
                    {(isHR || isExecutive || can('TIMESHEET_LOCK')) && (
                      <>
                        <button
                          onClick={handleCalculateSummary}
                          disabled={isOpenPeriod || isSummaryLocked}
                          title={isOpenPeriod
                            ? 'Kỳ chưa kết thúc — chỉ tính toán được kỳ đã qua'
                            : isSummaryLocked
                              ? 'Bảng công đã chốt sổ, không thể tính toán lại'
                              : undefined}
                          className="flex items-center gap-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-3 py-1.5 text-xs font-bold transition cursor-pointer shadow-xs"
                        >
                          <Sparkles className="h-3.5 w-3.5" />
                          <span>Tính toán công tháng</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => setLockConfirm(true)}
                          disabled={!hasSummaryData || isSummaryLocked || isOpenPeriod}
                          title={isOpenPeriod
                            ? 'Kỳ chưa kết thúc — chỉ chốt sổ được kỳ đã qua'
                            : !hasSummaryData
                              ? 'Chưa có dữ liệu tổng hợp công — bấm "Tính toán công tháng" trước'
                              : isSummaryLocked
                                ? 'Bảng công đã chốt sổ trước đó'
                                : selectedSummaryIds.length > 0
                                  ? `Chốt ${selectedSummaryIds.length} bảng công đã chọn`
                                  : 'Chốt cả tháng — tick các dòng để chỉ chốt một phần'}
                          className="flex items-center gap-1.5 rounded-xl bg-amber-600 hover:bg-amber-700 disabled:opacity-50 disabled:cursor-not-allowed text-white px-3 py-1.5 text-xs font-bold transition cursor-pointer shadow-xs"
                        >
                          <Lock className="h-3.5 w-3.5" />
                          <span>
                            {selectedSummaryIds.length > 0
                              ? `Chốt ${selectedSummaryIds.length} dòng đã chọn`
                              : 'Chốt sổ bảng công'}
                          </span>
                        </button>
                      </>
                    )}
                    <button
                      onClick={() => handleExportExcel('monthly')}
                      disabled={!hasSummaryData || isOpenPeriod}
                      title={isOpenPeriod
                        ? 'Kỳ chưa kết thúc — chưa có bảng công để xuất'
                        : !hasSummaryData
                          ? 'Chưa có dữ liệu tổng hợp công để xuất'
                          : undefined}
                      className="flex items-center gap-1.5 rounded-xl bg-slate-900 hover:bg-slate-800 disabled:opacity-50 disabled:cursor-not-allowed text-white px-3 py-1.5 text-xs font-bold transition cursor-pointer"
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
                        <th className="py-3 px-3 w-10">
                          <input
                            type="checkbox"
                            aria-label="Chọn tất cả nhân viên đang hiển thị"
                            checked={selectableIds.length > 0 && selectableIds.every(id => selectedSummaryIds.includes(id))}
                            ref={el => { if (el) el.indeterminate = selectableIds.some(id => selectedSummaryIds.includes(id)) && !selectableIds.every(id => selectedSummaryIds.includes(id)); }}
                            onChange={() => toggleAllSummaryRows(selectableIds)}
                            className="w-4 h-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500 cursor-pointer"
                          />
                        </th>
                        <th className="py-3 px-3">Mã NV</th>
                        <th className="py-3 px-3">Họ tên</th>
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
                        <th className="py-3 px-3 text-center" title="monthly_timesheets.status">Trạng Thái</th>
                        <th className="py-3 px-3 text-center">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 text-slate-700">
                      {visibleMonthlySummaries.length === 0 && (
                        <tr><td colSpan={16} className="py-8 text-center text-xs text-slate-400">Chưa có dữ liệu tổng hợp công cho kỳ này. Bấm “Tính toán công tháng” để tổng hợp.</td></tr>
                      )}
                      {visibleMonthlySummaries.map(item => {
                        const isLocked = item.status === 'LOCKED';
                        const checked = selectedSummaryIds.includes(item.userId);
                        const isMe = isSelf(item.userId);
                        return (
                        <tr key={item.userId} className={`transition ${checked ? 'bg-blue-50/70' : isMe ? 'bg-blue-50/50 hover:bg-blue-50/80' : 'hover:bg-slate-50/80'}`}>
                          <td className="py-3 px-3 text-center">
                            <input
                              type="checkbox"
                              aria-label={`Chọn bảng công của ${item.fullName}`}
                              checked={checked}
                              disabled={isLocked}
                              onChange={() => toggleSummaryRow(item.userId)}
                              className="w-4 h-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500 cursor-pointer disabled:cursor-not-allowed disabled:opacity-40"
                            />
                          </td>
                          <td className="py-3 px-3 font-mono text-[11px] text-slate-500">{item.employeeCode}</td>
                          <td className="py-3 px-3 font-bold text-slate-900 whitespace-nowrap">
                            {item.fullName}
                            {isMe && (
                              <span className="ml-1.5 inline-flex align-middle rounded-full bg-blue-600 px-1.5 py-0.5 text-[9px] font-black uppercase tracking-wide text-white">
                                Bạn
                              </span>
                            )}
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
                          <td className="py-3 px-3 text-center">
                            {isLocked ? (
                              <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 text-emerald-800 px-2 py-0.5 text-[10px] font-bold">
                                <Lock className="h-3 w-3" aria-hidden="true" />
                                Đã chốt
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 text-slate-600 px-2 py-0.5 text-[10px] font-bold">
                                <Pencil className="h-3 w-3" aria-hidden="true" />
                                Nháp
                              </span>
                            )}
                          </td>
                          <td className="py-3 px-3 text-center">
                            {(isHR || isExecutive || can('TIMESHEET_LOCK')) && !isLocked ? (
                              <button
                                onClick={() => openEditSheet(item)}
                                aria-label={`Chỉnh sửa bảng công của ${item.fullName}`}
                                title="Chỉnh sửa ngày công / OT / phép"
                                className="inline-flex items-center gap-1 rounded-lg border border-slate-300 px-2 py-1 text-[10px] font-bold text-slate-700 hover:bg-slate-50 transition cursor-pointer whitespace-nowrap"
                              >
                                <Pencil className="w-3 h-3" aria-hidden="true" />
                                Sửa
                              </button>
                            ) : (
                              <span className="text-slate-300 text-[10px]">—</span>
                            )}
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
        )}

        {/* Xác nhận trước khi chốt sổ — không hoàn tác được */}
        <ConfirmDialog
          open={lockConfirm}
          busy={lockingSheet}
          title={`Chốt sổ bảng công tháng ${appliedSummaryFilters.month}/${appliedSummaryFilters.year}?`}
          body={selectedSummaryIds.length > 0
            ? `Chốt ${selectedSummaryIds.length} bảng công đã chọn. Các bảng công đã chốt sẽ bị khoá (LOCKED) và không sửa được nữa.`
            : `Chốt toàn bộ ${visibleMonthlySummaries.length} bảng công trong bảng đang xem. Sau khi chốt sổ, bảng công sẽ bị khoá (LOCKED) và không sửa được nữa.`}
          confirmLabel="Chốt sổ bảng công"
          onClose={() => !lockingSheet && setLockConfirm(false)}
          onConfirm={handleLockTimesheet}
        />

        {/* Modal sửa bảng công tháng (HR / Ban Giám đốc) */}
        {editingSheet && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-2xl rounded-3xl bg-white p-6 shadow-2xl border border-slate-200 max-h-[90vh] overflow-y-auto">
              <button
                onClick={() => setEditingSheet(null)}
                aria-label="Đóng"
                className="absolute right-4 top-4 rounded-full p-1 text-slate-400 hover:bg-slate-100 transition"
              >
                <X className="w-5 h-5" />
              </button>
              <h2 className="text-lg font-black text-slate-900 mb-1">Điều chỉnh bảng công</h2>
              <p className="text-xs text-slate-500 mb-5">
                {editingSheet.fullName} ({editingSheet.employeeCode}) · kỳ {editingSheet.month}/{editingSheet.year}
              </p>

              <form onSubmit={handleSaveSheet} className="space-y-4 text-xs">
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  {[
                    { k: 'actualWorkedDays', l: 'Công thực' },
                    { k: 'actualWorkHours', l: 'Giờ thực làm' },
                    { k: 'absentDays', l: 'Vắng KP' },
                    { k: 'paidLeaveDays', l: 'Phép hưởng lương' },
                    { k: 'unpaidLeaveDays', l: 'Nghỉ không lương' },
                    { k: 'lateCount', l: 'Số lần đi trễ' },
                    { k: 'earlyDepartureCount', l: 'Số lần về sớm' },
                    { k: 'totalActualOtHours', l: 'OT thực tế (h)' },
                    { k: 'totalPaidOtHours', l: 'OT tính lương (h)' }
                  ].map(f => (
                    <label key={f.k} className="block">
                      <span className="block font-bold text-slate-700 mb-1">{f.l}</span>
                      <input
                        type="number"
                        step="0.25"
                        min="0"
                        value={(sheetForm as any)[f.k]}
                        onChange={e => setSheetForm({ ...sheetForm, [f.k]: e.target.value })}
                        className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                      />
                    </label>
                  ))}
                </div>

                <label className="block">
                  <span className="block font-bold text-slate-700 mb-1">Lý do chỉnh sửa</span>
                  <textarea
                    rows={2}
                    maxLength={500}
                    value={sheetForm.note}
                    onChange={e => setSheetForm({ ...sheetForm, note: e.target.value })}
                    className="w-full rounded-xl border border-slate-300 p-2.5 focus:border-blue-600 focus:outline-hidden"
                  />
                </label>

                <div className="flex items-center justify-end gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setEditingSheet(null)}
                    className="rounded-xl border border-slate-300 px-4 py-2.5 font-bold text-slate-700 hover:bg-slate-50 transition cursor-pointer"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={savingSheet}
                    className="rounded-xl bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white px-5 py-2.5 font-bold shadow-sm transition cursor-pointer"
                  >
                    {savingSheet ? 'Đang lưu…' : 'Lưu thay đổi'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

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
