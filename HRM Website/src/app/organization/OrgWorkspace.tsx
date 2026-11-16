'use client';

import { useCallback, useEffect, useState, useMemo } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import {
  organizationService,
  DepartmentDto,
  JobDto
} from '@/services/organizationService';
import {
  workShiftService,
  WorkShiftResponse,
  CreateWorkShiftRequest
} from '@/services/workShiftService';
import { employeeService } from '@/services/employeeService';
import {
  AlertCircle,
  Building2,
  Briefcase,
  Building,
  CheckCircle2,
  Clock,
  Pencil,
  Plus,
  Search,
  Trash2,
  X,
  Network,
  Users,
  ChevronDown,
  ChevronRight,
  Sparkles,
  ArrowUpRight,
  Shield,
  FileText,
  UserCheck
} from 'lucide-react';
import { User } from '@/types';

type SubTab = 'departments' | 'jobs' | 'shifts';
type DialogKind = 'department' | 'job' | 'shift' | null;

const DEFAULT_SCHEDULES: CreateWorkShiftRequest['schedules'] = [
  { dayOfWeek: 1, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 2, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 3, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 4, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 5, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 6, isWorking: false },
  { dayOfWeek: 7, isWorking: false }
];

const DEPT_COLORS = [
  '#2563eb', // Blue
  '#8b5cf6', // Purple
  '#ef4444', // Red
  '#f59e0b', // Amber
  '#10b981', // Emerald
  '#06b6d4', // Cyan
  '#ec4899', // Pink
  '#6366f1', // Indigo
  '#84cc16'  // Lime
];

const CONTRACT_COLORS = [
  '#2563eb', // Blue: Fixed-term
  '#8b5cf6', // Purple: Indefinite
  '#f43f5e', // Rose: Học việc
  '#f59e0b'  // Amber: Thử việc
];

