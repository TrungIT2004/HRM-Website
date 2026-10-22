'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import TodayStatusBadge from '@/components/TodayStatusBadge';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { employeeService, CreateEmployeePayload } from '@/services/employeeService';
import { organizationService, DepartmentDto, JobDto } from '@/services/organizationService';
import { DEPARTMENTS } from '@/constants/departments';
import { workShiftService, WorkShiftResponse } from '@/services/workShiftService';
import {
  Users,
  Search,
  Building2,
  Mail,
  ArrowUpRight,
  LayoutGrid,
  Table as TableIcon,
  CheckCircle2,
  UserPlus,
  X,
  Briefcase
} from 'lucide-react';
import { DepartmentName, TodayAttendanceStatus, User } from '@/types';

export default function EmployeeDirectoryPage() {
  const { allUsers, isHR, isExecutive, currentUser, can } = useAuth();
  const { employeeDetails } = useHRMData();

  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');

  // Directory live state
  const [liveUsers, setLiveUsers] = useState<User[]>([]);
  const [toastMsg, setToastMsg] = useState('');

  // Modals state
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  // Org data state
  const [departments, setDepartments] = useState<DepartmentDto[]>([]);
  const [jobs, setJobs] = useState<JobDto[]>([]);
  const [shifts, setShifts] = useState<WorkShiftResponse[]>([]);

  // Create Employee Form state
  const [newEmp, setNewEmp] = useState<CreateEmployeePayload>({
    email: '',
    password: 'password123',
    firstName: '',
    lastName: '',
    departmentId: '',
    jobId: '',
    shiftId: '',
    baseSalary: 15000000,
    phoneNumber: '',
    citizenId: '',
    address: 'Hà Nội'
  });

  // Org Management Form states

  // Filter form ref — reads values on submit
  const filterFormRef = useRef<HTMLFormElement>(null);
  const [appliedFilters, setAppliedFilters] = useState({
    keyword: '',
    dept: 'ALL',
    status: 'ALL'
  });

  const handleApplyFilter = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const fd = new FormData(filterFormRef.current!);
    setAppliedFilters({
      keyword: fd.get('keyword') as string || '',
      dept: fd.get('dept') as string || 'ALL',
      status: fd.get('status') as string || 'ALL'
    });
  };

  const handleResetFilter = () => {
    filterFormRef.current?.reset();
    setAppliedFilters({ keyword: '', dept: 'ALL', status: 'ALL' });
  };

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };

  const loadDirectory = async (filters = appliedFilters) => {
    try {
      const res = await employeeService.getEmployees({
        keyword: filters.keyword || undefined,
        department: filters.dept !== 'ALL' ? filters.dept : undefined,
        size: 50
      });
      if (res && res.content) {
        setLiveUsers(res.content);
      }
    } catch {
      // fallback to allUsers
    }
  };

  const loadOrgData = async () => {
    try {
      const [deptRes, jobRes, shiftRes] = await Promise.all([
        organizationService.getAllDepartments(),
        organizationService.getAllJobs(),
        workShiftService.getAllWorkShifts()
      ]);
      setDepartments(deptRes || []);
      setJobs(jobRes || []);
      setShifts(shiftRes || []);

      if (deptRes && deptRes.length > 0) {
        setNewEmp(prev => ({
          ...prev,
          departmentId: prev.departmentId || deptRes[0].departmentId
        }));
      }
      if (jobRes && jobRes.length > 0) {
        setNewEmp(prev => ({ ...prev, jobId: prev.jobId || jobRes[0].jobId }));
      }
      if (shiftRes && shiftRes.length > 0) {
        setNewEmp(prev => ({ ...prev, shiftId: prev.shiftId || shiftRes[0].shiftId }));
      }
    } catch {
      // ignore
    }
  };

  useEffect(() => {
    loadDirectory(appliedFilters);
  }, [appliedFilters.keyword, appliedFilters.dept]);

  useEffect(() => {
    loadOrgData();
  }, []);

  const displayedUsers = liveUsers.length > 0 ? liveUsers : allUsers;

  // Quyền quản lý cơ cấu: mặc định phòng HR, hoặc được cấp ORG_MANAGE (backend: isHR || grant)
  const isHRRaw = (currentUser?.department || '').toLowerCase() === 'human resources';
  const canManageOrg = isHRRaw || can('ORG_MANAGE');


  const filteredUsers = displayedUsers.filter(user => {
    const matchKeyword = 
      !appliedFilters.keyword ||
      ((user.fullName || '')?.toLowerCase() || '').includes(appliedFilters.keyword.toLowerCase()) ||
      ((user.employeeCode || '')?.toLowerCase() || '').includes(appliedFilters.keyword.toLowerCase()) ||
      ((user.email || '')?.toLowerCase() || '').includes(appliedFilters.keyword.toLowerCase()) ||
      ((user.job || '')?.toLowerCase() || '').includes(appliedFilters.keyword.toLowerCase());

    const matchDept = appliedFilters.dept === 'ALL' || user.department === appliedFilters.dept;
    const matchStatus = appliedFilters.status === 'ALL' || user.todayStatus === appliedFilters.status;

    return matchKeyword && matchDept && matchStatus;
  });

  const handleCreateEmployeeSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await employeeService.createEmployee(newEmp);
      showToast(`Đã tạo nhân viên mới ${newEmp.firstName} ${newEmp.lastName} thành công!`);
      setIsCreateModalOpen(false);
      setNewEmp({
        email: '',
        password: 'password123',
        firstName: '',
        lastName: '',
        departmentId: departments[0]?.departmentId || '',
        jobId: jobs[0]?.jobId || '',
        shiftId: shifts[0]?.shiftId || '',
        baseSalary: 15000000,
        phoneNumber: '',
        citizenId: '',
        address: 'Hà Nội'
      });
      await loadDirectory();
    } catch (err: any) {
      showToast('Lỗi tạo nhân viên: ' + (err.message || 'Không thể tạo'));
    }
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {toastMsg && (
          <div className="fixed top-20 right-6 z-50 rounded-2xl bg-slate-900 text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold animate-in slide-in-from-top-4">
            <CheckCircle2 className="h-5 w-5 text-emerald-400" />
            <span>{toastMsg}</span>
          </div>
        )}

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
              Tra cứu hồ sơ công khai, trạng thái chấm công và cơ cấu tổ chức doanh nghiệp.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {canManageOrg && (
              <Link
                href="/organization/manage"
                className="flex items-center gap-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 px-3.5 py-2.5 text-xs font-bold transition"
              >
                <Building2 className="h-4 w-4 text-blue-600" aria-hidden="true" />
                <span>Cơ cấu & Ca làm việc</span>
              </Link>
            )}
            {(isHR || isExecutive) && (
              <>
                <button
                  onClick={() => setIsCreateModalOpen(true)}
                  className="flex items-center gap-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
                >
                  <UserPlus className="h-4 w-4" />
                  <span>Thêm nhân viên mới</span>
                </button>
              </>
            )}

            <button
              onClick={() => setViewMode('grid')}
              className={`p-2.5 rounded-xl border transition cursor-pointer ${
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
              className={`p-2.5 rounded-xl border transition cursor-pointer ${
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

        {/* Filter & Search Bar */}
        <form ref={filterFormRef} onSubmit={handleApplyFilter} className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-xs space-y-3">
          <div className="grid grid-cols-1 sm:grid-cols-12 gap-3">
            <div className="relative sm:col-span-6">
              <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                <Search className="h-4 w-4 text-slate-400" />
              </div>
              <input
                type="text"
                name="keyword"
                placeholder="Tìm kiếm theo Tên, Mã nhân viên (EMP...), Email hoặc Vị trí..."
                className="block w-full rounded-xl border border-slate-300 py-2.5 pl-10 pr-4 text-xs placeholder:text-slate-400 focus:border-blue-600 focus:outline-hidden"
              />
            </div>

            <div className="sm:col-span-3">
              <select
                name="dept"
                defaultValue="ALL"
                className="block w-full rounded-xl border border-slate-300 py-2.5 px-3 text-xs focus:border-blue-600 focus:outline-hidden bg-white"
              >
                <option value="ALL">Tất cả phòng ban</option>
                {departments.length > 0 ? (
                  departments.map(d => (
                    <option key={d.departmentId} value={d.name}>
                      {d.name} ({d.totalEmployees})
                    </option>
                  ))
                ) : (
                  <>
                    <option value="ALL">Tất cả phòng ban</option>
                    {DEPARTMENTS.map(d => (
                      <option key={d.dbName} value={d.dbName}>{d.label}</option>
                    ))}
                  </>
                )}
              </select>
            </div>

            <div className="sm:col-span-3">
              <select
                name="status"
                defaultValue="ALL"
                className="block w-full rounded-xl border border-slate-300 py-2.5 px-3 text-xs focus:border-blue-600 focus:outline-hidden bg-white"
              >
                <option value="ALL">Tất cả trạng thái hôm nay</option>
                <option value="WORKING">Đang làm việc</option>
                <option value="ON_LEAVE">Nghỉ phép</option>
                <option value="ABSENT">Vắng mặt</option>
                <option value="NOT_CHECKED">Chưa chấm công</option>
              </select>
            </div>
          </div>

          <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
            {(appliedFilters.keyword || appliedFilters.dept !== 'ALL' || appliedFilters.status !== 'ALL') && (
              <button
                type="button"
                onClick={handleResetFilter}
                className="px-3.5 py-1.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 text-xs font-semibold transition cursor-pointer"
              >
                Đặt lại
              </button>
            )}
            <button
              type="submit"
              className="flex items-center gap-1.5 px-4 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-xs transition cursor-pointer"
            >
              <Search className="h-3.5 w-3.5" />
              <span>Tìm kiếm & Lọc</span>
            </button>
          </div>
        </form>


        {/* Results Count */}
        <div className="flex items-center justify-between text-xs text-slate-500 px-1">
          <span>Tìm thấy <strong>{filteredUsers.length}</strong> nhân sự phù hợp</span>
        </div>

        {/* Directory Listing */}
        {viewMode === 'grid' ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredUsers.map(user => {
              const avatarSrc = user.profilePicUrl?.startsWith('http')
                ? user.profilePicUrl
                : user.profilePicUrl
                ? user.profilePicUrl
                : null;

              return (
                <div
                  key={user.userId}
                  className="rounded-3xl bg-white p-5 shadow-xs border border-slate-200/80 hover:border-blue-200 hover:shadow-md transition flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-start justify-between gap-3 mb-3">
                      <div className="flex items-center gap-3">
                        {avatarSrc ? (
                          <img
                            src={avatarSrc}
                            alt={user.fullName}
                            className="h-12 w-12 rounded-2xl object-cover border border-slate-100 shadow-xs"
                          />
                        ) : (
                          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-600 to-indigo-600 text-white font-extrabold text-base shadow-xs">
                            {user.lastName?.[0] || user.fullName?.[0]}
                          </div>
                        )}
                        <div>
                          <div className="font-bold text-slate-900 text-sm flex items-center gap-1.5">
                            <span>{user.fullName}</span>
                          </div>
                          <span className="font-mono text-[11px] text-slate-400 font-semibold">{user.employeeCode}</span>
                        </div>
                      </div>
                      <TodayStatusBadge status={user.todayStatus} overtime={user.todayOvertimeStatus} />
                    </div>

                    <div className="space-y-1.5 text-xs text-slate-600 border-t border-slate-100 pt-3">
                      <div className="flex items-center gap-2">
                        <Building2 className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                        <span className="font-semibold text-slate-800">{user.department}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Briefcase className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                        <span className="text-blue-600 font-medium">{user.job}</span>
                      </div>
                      <div className="flex items-center gap-2 font-mono text-[11px] text-slate-500">
                        <Mail className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                        <span className="truncate">{user.email}</span>
                      </div>
                    </div>
                  </div>

                  <Link
                    href={`/employees/${user.userId}`}
                    className="mt-4 flex items-center justify-between p-2.5 rounded-xl bg-slate-50 hover:bg-blue-50 text-slate-700 hover:text-blue-700 font-bold text-xs transition border border-slate-100 group"
                  >
                    <span>Xem hồ sơ chi tiết</span>
                    <ArrowUpRight className="h-3.5 w-3.5 group-hover:translate-x-0.5 transition-transform" />
                  </Link>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="rounded-3xl bg-white border border-slate-200/80 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-bold uppercase text-[10px] tracking-wider">
                    <tr>
                      <th className="py-3.5 px-4">Mã NV</th>
                      <th className="py-3.5 px-4">Họ tên</th>
                      <th className="py-3.5 px-4">Phòng ban</th>
                    <th className="py-3.5 px-4">Chức vụ</th>
                    <th className="py-3.5 px-4">Email</th>
                    <th className="py-3.5 px-4">Hôm nay</th>
                    <th className="py-3.5 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                    {filteredUsers.length === 0 && (
                      <tr><td colSpan={6} className="py-8 text-center text-xs text-slate-400">Không tìm thấy nhân sự phù hợp với bộ lọc.</td></tr>
                    )}
                    {filteredUsers.map(u => (
                    <tr key={u.userId} className="hover:bg-slate-50/80 transition">
                      <td className="py-3 px-4 font-mono text-[11px] text-slate-500">{u.employeeCode}</td>
                      <td className="py-3 px-4 font-bold text-slate-900">{u.fullName}</td>
                      <td className="py-3 px-4 font-semibold text-slate-800">{u.department}</td>
                      <td className="py-3 px-4 text-blue-600 font-medium">{u.job}</td>
                      <td className="py-3 px-4 font-mono text-slate-500">{u.email}</td>
                      <td className="py-3 px-4"><TodayStatusBadge status={u.todayStatus} overtime={u.todayOvertimeStatus} /></td>
                      <td className="py-3 px-4 text-right">
                        <Link
                          href={`/employees/${u.userId}`}
                          className="inline-flex items-center gap-1 text-xs font-bold text-blue-600 hover:text-blue-700"
                        >
                          <span>Chi tiết</span>
                          <ArrowUpRight className="h-3 w-3" />
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* MODAL 1: THÊM NHÂN VIÊN MỚI */}
        {isCreateModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 overflow-y-auto">
            <div className="relative w-full max-w-2xl rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200 my-8 max-h-[90vh] overflow-y-auto">
              <button
                onClick={() => setIsCreateModalOpen(false)}
                className="absolute right-4 top-4 rounded-full p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition"
              >
                <X className="h-5 w-5" />
              </button>

              <h2 className="text-lg font-black text-slate-900 mb-1 flex items-center gap-2">
                <UserPlus className="h-5 w-5 text-blue-600" />
                <span>Thêm Nhân Viên Mới Trọn Gói</span>
              </h2>
              <p className="text-xs text-slate-500 mb-6">
                Tự động tạo tài khoản đăng nhập, hồ sơ pháp lý, hợp đồng thử việc và mức lương ban đầu.
              </p>

              <form onSubmit={handleCreateEmployeeSubmit} className="space-y-4 text-xs">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Họ đệm *</label>
                    <input
                      type="text"
                      required
                      value={newEmp.lastName}
                      onChange={e => setNewEmp({ ...newEmp, lastName: e.target.value })}
                      placeholder="Nguyễn Văn"
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Tên *</label>
                    <input
                      type="text"
                      required
                      value={newEmp.firstName}
                      onChange={e => setNewEmp({ ...newEmp, firstName: e.target.value })}
                      placeholder="An"
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Email doanh nghiệp *</label>
                    <input
                      type="email"
                      required
                      value={newEmp.email}
                      onChange={e => setNewEmp({ ...newEmp, email: e.target.value })}
                      placeholder="nguyenvanan@company.com"
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Mật khẩu khởi tạo (tối thiểu 8 ký tự) *</label>
                    <input
                      type="password"
                      required
                      minLength={8}
                      value={newEmp.password}
                      onChange={e => setNewEmp({ ...newEmp, password: e.target.value })}
                      placeholder="••••••••"
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Phòng ban *</label>
                    <select
                      required
                      value={newEmp.departmentId}
                      onChange={e => setNewEmp({ ...newEmp, departmentId: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium bg-white focus:border-blue-600 focus:outline-hidden"
                    >
                      {departments.map(d => (
                        <option key={d.departmentId} value={d.departmentId}>{d.name}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Vị trí công việc *</label>
                    <select
                      required
                      value={newEmp.jobId}
                      onChange={e => setNewEmp({ ...newEmp, jobId: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium bg-white focus:border-blue-600 focus:outline-hidden"
                    >
                      {jobs.map(j => (
                        <option key={j.jobId} value={j.jobId}>{j.title}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Ca làm việc *</label>
                    <select
                      value={newEmp.shiftId}
                      onChange={e => setNewEmp({ ...newEmp, shiftId: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium bg-white focus:border-blue-600 focus:outline-hidden"
                    >
                      {shifts.map(s => (
                        <option key={s.shiftId} value={s.shiftId}>{s.name}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Lương cơ bản (VNĐ) *</label>
                    <input
                      type="number"
                      required
                      value={newEmp.baseSalary}
                      onChange={e => setNewEmp({ ...newEmp, baseSalary: Number(e.target.value) })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono font-bold focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>

                <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => setIsCreateModalOpen(false)}
                    className="px-4 py-2.5 rounded-xl border border-slate-300 font-bold text-slate-700 hover:bg-slate-50 transition"
                  >
                    Hủy bỏ
                  </button>
                  <button
                    type="submit"
                    className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold shadow-md shadow-blue-500/20 transition"
                  >
                    <UserPlus className="h-4 w-4" />
                    <span>Tạo nhân viên</span>
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
