'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { employeeService, CreateEmployeePayload } from '@/services/employeeService';
import { organizationService, DepartmentDto, JobDto } from '@/services/organizationService';
import { workShiftService, WorkShiftResponse } from '@/services/workShiftService';
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
  UserCheck,
  UserPlus,
  Plus,
  X,
  Save,
  Briefcase,
  AlertCircle
} from 'lucide-react';
import { DepartmentName, TodayAttendanceStatus, User } from '@/types';

export default function EmployeeDirectoryPage() {
  const { allUsers, isHR, isExecutive } = useAuth();
  const { employeeDetails } = useHRMData();

  const [keyword, setKeyword] = useState('');
  const [selectedDept, setSelectedDept] = useState<string>('ALL');
  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');

  // Directory live state
  const [liveUsers, setLiveUsers] = useState<User[]>([]);
  const [toastMsg, setToastMsg] = useState('');

  // Modals state
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isOrgModalOpen, setIsOrgModalOpen] = useState(false);

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
  const [newDeptName, setNewDeptName] = useState('');
  const [newJobTitle, setNewJobTitle] = useState('');
  const [newJobDeptId, setNewJobDeptId] = useState('');
  const [newShiftName, setNewShiftName] = useState('');

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };

  const loadDirectory = async () => {
    try {
      const res = await employeeService.getEmployees({
        keyword: keyword || undefined,
        department: selectedDept !== 'ALL' ? selectedDept : undefined,
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
        setNewJobDeptId(prev => prev || deptRes[0].departmentId);
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
    loadDirectory();
  }, [keyword, selectedDept]);

  useEffect(() => {
    loadOrgData();
  }, []);

  const displayedUsers = liveUsers.length > 0 ? liveUsers : allUsers;

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

  const filteredUsers = displayedUsers.filter(user => {
    const matchKeyword = 
      ((user.fullName || '')?.toLowerCase() || '').includes(keyword.toLowerCase()) ||
      ((user.employeeCode || '')?.toLowerCase() || '').includes(keyword.toLowerCase()) ||
      ((user.email || '')?.toLowerCase() || '').includes(keyword.toLowerCase()) ||
      ((user.job || '')?.toLowerCase() || '').includes(keyword.toLowerCase());

    const matchDept = selectedDept === 'ALL' || user.department === selectedDept;
    const matchStatus = selectedStatus === 'ALL' || user.todayStatus === selectedStatus;

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

  const handleCreateDepartment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDeptName.trim()) return;
    try {
      await organizationService.createDepartment(newDeptName.trim());
      showToast(`Đã tạo phòng ban ${newDeptName} thành công!`);
      setNewDeptName('');
      await loadOrgData();
    } catch (err: any) {
      showToast('Lỗi tạo phòng ban: ' + (err.message || 'Không thể tạo'));
    }
  };

  const handleCreateJob = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newJobTitle.trim() || !newJobDeptId) return;
    try {
      await organizationService.createJob(newJobTitle.trim(), newJobDeptId);
      showToast(`Đã tạo chức danh ${newJobTitle} thành công!`);
      setNewJobTitle('');
      await loadOrgData();
    } catch (err: any) {
      showToast('Lỗi tạo chức danh: ' + (err.message || 'Không thể tạo'));
    }
  };

  const handleCreateShift = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newShiftName.trim()) return;
    try {
      // Standard 8h shift Mon-Fri, Sat-Sun off
      const defaultSchedules = [
        { dayOfWeek: 1, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
        { dayOfWeek: 2, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
        { dayOfWeek: 3, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
        { dayOfWeek: 4, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
        { dayOfWeek: 5, isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
        { dayOfWeek: 6, isWorking: false },
        { dayOfWeek: 7, isWorking: false }
      ];
      await workShiftService.createWorkShift({
        name: newShiftName.trim(),
        schedules: defaultSchedules
      });
      showToast(`Đã tạo ca làm việc mới "${newShiftName}" (Tuân thủ luật ≤8h/ngày, ≤48h/tuần)!`);
      setNewShiftName('');
      await loadOrgData();
    } catch (err: any) {
      showToast('Lỗi tạo ca: ' + (err.message || 'Không thể tạo ca'));
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
            {(isHR || isExecutive) && (
              <>
                <button
                  onClick={() => setIsOrgModalOpen(true)}
                  className="flex items-center gap-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 px-3.5 py-2.5 text-xs font-bold transition cursor-pointer"
                >
                  <Building2 className="h-4 w-4 text-blue-600" />
                  <span>Cơ cấu & Ca làm việc</span>
                </button>
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
        <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 bg-white p-3.5 rounded-2xl border border-slate-200 shadow-xs">
          <div className="relative sm:col-span-6">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <Search className="h-4 w-4 text-slate-400" />
            </div>
            <input
              type="text"
              value={keyword}
              onChange={e => setKeyword(e.target.value)}
              placeholder="Tìm kiếm theo Tên, Mã nhân viên (EMP...), Email hoặc Vị trí..."
              className="block w-full rounded-xl border border-slate-300 py-2.5 pl-10 pr-4 text-xs placeholder:text-slate-400 focus:border-blue-600 focus:outline-hidden"
            />
          </div>

          <div className="sm:col-span-3">
            <select
              value={selectedDept}
              onChange={e => setSelectedDept(e.target.value)}
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
                  <option value="Executive Leadership">Ban Giám Đốc</option>
                  <option value="Human Resources">Phòng Nhân sự</option>
                  <option value="Information Technology">Phòng IT</option>
                  <option value="Sales & Marketing">Kinh doanh & Marketing</option>
                  <option value="Finance & Accounting">Tài chính - Kế toán</option>
                  <option value="Customer Support">Chăm sóc khách hàng</option>
                </>
              )}
            </select>
          </div>

          <div className="sm:col-span-3">
            <select
              value={selectedStatus}
              onChange={e => setSelectedStatus(e.target.value)}
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
                ? `http://localhost:8080${user.profilePicUrl}`
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
                      {todayStatusBadge(user.todayStatus)}
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
                    <th className="py-3.5 px-4">Nhân sự</th>
                    <th className="py-3.5 px-4">Phòng ban</th>
                    <th className="py-3.5 px-4">Chức vụ</th>
                    <th className="py-3.5 px-4">Email</th>
                    <th className="py-3.5 px-4">Hôm nay</th>
                    <th className="py-3.5 px-4 text-right">Thao tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700">
                  {filteredUsers.map(u => (
                    <tr key={u.userId} className="hover:bg-slate-50/80 transition">
                      <td className="py-3 px-4">
                        <div className="font-bold text-slate-900">{u.fullName}</div>
                        <div className="text-[10px] font-mono text-slate-400">{u.employeeCode}</div>
                      </td>
                      <td className="py-3 px-4 font-semibold text-slate-800">{u.department}</td>
                      <td className="py-3 px-4 text-blue-600 font-medium">{u.job}</td>
                      <td className="py-3 px-4 font-mono text-slate-500">{u.email}</td>
                      <td className="py-3 px-4">{todayStatusBadge(u.todayStatus)}</td>
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

        {/* MODAL 2: QUẢN LÝ CƠ CẤU & CA LÀM VIỆC */}
        {isOrgModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 overflow-y-auto">
            <div className="relative w-full max-w-3xl rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200 my-8 max-h-[90vh] overflow-y-auto">
              <button
                onClick={() => setIsOrgModalOpen(false)}
                className="absolute right-4 top-4 rounded-full p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition"
              >
                <X className="h-5 w-5" />
              </button>

              <h2 className="text-lg font-black text-slate-900 mb-1 flex items-center gap-2">
                <Building2 className="h-5 w-5 text-blue-600" />
                <span>Quản Lý Cơ Cấu Tổ Chức & Ca Làm Việc</span>
              </h2>
              <p className="text-xs text-slate-500 mb-6">
                Quyền hạn dành cho Trưởng Phòng Nhân Sự (HR Head) & Ban Giám Đốc (Executive Leadership).
              </p>

              <div className="space-y-6 text-xs">
                {/* 1. Tạo phòng ban mới */}
                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200">
                  <h3 className="font-bold text-slate-900 mb-2 flex items-center gap-2">
                    <Building2 className="h-4 w-4 text-blue-600" />
                    <span>1. Thêm Phòng Ban Mới (POST /api/departments)</span>
                  </h3>
                  <form onSubmit={handleCreateDepartment} className="flex gap-2">
                    <input
                      type="text"
                      value={newDeptName}
                      onChange={e => setNewDeptName(e.target.value)}
                      placeholder="Tên phòng ban mới (ví dụ: Phòng Nghiên cứu & Phát triển R&D)..."
                      className="flex-1 rounded-xl border border-slate-300 p-2.5 bg-white text-xs focus:border-blue-600 focus:outline-hidden"
                    />
                    <button
                      type="submit"
                      className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold transition shrink-0"
                    >
                      <Plus className="h-4 w-4" />
                      <span>Thêm phòng</span>
                    </button>
                  </form>
                </div>

                {/* 2. Tạo chức danh mới */}
                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200">
                  <h3 className="font-bold text-slate-900 mb-2 flex items-center gap-2">
                    <Briefcase className="h-4 w-4 text-indigo-600" />
                    <span>2. Thêm Chức Danh / Vị Trí Công Việc (POST /api/jobs)</span>
                  </h3>
                  <form onSubmit={handleCreateJob} className="grid grid-cols-1 sm:grid-cols-12 gap-2">
                    <div className="sm:col-span-6">
                      <input
                        type="text"
                        value={newJobTitle}
                        onChange={e => setNewJobTitle(e.target.value)}
                        placeholder="Tên chức danh (ví dụ: Kỹ sư Trí tuệ nhân tạo)..."
                        className="w-full rounded-xl border border-slate-300 p-2.5 bg-white text-xs focus:border-blue-600 focus:outline-hidden"
                      />
                    </div>
                    <div className="sm:col-span-4">
                      <select
                        value={newJobDeptId}
                        onChange={e => setNewJobDeptId(e.target.value)}
                        className="w-full rounded-xl border border-slate-300 p-2.5 bg-white text-xs focus:border-blue-600 focus:outline-hidden"
                      >
                        {departments.map(d => (
                          <option key={d.departmentId} value={d.departmentId}>{d.name}</option>
                        ))}
                      </select>
                    </div>
                    <div className="sm:col-span-2">
                      <button
                        type="submit"
                        className="w-full flex items-center justify-center gap-1 px-3 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold transition shrink-0"
                      >
                        <Plus className="h-4 w-4" />
                        <span>Thêm</span>
                      </button>
                    </div>
                  </form>
                </div>

                {/* 3. Tạo ca làm việc mới */}
                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200">
                  <h3 className="font-bold text-slate-900 mb-2 flex items-center gap-2">
                    <Clock className="h-4 w-4 text-emerald-600" />
                    <span>3. Thêm Ca Làm Việc Mới (POST /api/work-shifts)</span>
                  </h3>
                  <p className="text-[11px] text-slate-500 mb-2">
                    Tự động tạo lịch 7 ngày (T2-T6: 08:00 - 17:30, nghỉ trưa 12:00 - 13:30; T7 & CN nghỉ) đảm bảo luật ≤ 8h/ngày và ≤ 48h/tuần.
                  </p>
                  <form onSubmit={handleCreateShift} className="flex gap-2">
                    <input
                      type="text"
                      value={newShiftName}
                      onChange={e => setNewShiftName(e.target.value)}
                      placeholder="Tên ca (ví dụ: Ca Sáng Tiêu Chuẩn 08:00 - 17:30)..."
                      className="flex-1 rounded-xl border border-slate-300 p-2.5 bg-white text-xs focus:border-blue-600 focus:outline-hidden"
                    />
                    <button
                      type="submit"
                      className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold transition shrink-0"
                    >
                      <Plus className="h-4 w-4" />
                      <span>Thêm ca</span>
                    </button>
                  </form>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