export default function OrgWorkspace({ tab }: { tab: 'overview' | 'tree' | 'manage' }) {
  const { currentUser, can } = useAuth();

  // Quyền: phòng HR hoặc grant ORG_MANAGE
  const isHR = (currentUser?.department || '').toLowerCase() === 'human resources';
  const canManage = isHR || can('ORG_MANAGE');

  // ponytail: tab cố định theo route (/overview, /structure, /manage) — direct URL không quyền manage rớt về overview
  const effectiveTab = tab === 'manage' && !canManage ? 'overview' : tab;
  const [subTab, setSubTab] = useState<SubTab>('departments');
  const [departments, setDepartments] = useState<DepartmentDto[]>([]);
  const [jobs, setJobs] = useState<JobDto[]>([]);
  const [shifts, setShifts] = useState<WorkShiftResponse[]>([]);
  const [employees, setEmployees] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [keyword, setKeyword] = useState('');
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Selected department filter on tree view
  const [selectedDeptId, setSelectedDeptId] = useState<string | null>(null);

  // Modals & form state for Manage tab
  const [dialog, setDialog] = useState<DialogKind>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formName, setFormName] = useState('');
  const [formDeptId, setFormDeptId] = useState('');
  const [formSchedules, setFormSchedules] = useState<CreateWorkShiftRequest['schedules']>(DEFAULT_SCHEDULES);
  const [saving, setSaving] = useState(false);
  const [dialogError, setDialogError] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<{ kind: SubTab; id: string; label: string } | null>(null);

  const showToast = (text: string, type: 'success' | 'error') => {
    setToast({ text, type });
    setTimeout(() => setToast(null), 4000);
  };

  const [overview, setOverview] = useState<any>(null);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [depts, allJobs, allShifts, empRes, ov] = await Promise.all([
        organizationService.getAllDepartments().catch(() => []),
        organizationService.getAllJobs().catch(() => []),
        workShiftService.getAllWorkShifts().catch(() => []),
        employeeService.getEmployees({ size: 100 }).catch(() => ({ content: [] })),
        organizationService.getOverview(new Date().getFullYear()).catch(() => null)
      ]);
      setDepartments(depts || []);
      setJobs(allJobs || []);
      setShifts(allShifts || []);
      setEmployees(empRes?.content || []);
      setOverview(ov);
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Không thể tải dữ liệu', 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Statistics calculation for Dashboard — dữ liệu thật từ GET /api/departments/overview
  const totalEmployees = overview?.totalEmployees ?? (employees.length > 0 ? employees.length : departments.reduce((acc, d) => acc + (d.totalEmployees || 0), 0));

  const deptChartData = useMemo(() => {
    const src = overview?.deptBreakdown?.length ? overview.deptBreakdown : departments.map(d => ({ name: d.name, count: d.totalEmployees || 0 }));
    const total = overview?.totalEmployees ?? totalEmployees;
    return (src || []).map((d: any, index: number) => ({
      id: d.name,
      label: d.name,
      value: d.count ?? 0,
      percentage: total > 0 ? Math.round(((d.count ?? 0) / total) * 1000) / 10 : 0,
      color: DEPT_COLORS[index % DEPT_COLORS.length]
    }));
  }, [overview, departments, totalEmployees]);

  const contractChartData = useMemo(() => {
    if (!overview?.contractBreakdown?.length) return [];
    const CONTRACT_LABELS: Record<string, string> = {
      Probation: 'Thử việc',
      'Fixed-term': 'Xác định thời hạn',
      Indefinite: 'Không xác định thời hạn'
    };
    const total = overview.contractBreakdown.reduce((a: number, c: any) => a + (c.count || 0), 0);
    return overview.contractBreakdown.map((c: any, i: number) => ({
      label: CONTRACT_LABELS[c.type] ?? c.type,
      value: c.count,
      percentage: total > 0 ? Math.round((c.count / total) * 1000) / 10 : 0,
      color: CONTRACT_COLORS[i % CONTRACT_COLORS.length]
    }));
  }, [totalEmployees]);

  // Handlers for Manage SubTab
  const openCreate = () => {
    setEditingId(null);
    setDialogError(null);
    setFormName('');
    setFormDeptId(departments[0]?.departmentId || '');
    setFormSchedules(DEFAULT_SCHEDULES);
    setDialog(subTab === 'departments' ? 'department' : subTab === 'jobs' ? 'job' : 'shift');
  };

  const openEdit = (kind: DialogKind, id: string, name: string, deptId?: string) => {
    setEditingId(id);
    setDialogError(null);
    setFormName(name);
    setFormDeptId(deptId || departments[0]?.departmentId || '');
    if (kind === 'shift') {
      const existing = shifts.find(s => s.shiftId === id);
      setFormSchedules(
        existing?.schedules.length
          ? existing.schedules.map(s => ({
              dayOfWeek: s.dayOfWeek,
              isWorking: !!s.isWorking,
              startTime: s.startTime,
              endTime: s.endTime,
              restStartTime: s.restStartTime,
              restEndTime: s.restEndTime
            }))
          : DEFAULT_SCHEDULES
      );
    }
    setDialog(kind);
  };

  const closeDialog = () => {
    setDialog(null);
    setDialogError(null);
    setEditingId(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formName.trim()) {
      showToast('Vui lòng nhập tên.', 'error');
      return;
    }
    setSaving(true);
    setDialogError(null);
    try {
      if (dialog === 'department') {
        if (editingId) {
          await organizationService.updateDepartment(editingId, formName.trim());
          showToast('Đã cập nhật tên phòng ban.', 'success');
        } else {
          await organizationService.createDepartment(formName.trim());
          showToast('Đã tạo phòng ban mới.', 'success');
        }
      } else if (dialog === 'job') {
        if (!formDeptId) throw new Error('Vui lòng chọn phòng ban.');
        if (editingId) {
          await organizationService.updateJob(editingId, formName.trim(), formDeptId);
          showToast('Đã cập nhật chức danh.', 'success');
        } else {
          await organizationService.createJob(formName.trim(), formDeptId);
          showToast('Đã tạo chức danh mới.', 'success');
        }
      } else if (dialog === 'shift') {
        const payload: CreateWorkShiftRequest = { name: formName.trim(), schedules: formSchedules };
        if (editingId) {
          await workShiftService.updateWorkShift(editingId, payload);
          showToast('Đã cập nhật ca làm việc.', 'success');
        } else {
          await workShiftService.createWorkShift(payload);
          showToast('Đã tạo ca làm việc mới.', 'success');
        }
      }
      closeDialog();
      loadData();
    } catch (err: any) {
      setDialogError(err?.response?.data?.msg || err?.message || 'Thao tác không thành công.');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!confirmDelete) return;
    setSaving(true);
    try {
      if (confirmDelete.kind === 'departments') {
        await organizationService.deleteDepartment(confirmDelete.id);
        showToast('Đã xoá phòng ban.', 'success');
      } else if (confirmDelete.kind === 'jobs') {
        await organizationService.deleteJob(confirmDelete.id);
        showToast('Đã xoá chức danh.', 'success');
      } else if (confirmDelete.kind === 'shifts') {
        await workShiftService.deleteWorkShift(confirmDelete.id);
        showToast('Đã xoá ca làm việc.', 'success');
      }
      setConfirmDelete(null);
      loadData();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Không thể xoá mục này.', 'error');
    } finally {
      setSaving(false);
    }
  };

  // Pure SVG Donut renderer
  const renderSvgDonut = (data: { label: string; value: number; percentage: number; color: string }[], total: number) => {
    const radius = 70;
    const strokeWidth = 26;
    const circumference = 2 * Math.PI * radius;
    let accumulatedOffset = 0;

    return (
      <div className="flex flex-col lg:flex-row items-center gap-6 justify-center">
        {/* Donut Circle */}
        <div className="relative w-44 h-44 shrink-0 flex items-center justify-center">
          <svg className="w-full h-full -rotate-90" viewBox="0 0 200 200">
            {/* Background track circle */}
            <circle
              cx="100"
              cy="100"
              r={radius}
              fill="transparent"
              stroke="#f1f5f9"
              strokeWidth={strokeWidth}
            />
            {data.map((item, idx) => {
              if (item.value <= 0 || total <= 0) return null;
              const sliceLength = (item.value / total) * circumference;
              const offset = -accumulatedOffset;
              accumulatedOffset += sliceLength;
              return (
                <circle
                  key={idx}
                  cx="100"
                  cy="100"
                  r={radius}
                  fill="transparent"
                  stroke={item.color}
                  strokeWidth={strokeWidth}
                  strokeDasharray={`${sliceLength} ${circumference - sliceLength}`}
                  strokeDashoffset={offset}
                  className="transition-all duration-500 hover:opacity-85"
                />
              );
            })}
          </svg>
          {/* Centered Total */}
          <div className="absolute flex flex-col items-center justify-center pointer-events-none">
            <span className="text-2xl font-black text-slate-900 tracking-tight">{total.toLocaleString()}</span>
            <span className="text-[10px] text-slate-400 font-medium">Nhân sự</span>
          </div>
        </div>

        {/* Legend List on Right */}
        <div className="flex-1 space-y-2 max-h-48 overflow-y-auto pr-1 text-xs w-full">
          {data.map((item, idx) => (
            <div key={idx} className="flex items-center justify-between gap-3 text-slate-700 hover:bg-slate-50 p-1 rounded-lg transition">
              <div className="flex items-center gap-2 min-w-0">
                <span className="w-2.5 h-2.5 rounded-full shrink-0 shadow-xs" style={{ backgroundColor: item.color }} />
                <span className="truncate font-medium text-slate-800">{item.label}</span>
              </div>
              <div className="flex items-center gap-1.5 shrink-0 font-semibold text-slate-900">
                <span>{item.value}</span>
                <span className="text-[11px] text-slate-400 font-normal">({item.percentage}%)</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Toast Alert */}
        {toast && (
          <div
            className={`fixed top-4 right-4 z-50 flex items-center gap-2 rounded-2xl px-4 py-3 text-xs font-bold text-white shadow-xl animate-in fade-in duration-200 ${
              toast.type === 'success' ? 'bg-emerald-600' : 'bg-rose-600'
            }`}
          >
            {toast.type === 'success' ? <CheckCircle2 className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
            <span>{toast.text}</span>
          </div>
        )}

        {/* Header Title & Main Tabs */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-slate-200">
          <div>
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-blue-600 text-white flex items-center justify-center shadow-md shadow-blue-500/25">
                <Network className="w-5 h-5" />
              </div>
              <div>
                <h1 className="text-xl sm:text-2xl font-black text-slate-900 tracking-tight">Cơ Cấu Tổ Chức</h1>
                <p className="text-xs text-slate-500 font-medium">Báo cáo cơ cấu nhân sự, sơ đồ phân cấp và quản lý chức danh phòng ban.</p>
              </div>
            </div>
          </div>

          {/* ponytail: điều hướng tab đã chuyển lên sidebar (/overview, /structure, /manage) */}
        </div>

        {/* TAB 1: TỔNG QUAN & BÁO CÁO (CHUẨN THEO ẢNH USER GỬI) */}
        {effectiveTab === 'overview' && (
          <div className="space-y-6 animate-in fade-in duration-200">
            {/* ROW 1: 3 KPI METRIC CARDS — dữ liệu thật từ /api/departments/overview */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {/* Card 1: Tổng nhân sự */}
              <div className="bg-white rounded-3xl p-5 border border-slate-200/80 shadow-xs flex flex-col justify-between hover:shadow-md transition">
                <div className="flex items-center justify-between text-xs text-slate-500 font-semibold mb-2">
                  <span>Tổng nhân sự</span>
                  <span className="flex items-center gap-1 text-[11px] bg-slate-50 border border-slate-200 px-2 py-0.5 rounded-lg text-slate-600">
                    Hiện tại
                  </span>
                </div>
                <div className="flex items-baseline justify-between mt-1">
                  <span className="text-3xl font-black text-slate-900">{overview?.totalEmployees ?? totalEmployees}</span>
                </div>
                <div className="mt-3 text-xs font-semibold text-slate-500">
                  {overview?.totalDepartments ?? departments.length} phòng ban · {overview?.totalJobs ?? jobs.length} chức danh
                </div>
              </div>

              {/* Card 2: Nhân viên mới tháng này */}
              <div className="bg-white rounded-3xl p-5 border border-slate-200/80 shadow-xs flex flex-col justify-between hover:shadow-md transition">
                <div className="flex items-center justify-between text-xs text-slate-500 font-semibold mb-2">
                  <span>Nhân viên mới</span>
                  <span className="flex items-center gap-1 text-[11px] bg-slate-50 border border-slate-200 px-2 py-0.5 rounded-lg text-slate-600">
                    Tháng này <ChevronDown className="w-3 h-3" />
                  </span>
                </div>
                <div className="flex items-baseline justify-between mt-1">
                  <span className="text-3xl font-black text-slate-900">{overview?.monthlyHires?.[new Date().getMonth()] ?? 0}</span>
                </div>
                <div className="mt-3 text-xs font-semibold text-slate-500">
                  Tuyển mới trong năm: {(overview?.monthlyHires || []).reduce((a: number, b: number) => a + b, 0)}
                </div>
              </div>

              {/* Card 3: Nghỉ việc tháng này */}
              <div className="bg-white rounded-3xl p-5 border border-slate-200/80 shadow-xs flex flex-col justify-between hover:shadow-md transition">
                <div className="flex items-center justify-between text-xs text-slate-500 font-semibold mb-2">
                  <span>Nghỉ việc</span>
                  <span className="flex items-center gap-1 text-[11px] bg-slate-50 border border-slate-200 px-2 py-0.5 rounded-lg text-slate-600">
                    Tháng này <ChevronDown className="w-3 h-3" />
                  </span>
                </div>
                <div className="flex items-baseline justify-between mt-1">
                  <span className="text-3xl font-black text-slate-900">{overview?.monthlyLeavers?.[new Date().getMonth()] ?? 0}</span>
                </div>
                <div className="mt-3 text-xs font-semibold text-slate-500">
                  Nghỉ việc trong năm: {(overview?.monthlyLeavers || []).reduce((a: number, b: number) => a + b, 0)}
                </div>
              </div>
            </div>

            {/* ROW 2: 2 DONUT CHARTS SIDE BY SIDE */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Donut Chart 1: Cơ cấu nhân sự theo phòng ban */}
              <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-xs">
                <div className="mb-4">
                  <h3 className="text-sm font-bold text-slate-900 tracking-tight">Cơ cấu nhân sự theo phòng ban</h3>
                  <p className="text-[11px] text-slate-400 mt-0.5">Tất cả đơn vị - Đến ngày {new Date().toLocaleDateString('vi-VN')}</p>
                </div>
                {renderSvgDonut(deptChartData, totalEmployees)}
              </div>

              {/* Donut Chart 2: Thống kê hợp đồng theo loại */}
              <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-xs">
                <div className="mb-4">
                  <h3 className="text-sm font-bold text-slate-900 tracking-tight">Thống kê hợp đồng theo loại</h3>
                  <p className="text-[11px] text-slate-400 mt-0.5">Tất cả đơn vị - Đến ngày {new Date().toLocaleDateString('vi-VN')}</p>
                </div>
                {renderSvgDonut(contractChartData, totalEmployees)}
              </div>
            </div>

            {/* ROW 3: 2 BAR CHARTS (BIẾN ĐỘNG & TỔNG NHÂN SỰ) */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Bar Chart 1: Biến động nhân sự */}
              <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-xs">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-sm font-bold text-slate-900 tracking-tight">Biến động nhân sự</h3>
                    <p className="text-[11px] text-slate-400 mt-0.5">Tất cả đơn vị - Năm {new Date().getFullYear()}</p>
                  </div>
                  <div className="flex items-center gap-3 text-[11px] font-semibold">
                    <span className="flex items-center gap-1.5 text-blue-600">
                      <span className="w-2.5 h-2.5 rounded-sm bg-blue-600 inline-block" /> Tuyển mới
                    </span>
                    <span className="flex items-center gap-1.5 text-rose-500">
                      <span className="w-2.5 h-2.5 rounded-sm bg-rose-500 inline-block" /> Nghỉ việc
                    </span>
                  </div>
                </div>

                {/* SVG 12-Month Bar Chart — dữ liệu thật */}
                <div className="h-44 w-full flex items-end justify-between gap-1.5 pt-6 pb-2 border-b border-slate-100">
                  {['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'].map((m, idx) => {
                    const newH = Math.min(100, ((overview?.monthlyHires?.[idx] ?? 0) / Math.max(1, ...(overview?.monthlyHires || [1]))) * 90 + ((overview?.monthlyHires?.[idx] ?? 0) > 0 ? 8 : 0));
                    const resH = Math.min(100, ((overview?.monthlyLeavers?.[idx] ?? 0) / Math.max(1, ...(overview?.monthlyLeavers || [1]))) * 90 + ((overview?.monthlyLeavers?.[idx] ?? 0) > 0 ? 8 : 0));
                    return (
                      <div key={m} className="flex-1 flex flex-col items-center justify-end h-full gap-1 group relative">
                        <div className="w-full flex items-end justify-center gap-0.5 h-full">
                          <div
                            style={{ height: `${newH}%` }}
                            className="w-2 sm:w-3 bg-blue-600 rounded-t-sm transition-all duration-300 group-hover:brightness-110"
                          />
                          <div
                            style={{ height: `${resH}%` }}
                            className="w-2 sm:w-3 bg-rose-400 rounded-t-sm transition-all duration-300 group-hover:brightness-110"
                          />
                        </div>
                        <span className="text-[10px] text-slate-400 font-medium">{m}</span>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Bar Chart 2: Số lượng nhân sự theo thời gian */}
              <div className="bg-white rounded-3xl p-6 border border-slate-200/80 shadow-xs">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-sm font-bold text-slate-900 tracking-tight">Số lượng nhân sự</h3>
                    <p className="text-[11px] text-slate-400 mt-0.5">Quy mô tăng trưởng - Năm {new Date().getFullYear()}</p>
                  </div>
                  <span className="text-xs font-bold text-slate-700 bg-slate-100 px-2.5 py-1 rounded-xl">
                    Hiện tại: {totalEmployees} người
                  </span>
                </div>

                {/* Headcount Progression — dữ liệu thật */}
                <div className="h-44 w-full flex items-end justify-between gap-1.5 pt-6 pb-2 border-b border-slate-100">
                  {['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'].map((m, idx) => {
                    const progress = overview?.headcountTrend?.[idx] ?? totalEmployees;
                    const heightPct = Math.min(100, (progress / Math.max(1, ...(overview?.headcountTrend || [totalEmployees, 1]))) * 100);
                    return (
                      <div key={m} className="flex-1 flex flex-col items-center justify-end h-full gap-1 group relative">
                        <div
                          style={{ height: `${heightPct}%` }}
                          className="w-3 sm:w-4 bg-linear-to-t from-blue-600 to-indigo-500 rounded-t-md transition-all duration-300 group-hover:brightness-110"
                        />
                        <span className="text-[10px] text-slate-400 font-medium">{m}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: SƠ ĐỒ CÂY TỔ CHỨC (INTERACTIVE ORG TREE) */}
        {effectiveTab === 'tree' && (
          <div className="space-y-6 animate-in fade-in duration-200">
            {/* Top Root Node: Ban Giám Đốc */}
            <div className="flex flex-col items-center">
              <div className="bg-linear-to-r from-blue-700 to-indigo-800 text-white rounded-3xl p-5 shadow-xl shadow-blue-900/20 border border-blue-500/30 text-center max-w-sm w-full relative">
                <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center mx-auto mb-2 text-white font-black text-base ring-2 ring-white/40">
                  CEO
                </div>
                <h3 className="text-base font-black tracking-tight">Ban Giám Đốc Điều Hành</h3>
                <p className="text-xs text-blue-200 font-medium mt-0.5">Executive Leadership</p>
                <div className="mt-3 flex items-center justify-center gap-2 text-[11px] font-semibold bg-white/10 py-1 px-3 rounded-xl border border-white/10">
                  <span>Chủ tịch: Nguyễn Minh Đức</span>
                </div>
              </div>

              {/* Connecting Tree Line */}
              <div className="w-0.5 h-8 bg-blue-300 my-1" />
              <div className="w-11/12 max-w-5xl h-0.5 bg-blue-300 mb-6 hidden md:block" />
            </div>

            {/* Department Level Branches */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
              {departments.map((dept, idx) => {
                const isSelected = selectedDeptId === dept.departmentId;
                const deptJobs = jobs.filter(j => j.departmentId === dept.departmentId);
                return (
                  <div
                    key={dept.departmentId}
                    onClick={() => setSelectedDeptId(isSelected ? null : dept.departmentId)}
                    className={`bg-white rounded-3xl p-5 border transition-all duration-200 cursor-pointer ${
                      isSelected
                        ? 'border-blue-500 ring-2 ring-blue-500/20 shadow-lg'
                        : 'border-slate-200/80 hover:border-slate-300 hover:shadow-md'
                    }`}
                  >
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex items-center gap-2.5">
                        <div
                          className="w-9 h-9 rounded-xl flex items-center justify-center text-white font-bold text-xs shadow-xs"
                          style={{ backgroundColor: DEPT_COLORS[idx % DEPT_COLORS.length] }}
                        >
                          <Building2 className="w-4 h-4" />
                        </div>
                        <div>
                          <h4 className="text-xs font-bold text-slate-900 leading-tight">{dept.name}</h4>
                          <span className="text-[10px] text-slate-400 font-medium">
                            {dept.totalEmployees} nhân sự
                          </span>
                        </div>
                      </div>
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-600">
                        {deptJobs.length} vị trí
                      </span>
                    </div>

                    {/* Job Titles list */}
                    <div className="space-y-1.5 pt-2 border-t border-slate-100">
                      <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Các chức danh:</p>
                      <div className="flex flex-wrap gap-1">
                        {deptJobs.slice(0, 4).map(job => (
                          <span
                            key={job.jobId}
                            className="text-[10px] font-medium px-2 py-0.5 rounded-lg bg-slate-50 border border-slate-200/60 text-slate-700 truncate max-w-[140px]"
                          >
                            {job.title}
                          </span>
                        ))}
                        {deptJobs.length > 4 && (
                          <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-lg bg-slate-100 text-slate-500">
                            +{deptJobs.length - 4}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* TAB 3: QUẢN LÝ PHÒNG BAN, CHỨC DANH & CA LÀM VIỆC (CRUD DATA) */}
        {effectiveTab === 'manage' && (
          <div className="space-y-6 animate-in fade-in duration-200">
            {/* Sub-tabs & Action Bar */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div role="tablist" className="flex items-center gap-1 bg-slate-100 p-1 rounded-2xl w-fit border border-slate-200/80">
                <button
                  role="tab"
                  aria-selected={subTab === 'departments'}
                  onClick={() => setSubTab('departments')}
                  className={`flex items-center gap-2 px-3 py-1.5 text-xs font-bold rounded-xl transition-all cursor-pointer ${
                    subTab === 'departments' ? 'bg-white text-blue-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <Building2 className="w-4 h-4" />
                  Phòng ban ({departments.length})
                </button>
                <button
                  role="tab"
                  aria-selected={subTab === 'jobs'}
                  onClick={() => setSubTab('jobs')}
                  className={`flex items-center gap-2 px-3 py-1.5 text-xs font-bold rounded-xl transition-all cursor-pointer ${
                    subTab === 'jobs' ? 'bg-white text-blue-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <Briefcase className="w-4 h-4" />
                  Chức danh ({jobs.length})
                </button>
                <button
                  role="tab"
                  aria-selected={subTab === 'shifts'}
                  onClick={() => setSubTab('shifts')}
                  className={`flex items-center gap-2 px-3 py-1.5 text-xs font-bold rounded-xl transition-all cursor-pointer ${
                    subTab === 'shifts' ? 'bg-white text-blue-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <Clock className="w-4 h-4" />
                  Ca làm việc ({shifts.length})
                </button>
              </div>

              {canManage && (
                <button
                  onClick={openCreate}
                  className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 active:scale-98 text-white rounded-xl text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer self-start sm:self-auto"
                >
                  <Plus className="w-4 h-4" />
                  <span>
                    Thêm {subTab === 'departments' ? 'phòng ban' : subTab === 'jobs' ? 'chức danh' : 'ca làm việc'}
                  </span>
                </button>
              )}
            </div>

            {/* Keyword Search Input */}
            <div className="relative max-w-sm">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                placeholder="Tìm kiếm..."
                value={keyword}
                onChange={e => setKeyword(e.target.value)}
                className="w-full pl-9 pr-3 py-2 text-xs rounded-xl border border-slate-200 bg-white placeholder:text-slate-400 focus:outline-hidden focus:border-blue-500 focus:ring-1 focus:ring-blue-500/20 transition"
              />
            </div>

            {/* SubTab 1: Departments Table */}
            {subTab === 'departments' && (
              <div className="bg-white rounded-3xl border border-slate-200/80 shadow-xs overflow-hidden">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-100 text-slate-500 font-bold uppercase tracking-wider text-[10px]">
                      <th className="py-3 px-4">Tên phòng ban</th>
                      <th className="py-3 px-4">Nhân sự hiện có</th>
                      <th className="py-3 px-4">Số lượng chức danh</th>
                      {canManage && <th className="py-3 px-4 text-right">Thao tác</th>}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {departments
                      .filter(d => d.name.toLowerCase().includes(keyword.toLowerCase().trim()))
                      .map(dept => (
                        <tr key={dept.departmentId} className="hover:bg-slate-50/80 transition">
                          <td className="py-3 px-4 font-bold text-slate-900">{dept.name}</td>
                          <td className="py-3 px-4">
                            <span className="font-semibold text-blue-600 bg-blue-50 px-2 py-0.5 rounded-md">
                              {dept.totalEmployees} nhân viên
                            </span>
                          </td>
                          <td className="py-3 px-4 text-slate-600 font-medium">
                            {dept.jobs ? dept.jobs.length : 0} chức danh
                          </td>
                          {canManage && (
                            <td className="py-3 px-4 text-right">
                              <div className="flex items-center justify-end gap-1.5">
                                <button
                                  onClick={() => openEdit('department', dept.departmentId, dept.name)}
                                  className="p-1.5 text-slate-400 hover:text-blue-600 rounded-lg hover:bg-slate-100 transition"
                                >
                                  <Pencil className="w-3.5 h-3.5" />
                                </button>
                                <button
                                  onClick={() => setConfirmDelete({ kind: 'departments', id: dept.departmentId, label: dept.name })}
                                  className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 transition"
                                >
                                  <Trash2 className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            </td>
                          )}
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            )}

            {/* SubTab 2: Jobs Table */}
            {subTab === 'jobs' && (
              <div className="bg-white rounded-3xl border border-slate-200/80 shadow-xs overflow-hidden">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-100 text-slate-500 font-bold uppercase tracking-wider text-[10px]">
                      <th className="py-3 px-4">Tên chức danh</th>
                      <th className="py-3 px-4">Phòng ban</th>
                      {canManage && <th className="py-3 px-4 text-right">Thao tác</th>}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {jobs
                      .filter(j => j.title.toLowerCase().includes(keyword.toLowerCase().trim()))
                      .map(job => (
                        <tr key={job.jobId} className="hover:bg-slate-50/80 transition">
                          <td className="py-3 px-4 font-bold text-slate-900">{job.title}</td>
                          <td className="py-3 px-4">
                            <span className="font-semibold text-slate-700 bg-slate-100 px-2 py-0.5 rounded-md">
                              {job.departmentName || departments.find(d => d.departmentId === job.departmentId)?.name || 'Chưa gắn'}
                            </span>
                          </td>
                          {canManage && (
                            <td className="py-3 px-4 text-right">
                              <div className="flex items-center justify-end gap-1.5">
                                <button
                                  onClick={() => openEdit('job', job.jobId, job.title, job.departmentId)}
                                  className="p-1.5 text-slate-400 hover:text-blue-600 rounded-lg hover:bg-slate-100 transition"
                                >
                                  <Pencil className="w-3.5 h-3.5" />
                                </button>
                                <button
                                  onClick={() => setConfirmDelete({ kind: 'jobs', id: job.jobId, label: job.title })}
                                  className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 transition"
                                >
                                  <Trash2 className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            </td>
                          )}
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            )}

            {/* SubTab 3: WorkShifts Table */}
            {subTab === 'shifts' && (
              <div className="bg-white rounded-3xl border border-slate-200/80 shadow-xs overflow-hidden">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-100 text-slate-500 font-bold uppercase tracking-wider text-[10px]">
                      <th className="py-3 px-4">Tên ca làm việc</th>
                      <th className="py-3 px-4">Giờ làm chuẩn</th>
                      <th className="py-3 px-4">Nghỉ trưa</th>
                      {canManage && <th className="py-3 px-4 text-right">Thao tác</th>}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {shifts
                      .filter(s => s.name.toLowerCase().includes(keyword.toLowerCase().trim()))
                      .map(shift => {
                        const sched = shift.schedules?.find(x => x.isWorking) || shift.schedules?.[0];
                        return (
                          <tr key={shift.shiftId} className="hover:bg-slate-50/80 transition">
                            <td className="py-3 px-4 font-bold text-slate-900">{shift.name}</td>
                            <td className="py-3 px-4 font-mono text-slate-700">
                              {sched?.startTime} - {sched?.endTime}
                            </td>
                            <td className="py-3 px-4 font-mono text-slate-500">
                              {sched?.restStartTime && sched?.restEndTime
                                ? `${sched.restStartTime} - ${sched.restEndTime}`
                                : 'Không nghỉ trưa'}
                            </td>
                            {canManage && (
                              <td className="py-3 px-4 text-right">
                                <div className="flex items-center justify-end gap-1.5">
                                  <button
                                    onClick={() => openEdit('shift', shift.shiftId, shift.name)}
                                    className="p-1.5 text-slate-400 hover:text-blue-600 rounded-lg hover:bg-slate-100 transition"
                                  >
                                    <Pencil className="w-3.5 h-3.5" />
                                  </button>
                                  <button
                                    onClick={() => setConfirmDelete({ kind: 'shifts', id: shift.shiftId, label: shift.name })}
                                    className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 transition"
                                  >
                                    <Trash2 className="w-3.5 h-3.5" />
                                  </button>
                                </div>
                              </td>
                            )}
                          </tr>
                        );
                      })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* Modal Dialog Tạo / Sửa (Phòng ban / Chức danh / Ca làm việc) */}
        {dialog && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4">
            <div className="relative w-full max-w-lg rounded-3xl bg-white p-6 shadow-2xl border border-slate-200">
              <button
                onClick={closeDialog}
                className="absolute top-5 right-5 text-slate-400 hover:text-slate-600 p-1 rounded-xl"
              >
                <X className="w-5 h-5" />
              </button>
              <h2 className="text-base font-black text-slate-900">
                {editingId ? 'Chỉnh sửa' : 'Tạo mới'}{' '}
                {dialog === 'department' ? 'phòng ban' : dialog === 'job' ? 'chức danh' : 'ca làm việc'}
              </h2>

              <form onSubmit={handleSubmit} className="space-y-4 text-xs mt-4">
                <div>
                  <label className="block font-bold text-slate-700 mb-1">
                    {dialog === 'department' ? 'Tên phòng ban' : dialog === 'job' ? 'Tên chức danh' : 'Tên ca'} *
                  </label>
                  <input
                    type="text"
                    required
                    value={formName}
                    onChange={e => setFormName(e.target.value)}
                    className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                  />
                </div>

                {dialog === 'job' && (
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Phòng ban *</label>
                    <select
                      required
                      value={formDeptId}
                      onChange={e => setFormDeptId(e.target.value)}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium bg-white focus:border-blue-600 focus:outline-hidden"
                    >
                      {departments.map(d => (
                        <option key={d.departmentId} value={d.departmentId}>
                          {d.name}
                        </option>
                      ))}
                    </select>
                  </div>
                )}

                {dialog === 'shift' && (
                  <fieldset>
                    <legend className="block font-bold text-slate-700 mb-2">
                      Lịch trình tuần <span className="font-normal text-slate-500">(≤ 8h/ngày, ≤ 48h/tuần)</span>
                    </legend>
                    <div className="space-y-2 max-h-56 overflow-y-auto pr-1">
                      {formSchedules.map((d, idx) => (
                        <div key={d.dayOfWeek} className="flex flex-wrap items-center gap-2">
                          <span className="w-8 text-[11px] font-bold text-slate-600 shrink-0">
                            {['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][idx]}
                          </span>
                          <label className="flex items-center gap-1.5 text-[11px] font-semibold text-slate-700">
                            <input
                              type="checkbox"
                              checked={d.isWorking}
                              onChange={e => {
                                const next = [...formSchedules];
                                next[idx] = { ...next[idx], isWorking: e.target.checked };
                                setFormSchedules(next);
                              }}
                              className="rounded"
                            />
                            Làm việc
                          </label>
                          {d.isWorking && (
                            <div className="flex items-center gap-1.5">
                              <input
                                type="time"
                                value={d.startTime || ''}
                                onChange={e => {
                                  const next = [...formSchedules];
                                  next[idx] = { ...next[idx], startTime: e.target.value };
                                  setFormSchedules(next);
                                }}
                                className="rounded-lg border border-slate-300 px-2 py-1 font-mono text-[11px]"
                              />
                              <span className="text-slate-400">→</span>
                              <input
                                type="time"
                                value={d.endTime || ''}
                                onChange={e => {
                                  const next = [...formSchedules];
                                  next[idx] = { ...next[idx], endTime: e.target.value };
                                  setFormSchedules(next);
                                }}
                                className="rounded-lg border border-slate-300 px-2 py-1 font-mono text-[11px]"
                              />
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  </fieldset>
                )}

                <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                  {dialogError && (
                    <div className="flex items-start gap-2 rounded-xl border border-rose-200 bg-rose-50 px-3 py-2 text-rose-700 mr-auto text-left">
                      <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                      <span className="font-semibold leading-snug">{dialogError}</span>
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={closeDialog}
                    className="px-4 py-2 rounded-xl border border-slate-300 font-bold text-slate-700 hover:bg-slate-50 transition"
                  >
                    Huỷ bỏ
                  </button>
                  <button
                    type="submit"
                    disabled={saving}
                    className="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold shadow-sm transition disabled:opacity-50"
                  >
                    {saving ? 'Đang lưu…' : editingId ? 'Lưu thay đổi' : 'Tạo mới'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Modal Xoá */}
        {confirmDelete && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4">
            <div className="relative w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl border border-slate-200">
              <h2 className="text-base font-black text-slate-900">
                Xoá {confirmDelete.kind === 'departments' ? 'phòng ban' : confirmDelete.kind === 'jobs' ? 'chức danh' : 'ca làm việc'}?
              </h2>
              <p className="text-xs text-slate-600 mt-2">
                <strong>{confirmDelete.label}</strong> sẽ bị xoá vĩnh viễn.
              </p>
              <div className="flex justify-end gap-3 mt-5">
                <button
                  onClick={() => setConfirmDelete(null)}
                  className="px-4 py-2 rounded-xl border border-slate-300 font-bold text-slate-700 hover:bg-slate-50 transition"
                >
                  Huỷ bỏ
                </button>
                <button
                  onClick={handleDelete}
                  disabled={saving}
                  className="px-5 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold transition disabled:opacity-50"
                >
                  {saving ? 'Đang xoá…' : 'Xoá'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
