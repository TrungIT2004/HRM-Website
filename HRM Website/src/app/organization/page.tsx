'use client';

import { useCallback, useEffect, useState } from 'react';
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
  X
} from 'lucide-react';

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

export default function OrganizationPage() {
  const { currentUser, can } = useAuth();

  // Quyền gốc: phòng HR. Ủy quyền thêm qua grant ORG_MANAGE (khớp OrganizationService).
  const isHR = (currentUser?.department || '').toLowerCase() === 'human resources';
  const canManage = isHR || can('ORG_MANAGE');

  const [subTab, setSubTab] = useState<SubTab>('departments');
  const [departments, setDepartments] = useState<DepartmentDto[]>([]);
  const [jobs, setJobs] = useState<JobDto[]>([]);
  const [shifts, setShifts] = useState<WorkShiftResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [keyword, setKeyword] = useState('');
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const [dialog, setDialog] = useState<DialogKind>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formName, setFormName] = useState('');
  const [formDeptId, setFormDeptId] = useState('');
  const [formSchedules, setFormSchedules] = useState<CreateWorkShiftRequest['schedules']>(DEFAULT_SCHEDULES);
  const [saving, setSaving] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState<{ kind: SubTab; id: string; label: string } | null>(null);

  const showToast = (text: string, type: 'success' | 'error') => {
    setToast({ text, type });
    setTimeout(() => setToast(null), 4000);
  };

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [depts, allJobs, allShifts] = await Promise.all([
        organizationService.getAllDepartments().catch(() => []),
        organizationService.getAllJobs().catch(() => []),
        workShiftService.getAllWorkShifts().catch(() => [])
      ]);
      setDepartments(depts || []);
      setJobs(allJobs || []);
      setShifts(allShifts || []);
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Không thể tải dữ liệu', 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (canManage) loadData();
  }, [canManage, loadData]);

  const openCreate = () => {
    setEditingId(null);
    setFormName('');
    setFormDeptId(departments[0]?.departmentId || '');
    setFormSchedules(DEFAULT_SCHEDULES);
    setDialog(subTab === 'departments' ? 'department' : subTab === 'jobs' ? 'job' : 'shift');
  };

  const openEdit = (kind: DialogKind, id: string, name: string, deptId?: string) => {
    setEditingId(id);
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
    setEditingId(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formName.trim()) {
      showToast('Vui lòng nhập tên.', 'error');
      return;
    }
    setSaving(true);
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
      await loadData();
    } catch (err: any) {
      // 409 = đang được tham chiếu — message từ backend đã giải thích cụ thể
      const msg = err?.response?.data?.message || err?.response?.data?.msg || err?.message || 'Thao tác thất bại';
      showToast(msg, 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!confirmDelete) return;
    const { kind, id, label } = confirmDelete;
    setSaving(true);
    try {
      if (kind === 'departments') await organizationService.deleteDepartment(id);
      else if (kind === 'jobs') await organizationService.deleteJob(id);
      else await workShiftService.deleteWorkShift(id);
      showToast(`Đã xoá "${label}".`, 'success');
      setConfirmDelete(null);
      await loadData();
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.response?.data?.msg || err?.message || 'Không thể xoá';
      showToast(msg, 'error');
      setConfirmDelete(null);
    } finally {
      setSaving(false);
    }
  };

  if (!canManage) {
    return (
      <AppShell>
        <div className="rounded-2xl bg-white border border-slate-200 p-10 text-center">
          <AlertCircle className="w-10 h-10 text-amber-500 mx-auto mb-3" aria-hidden="true" />
          <h1 className="text-lg font-bold text-slate-900">Bạn không có quyền truy cập trang này</h1>
          <p className="text-sm text-slate-500 mt-1">
            Quản lý cơ cấu tổ chức dành cho phòng Nhân sự, hoặc nhân sự được cấp quyền
            <span className="font-semibold"> Quản lý phòng ban, chức danh &amp; ca làm việc</span>.
          </p>
        </div>
      </AppShell>
    );
  }

  const q = keyword.trim().toLowerCase();
  const shownDepartments = departments.filter(d => !q || d.name.toLowerCase().includes(q));
  const shownJobs = jobs.filter(
    j => !q || j.title.toLowerCase().includes(q) || (j.departmentName || '').toLowerCase().includes(q)
  );
  const shownShifts = shifts.filter(s => !q || s.name.toLowerCase().includes(q));

  const counts: Record<SubTab, number> = {
    departments: departments.length,
    jobs: jobs.length,
    shifts: shifts.length
  };

  const totalInList = subTab === 'departments' ? shownDepartments.length : subTab === 'jobs' ? shownJobs.length : shownShifts.length;

  return (
    <AppShell>
      <div className="space-y-6">
        {toast && (
          <div
            role="status"
            className="fixed top-20 right-6 z-50 rounded-2xl bg-slate-900 text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold"
          >
            {toast.type === 'success' ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" aria-hidden="true" />
            ) : (
              <AlertCircle className="w-5 h-5 text-rose-400 shrink-0" aria-hidden="true" />
            )}
            <span>{toast.text}</span>
          </div>
        )}

        <div>
          <div className="inline-flex items-center gap-1.5 text-xs font-semibold text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full border border-blue-200 mb-2">
            <Building2 className="w-3.5 h-3.5" aria-hidden="true" />
            <span>Master Data</span>
          </div>
          <h1 className="text-2xl font-black tracking-tight text-slate-900">Quản Trị Cơ Cấu Tổ Chức</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Thiết lập phòng ban, chức danh và ca làm việc — dữ liệu này dùng chung cho toàn hệ thống.
          </p>
        </div>

        <div className="rounded-2xl bg-white border border-slate-200 shadow-xs p-4">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div role="tablist" className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl self-start">
              {([
                { key: 'departments', label: 'Phòng Ban', icon: Building2 },
                { key: 'jobs', label: 'Chức Danh', icon: Briefcase },
                { key: 'shifts', label: 'Ca Làm Việc', icon: Clock }
              ] as const).map(t => {
                const Icon = t.icon;
                return (
                  <button
                    key={t.key}
                    role="tab"
                    aria-selected={subTab === t.key}
                    onClick={() => setSubTab(t.key)}
                    className={`flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-lg transition-all ${
                      subTab === t.key ? 'bg-white text-indigo-700 shadow-xs' : 'text-slate-600 hover:text-slate-900'
                    }`}
                  >
                    <Icon className="w-3.5 h-3.5" aria-hidden="true" />
                    {t.label} ({counts[t.key]})
                  </button>
                );
              })}
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                  <Search className="w-4 h-4 text-slate-400" aria-hidden="true" />
                </div>
                <input
                  type="search"
                  value={keyword}
                  onChange={e => setKeyword(e.target.value)}
                  placeholder="Tìm theo tên..."
                  aria-label="Tìm kiếm"
                  className="block w-full sm:w-64 rounded-xl border border-slate-300 py-2.5 pl-10 pr-4 text-xs placeholder:text-slate-400 focus:border-blue-600 focus:outline-hidden"
                />
              </div>
              <button
                onClick={openCreate}
                className="flex items-center gap-1.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2.5 text-xs font-bold shadow-sm transition"
              >
                <Plus className="w-4 h-4" aria-hidden="true" />
                <span>
                  {subTab === 'departments' ? 'Tạo Phòng Ban' : subTab === 'jobs' ? 'Tạo Chức Danh' : 'Tạo Ca Mới'}
                </span>
              </button>
            </div>
          </div>

          <p className="text-xs text-slate-500 mt-3">
            {loading ? 'Đang tải…' : `${totalInList} / ${counts[subTab]} bản ghi`}
          </p>
        </div>

        {subTab === 'departments' && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {shownDepartments.map(d => (
              <div key={d.departmentId} className="rounded-2xl bg-white p-5 border border-slate-200 shadow-xs flex flex-col">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <h3 className="font-bold text-slate-900 truncate">{d.name}</h3>
                    <p className="font-mono text-[11px] text-slate-400 mt-0.5 truncate">{d.departmentId}</p>
                  </div>
                  <span className="shrink-0 bg-blue-50 text-blue-700 text-xs font-bold px-2 py-0.5 rounded-full border border-blue-200">
                    {d.totalEmployees} NV
                  </span>
                </div>
                <p className="text-xs text-slate-500 mt-3">{d.jobs.length} chức danh</p>
                <div className="flex items-center gap-1.5 mt-3 pt-3 border-t border-slate-100">
                  <button
                    onClick={() => openEdit('department', d.departmentId, d.name)}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 text-xs font-bold transition"
                  >
                    <Pencil className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>Sửa</span>
                  </button>
                  <button
                    onClick={() => setConfirmDelete({ kind: 'departments', id: d.departmentId, label: d.name })}
                    className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-rose-200 text-rose-700 hover:bg-rose-50 text-xs font-bold transition"
                  >
                    <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                    <span>Xoá</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {subTab === 'jobs' && (
          <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase text-[10px] tracking-wider">
                  <tr>
                    <th className="py-3 px-4">Chức danh</th>
                    <th className="py-3 px-4">Phòng ban</th>
                    <th className="py-3 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {shownJobs.length === 0 && (
                    <tr>
                      <td colSpan={3} className="py-8 text-center text-slate-400">
                        Không tìm thấy chức danh phù hợp.
                      </td>
                    </tr>
                  )}
                  {shownJobs.map(j => (
                    <tr key={j.jobId} className="hover:bg-slate-50/80 transition">
                      <td className="py-3 px-4 font-bold text-slate-900">{j.title}</td>
                      <td className="py-3 px-4">{j.departmentName || '—'}</td>
                      <td className="py-3 px-4 text-right">
                        <div className="inline-flex items-center gap-1.5">
                          <button
                            onClick={() => openEdit('job', j.jobId, j.title, j.departmentId)}
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 font-bold transition"
                          >
                            <Pencil className="w-3.5 h-3.5" aria-hidden="true" />
                            <span>Sửa</span>
                          </button>
                          <button
                            onClick={() => setConfirmDelete({ kind: 'jobs', id: j.jobId, label: j.title })}
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-rose-200 text-rose-700 hover:bg-rose-50 font-bold transition"
                          >
                            <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                            <span>Xoá</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {subTab === 'shifts' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {shownShifts.length === 0 && (
              <p className="text-xs text-slate-400 col-span-full py-8 text-center">Chưa có ca làm việc nào.</p>
            )}
            {shownShifts.map(s => {
              const workingDays = s.schedules.filter(x => x.isWorking);
              const totalHours = workingDays.reduce((acc, d) => {
                if (!d.startTime || !d.endTime) return acc;
                const mins = (toMin(d.endTime) - toMin(d.startTime)) / 60;
                const rest = d.restStartTime && d.restEndTime ? (toMin(d.restEndTime) - toMin(d.restStartTime)) / 60 : 0;
                return acc + mins - rest;
              }, 0);
              return (
                <div key={s.shiftId} className="rounded-2xl bg-white p-5 border border-slate-200 shadow-xs">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <h3 className="font-bold text-slate-900 truncate">{s.name}</h3>
                      <p className="font-mono text-[11px] text-slate-400 mt-0.5 truncate">{s.shiftId}</p>
                    </div>
                    <span
                      className={`shrink-0 text-xs font-bold px-2 py-0.5 rounded-full border ${
                        totalHours > 48
                          ? 'bg-rose-50 text-rose-700 border-rose-200'
                          : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                      }`}
                    >
                      {workingDays.length} ngày · {totalHours.toFixed(1)}h/tuần
                    </span>
                  </div>

                  <div className="grid grid-cols-4 sm:grid-cols-7 gap-1.5 mt-4">
                    {s.schedules
                      .slice()
                      .sort((a, b) => a.dayOfWeek - b.dayOfWeek)
                      .map(d => (
                        <div
                          key={d.dayOfWeek}
                          className={`rounded-lg border px-1.5 py-1.5 text-center ${
                            d.isWorking
                              ? 'bg-blue-50 border-blue-200 text-blue-900'
                              : 'bg-slate-50 border-slate-200 text-slate-400'
                          }`}
                        >
                          <div className="text-[10px] font-bold">
                            {['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][d.dayOfWeek - 1]}
                          </div>
                          {d.isWorking ? (
                            <div className="text-[10px] font-mono leading-tight">
                              {d.startTime?.slice(0, 5)}
                              <br />
                              {d.endTime?.slice(0, 5)}
                            </div>
                          ) : (
                            <div className="text-[10px] font-bold">Nghỉ</div>
                          )}
                        </div>
                      ))}
                  </div>

                  <div className="flex items-center gap-1.5 mt-4 pt-3 border-t border-slate-100">
                    <button
                      onClick={() => openEdit('shift', s.shiftId, s.name)}
                      className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-slate-200 text-slate-700 hover:bg-slate-50 text-xs font-bold transition"
                    >
                      <Pencil className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>Sửa</span>
                    </button>
                    <button
                      onClick={() => setConfirmDelete({ kind: 'shifts', id: s.shiftId, label: s.name })}
                      className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-rose-200 text-rose-700 hover:bg-rose-50 text-xs font-bold transition"
                    >
                      <Trash2 className="w-3.5 h-3.5" aria-hidden="true" />
                      <span>Xoá</span>
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Dialog tạo / sửa */}
        {dialog && (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 overflow-y-auto"
            onClick={closeDialog}
          >
            <div
              role="dialog"
              aria-modal="true"
              aria-labelledby="org-dialog-title"
              onClick={e => e.stopPropagation()}
              className="relative w-full max-w-2xl rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200 my-8 max-h-[90vh] overflow-y-auto"
            >
              <button
                onClick={closeDialog}
                aria-label="Đóng"
                className="absolute right-4 top-4 rounded-full p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition"
              >
                <X className="w-5 h-5" />
              </button>

              <h2 id="org-dialog-title" className="text-lg font-black text-slate-900 mb-1">
                {editingId ? 'Chỉnh sửa' : 'Tạo mới'}{' '}
                {dialog === 'department' ? 'phòng ban' : dialog === 'job' ? 'chức danh' : 'ca làm việc'}
              </h2>

              <form onSubmit={handleSubmit} className="space-y-4 text-xs mt-4">
                <div>
                  <label htmlFor="org-name" className="block font-bold text-slate-700 mb-1">
                    {dialog === 'department' ? 'Tên phòng ban' : dialog === 'job' ? 'Tên chức danh' : 'Tên ca'} *
                  </label>
                  <input
                    id="org-name"
                    type="text"
                    required
                    value={formName}
                    onChange={e => setFormName(e.target.value)}
                    className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                  />
                </div>

                {dialog === 'job' && (
                  <div>
                    <label htmlFor="org-dept" className="block font-bold text-slate-700 mb-1">
                      Phòng ban *
                    </label>
                    <select
                      id="org-dept"
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
                    <div className="space-y-2">
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
                            <>
                              <input
                                type="time"
                                aria-label={`Giờ bắt đầu ${['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][idx]}`}
                                value={d.startTime || ''}
                                onChange={e => {
                                  const next = [...formSchedules];
                                  next[idx] = { ...next[idx], startTime: e.target.value };
                                  setFormSchedules(next);
                                }}
                                className="rounded-lg border border-slate-300 px-2 py-1.5 font-mono"
                              />
                              <span className="text-slate-400">→</span>
                              <input
                                type="time"
                                aria-label={`Giờ kết thúc ${['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][idx]}`}
                                value={d.endTime || ''}
                                onChange={e => {
                                  const next = [...formSchedules];
                                  next[idx] = { ...next[idx], endTime: e.target.value };
                                  setFormSchedules(next);
                                }}
                                className="rounded-lg border border-slate-300 px-2 py-1.5 font-mono"
                              />
                              <input
                                type="time"
                                aria-label={`Nghỉ bắt đầu ${['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][idx]}`}
                                value={d.restStartTime || ''}
                                onChange={e => {
                                  const next = [...formSchedules];
                                  next[idx] = { ...next[idx], restStartTime: e.target.value };
                                  setFormSchedules(next);
                                }}
                                className="rounded-lg border border-slate-300 px-2 py-1.5 font-mono"
                              />
                              <input
                                type="time"
                                aria-label={`Nghỉ kết thúc ${['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][idx]}`}
                                value={d.restEndTime || ''}
                                onChange={e => {
                                  const next = [...formSchedules];
                                  next[idx] = { ...next[idx], restEndTime: e.target.value };
                                  setFormSchedules(next);
                                }}
                                className="rounded-lg border border-slate-300 px-2 py-1.5 font-mono"
                              />
                            </>
                          )}
                        </div>
                      ))}
                    </div>
                  </fieldset>
                )}

                <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={closeDialog}
                    className="px-4 py-2.5 rounded-xl border border-slate-300 font-bold text-slate-700 hover:bg-slate-50 transition"
                  >
                    Huỷ bỏ
                  </button>
                  <button
                    type="submit"
                    disabled={saving}
                    className="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold shadow-sm transition disabled:opacity-50"
                  >
                    {saving ? 'Đang lưu…' : editingId ? 'Lưu thay đổi' : 'Tạo'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Dialog xác nhận xoá */}
        {confirmDelete && (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4"
            onClick={() => setConfirmDelete(null)}
          >
            <div
              role="alertdialog"
              aria-modal="true"
              aria-labelledby="org-delete-title"
              onClick={e => e.stopPropagation()}
              className="relative w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl border border-slate-200"
            >
              <h2 id="org-delete-title" className="text-base font-black text-slate-900">
                Xoá {confirmDelete.kind === 'departments' ? 'phòng ban' : confirmDelete.kind === 'jobs' ? 'chức danh' : 'ca làm việc'}?
              </h2>
              <p className="text-xs text-slate-600 mt-2">
                <strong>{confirmDelete.label}</strong> sẽ bị xoá vĩnh viễn.
              </p>
              <p className="text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-xl p-2.5 mt-3">
                Nếu đang có nhân viên, chức danh hoặc bản ghi chấm công tham chiếu tới, hệ thống sẽ từ chối và
                không xoá gì.
              </p>
              <div className="flex justify-end gap-3 mt-5">
                <button
                  onClick={() => setConfirmDelete(null)}
                  className="px-4 py-2.5 rounded-xl border border-slate-300 font-bold text-slate-700 hover:bg-slate-50 transition"
                >
                  Huỷ bỏ
                </button>
                <button
                  onClick={handleDelete}
                  disabled={saving}
                  className="px-5 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold transition disabled:opacity-50"
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

function toMin(hhmm: string): number {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
}
