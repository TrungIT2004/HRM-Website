'use client';

import React, { useEffect, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { adminService } from '@/services/adminService';
import { organizationService, DepartmentDto, JobDto } from '@/services/organizationService';
import { workShiftService, WorkShiftResponse } from '@/services/workShiftService';
import { CheckCircle2, AlertCircle, UserPlus, Send } from 'lucide-react';

// HR nhập hồ sơ nhân viên sắp vào làm (bước 1 onboarding).
// IT cấp email + tài khoản ở /admin/onboarding (bước 2).
export default function RecruitmentPage() {
  const { currentUser, isHR, isAdmin, can } = useAuth();
  const canRecruit = isHR || isAdmin || can('EMPLOYEE_EDIT');

  const [departments, setDepartments] = useState<DepartmentDto[]>([]);
  const [jobs, setJobs] = useState<JobDto[]>([]);
  const [shifts, setShifts] = useState<WorkShiftResponse[]>([]);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [form, setForm] = useState({
    firstName: '',
    lastName: '',
    gender: 'Nam',
    birthDate: '',
    personalEmail: '',
    phoneNumber: '',
    citizenId: '',
    placeOfBirth: '',
    departmentId: '',
    jobId: '',
    shiftId: '',
    baseSalary: '',
    contractType: 'Fixed-term',
    contractStartDate: '',
    contractEndDate: ''
  });

  const showToast = (text: string, type: 'success' | 'error') => {
    setToast({ text, type });
    setTimeout(() => setToast(null), 4000);
  };

  useEffect(() => {
    organizationService.getAllDepartments().then(setDepartments).catch(() => {});
    organizationService.getAllJobs().then(setJobs).catch(() => {});
    workShiftService.getAllWorkShifts().then(setShifts).catch(() => {});
  }, []);

  if (!canRecruit) {
    return (
      <AppShell>
        <div className="rounded-2xl bg-rose-50 border border-rose-200 p-8 text-center text-xs font-bold text-rose-700">
          Chỉ phòng Nhân sự (hoặc người được cấp quyền sửa hồ sơ) mới được nhập hồ sơ tuyển dụng.
        </div>
      </AppShell>
    );
  }

  const set = (k: string, v: string) => setForm(prev => ({ ...prev, [k]: v }));
  const deptJobs = jobs.filter(j => !form.departmentId || j.departmentId === form.departmentId);

  const inputCls =
    'w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800 focus:border-violet-600 focus:outline-hidden bg-white';
  const labelCls = 'block font-bold text-slate-700 mb-1';

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.firstName.trim() || !form.lastName.trim() || !form.birthDate || !form.personalEmail.trim()) {
      showToast('Vui lòng điền họ tên, ngày sinh và email cá nhân.', 'error');
      return;
    }
    if (!form.departmentId || !form.jobId) {
      showToast('Vui lòng chọn phòng ban và chức danh.', 'error');
      return;
    }
    setSaving(true);
    try {
      await adminService.createPendingUser({
        ...form,
        firstName: form.firstName.trim(),
        lastName: form.lastName.trim(),
        personalEmail: form.personalEmail.trim(),
        shiftId: form.shiftId || undefined,
        baseSalary: form.baseSalary ? Number(form.baseSalary) : undefined,
        contractStartDate: form.contractStartDate || undefined,
        contractEndDate: form.contractEndDate || undefined
      });
      showToast(`Đã lưu hồ sơ của ${form.firstName} ${form.lastName}. IT sẽ cấp tài khoản ở trang Duyệt cấp tài khoản.`, 'success');
      setForm({
        firstName: '', lastName: '', gender: 'Nam', birthDate: '', personalEmail: '',
        phoneNumber: '', citizenId: '', placeOfBirth: '', departmentId: '', jobId: '',
        shiftId: '', baseSalary: '', contractType: 'Fixed-term', contractStartDate: '', contractEndDate: ''
      });
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Lưu hồ sơ thất bại', 'error');
    } finally {
      setSaving(false);
    }
  };

  return (
    <AppShell>
      <div className="space-y-6 max-w-4xl">
        {toast && (
          <div
            role="status"
            className={`fixed top-20 right-6 z-50 rounded-2xl px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold text-white ${
              toast.type === 'success' ? 'bg-emerald-600' : 'bg-rose-600'
            }`}
          >
            {toast.type === 'success' ? <CheckCircle2 className="h-5 w-5" /> : <AlertCircle className="h-5 w-5" />}
            <span>{toast.text}</span>
          </div>
        )}

        <div>
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-violet-600 text-white flex items-center justify-center shadow-md">
              <UserPlus className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl sm:text-2xl font-black text-slate-900 tracking-tight">Tuyển Dụng & Nhân Viên Mới</h1>
              <p className="text-xs text-slate-500 font-medium">
                Nhập hồ sơ nhân sự sắp vào làm. IT cấp email + tài khoản ở trang Duyệt cấp tài khoản.
              </p>
            </div>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="rounded-3xl bg-white border border-slate-200/80 shadow-xs p-6 space-y-6 text-xs">
          <section>
            <h2 className="text-sm font-black text-slate-900 mb-3">Thông tin cá nhân</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className={labelCls}>Họ *</label>
                <input required value={form.firstName} onChange={e => set('firstName', e.target.value)} className={inputCls} placeholder="VD: Nguyễn Văn" />
              </div>
              <div>
                <label className={labelCls}>Tên *</label>
                <input required value={form.lastName} onChange={e => set('lastName', e.target.value)} className={inputCls} placeholder="VD: An" />
              </div>
              <div>
                <label className={labelCls}>Giới tính *</label>
                <select value={form.gender} onChange={e => set('gender', e.target.value)} className={inputCls}>
                  <option>Nam</option>
                  <option>Nữ</option>
                  <option>Khác</option>
                </select>
              </div>
              <div>
                <label className={labelCls}>Ngày sinh *</label>
                <input type="date" required value={form.birthDate} onChange={e => set('birthDate', e.target.value)} className={`${inputCls} font-mono`} />
              </div>
              <div>
                <label className={labelCls}>Email cá nhân *</label>
                <input type="email" required value={form.personalEmail} onChange={e => set('personalEmail', e.target.value)} className={inputCls} placeholder="nhanvien@gmail.com" />
              </div>
              <div>
                <label className={labelCls}>Số điện thoại</label>
                <input value={form.phoneNumber} onChange={e => set('phoneNumber', e.target.value)} className={inputCls} placeholder="09xxxxxxxx" />
              </div>
              <div>
                <label className={labelCls}>CCCD</label>
                <input value={form.citizenId} onChange={e => set('citizenId', e.target.value)} className={inputCls} />
              </div>
              <div>
                <label className={labelCls}>Nơi sinh</label>
                <input value={form.placeOfBirth} onChange={e => set('placeOfBirth', e.target.value)} className={inputCls} />
              </div>
            </div>
          </section>

          <section className="pt-4 border-t border-slate-100">
            <h2 className="text-sm font-black text-slate-900 mb-3">Vị trí & hợp đồng</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className={labelCls}>Phòng ban *</label>
                <select required value={form.departmentId} onChange={e => { set('departmentId', e.target.value); set('jobId', ''); }} className={inputCls}>
                  <option value="">— Chọn phòng ban —</option>
                  {departments.map(d => (
                    <option key={d.departmentId} value={d.departmentId}>{d.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className={labelCls}>Chức danh *</label>
                <select required value={form.jobId} onChange={e => set('jobId', e.target.value)} className={inputCls} disabled={!form.departmentId}>
                  <option value="">— Chọn chức danh —</option>
                  {deptJobs.map(j => (
                    <option key={j.jobId} value={j.jobId}>{j.title}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className={labelCls}>Ca làm việc</label>
                <select value={form.shiftId} onChange={e => set('shiftId', e.target.value)} className={inputCls}>
                  <option value="">— Chưa phân ca —</option>
                  {shifts.map(s => (
                    <option key={s.shiftId} value={s.shiftId}>{s.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className={labelCls}>Lương cơ bản (VNĐ)</label>
                <input type="number" min="0" value={form.baseSalary} onChange={e => set('baseSalary', e.target.value)} className={`${inputCls} font-mono`} placeholder="VD: 12000000" />
              </div>
              <div>
                <label className={labelCls}>Loại hợp đồng</label>
                <select value={form.contractType} onChange={e => set('contractType', e.target.value)} className={inputCls}>
                  <option value="Fixed-term">Xác định thời hạn</option>
                  <option value="Indefinite">Không xác định thời hạn</option>
                  <option value="Probation">Thử việc</option>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className={labelCls}>HĐ từ ngày</label>
                  <input type="date" value={form.contractStartDate} onChange={e => set('contractStartDate', e.target.value)} className={`${inputCls} font-mono`} />
                </div>
                <div>
                  <label className={labelCls}>HĐ đến ngày</label>
                  <input type="date" value={form.contractEndDate} onChange={e => set('contractEndDate', e.target.value)} className={`${inputCls} font-mono`} />
                </div>
              </div>
            </div>
          </section>

          <div className="flex justify-end pt-2">
            <button
              type="submit"
              disabled={saving}
              className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-bold shadow-md shadow-violet-500/20 transition disabled:opacity-50 cursor-pointer"
            >
              <Send className="h-4 w-4" />
              <span>{saving ? 'Đang lưu…' : 'Lưu hồ sơ chờ duyệt'}</span>
            </button>
          </div>
        </form>
      </div>
    </AppShell>
  );
}
