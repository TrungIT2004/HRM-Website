'use client';

import React, { useState, useEffect, use, useRef } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { getEmployeeDetail } from '@/mock/employeeDetails';
import { EmployeeDetailed, TodayAttendanceStatus } from '@/types';
import { employeeService } from '@/services/employeeService';
import { 
  ArrowLeft, 
  Building2, 
  Calendar, 
  CreditCard, 
  FileText, 
  IdCard, 
  Mail, 
  Phone, 
  Shield, 
  UserCheck, 
  Edit3, 
  CheckCircle2, 
  Clock, 
  AlertCircle,
  Save,
  X,
  Lock,
  EyeOff,
  Camera,
  UserX,
  Sparkles
} from 'lucide-react';

export default function EmployeeDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const resolvedParams = use(params);
  const userId = resolvedParams.id;

  const { isHR, isExecutive, currentUser } = useAuth();
  const { employeeDetails } = useHRMData();

  const [activeTab, setActiveTab] = useState<'basic' | 'legal' | 'contract' | 'salary' | 'assignment'>('basic');
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [liveEmployee, setLiveEmployee] = useState<EmployeeDetailed | null>(null);
  const [toastMsg, setToastMsg] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };

  const loadProfile = async () => {
    try {
      const data = await employeeService.getDetailedProfile(userId);
      if (data && data.userId) {
        setLiveEmployee(data);
      }
    } catch {
      // fallback to mock
    }
  };

  useEffect(() => {
    loadProfile();
  }, [userId]);

  // Retrieve target employee
  const employee: EmployeeDetailed = liveEmployee || employeeDetails[userId] || getEmployeeDetail(userId);

  const isMe = currentUser?.userId === userId;
  const isTargetSameDeptHead = !!(
    currentUser?.job?.startsWith('Department Head') && 
    currentUser?.department === employee.department
  );

  const canViewLegal = isMe || isHR || isExecutive;
  const canViewContract = isMe || isTargetSameDeptHead || isHR || isExecutive;
  const canViewSalary = isMe || isHR || isExecutive;
  const canEdit = isHR || isExecutive;

  const todayStatusBadge = (status?: TodayAttendanceStatus) => {
    switch (status) {
      case 'WORKING':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-bold text-emerald-700 border border-emerald-200">
            <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>Đang làm việc (WORKING)</span>
          </span>
        );
      case 'ON_LEAVE':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-bold text-amber-700 border border-amber-200">
            <span className="h-2 w-2 rounded-full bg-amber-500" />
            <span>Nghỉ phép (ON_LEAVE)</span>
          </span>
        );
      case 'ABSENT':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-2.5 py-1 text-xs font-bold text-red-700 border border-red-200">
            <span className="h-2 w-2 rounded-full bg-red-500" />
            <span>Vắng mặt (ABSENT)</span>
          </span>
        );
      case 'NOT_CHECKED':
      default:
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-600 border border-slate-200">
            <span className="h-2 w-2 rounded-full bg-slate-400" />
            <span>Chưa chấm công (NOT_CHECKED)</span>
          </span>
        );
    }
  };

  // Form states for modal editing
  const [formData, setFormData] = useState({
    firstName: employee.firstName,
    lastName: employee.lastName,
    phoneNumber: employee.profile?.phoneNumber || '',
    personalEmail: employee.profile?.personalEmail || '',
    placeOfBirth: employee.profile?.placeOfBirth || '',
    maritalStatus: employee.profile?.maritalStatus || 'Độc thân',
    nationality: employee.profile?.nationality || 'Việt Nam',
    citizenIdNumber: employee.profile?.citizenIdNumber || '',
    socialInsuranceNumber: employee.profile?.socialInsuranceNumber || '',
    taxIdentificationNumber: employee.profile?.taxIdentificationNumber || '',
    emergencyContactName: employee.profile?.emergencyContactName || '',
    emergencyContactPhone: employee.profile?.emergencyContactPhone || '',
    contractType: employee.contract?.contractType || 'Không xác định thời hạn',
    contractStartDate: employee.contract?.contractStartDate || '2022-01-01',
    contractEndDate: employee.contract?.contractEndDate || '',
    baseSalary: employee.salary?.baseSalary || 20000000,
    bankName: employee.bankAccount?.bankName || 'Vietcombank',
    bankAccountNumber: employee.bankAccount?.bankAccountNumber || '',
    department: employee.department,
    job: employee.job,
    shiftName: employee.shiftName
  });

  useEffect(() => {
    if (employee) {
      setFormData({
        firstName: employee.firstName,
        lastName: employee.lastName,
        phoneNumber: employee.profile?.phoneNumber || '',
        personalEmail: employee.profile?.personalEmail || '',
        placeOfBirth: employee.profile?.placeOfBirth || '',
        maritalStatus: employee.profile?.maritalStatus || 'Độc thân',
        nationality: employee.profile?.nationality || 'Việt Nam',
        citizenIdNumber: employee.profile?.citizenIdNumber || '',
        socialInsuranceNumber: employee.profile?.socialInsuranceNumber || '',
        taxIdentificationNumber: employee.profile?.taxIdentificationNumber || '',
        emergencyContactName: employee.profile?.emergencyContactName || '',
        emergencyContactPhone: employee.profile?.emergencyContactPhone || '',
        contractType: employee.contract?.contractType || 'Không xác định thời hạn',
        contractStartDate: employee.contract?.contractStartDate || '2022-01-01',
        contractEndDate: employee.contract?.contractEndDate || '',
        baseSalary: employee.salary?.baseSalary || 20000000,
        bankName: employee.bankAccount?.bankName || 'Vietcombank',
        bankAccountNumber: employee.bankAccount?.bankAccountNumber || '',
        department: employee.department,
        job: employee.job,
        shiftName: employee.shiftName
      });
    }
  }, [employee]);

  const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      if (isMe) {
        await employeeService.uploadMyAvatar(file);
      } else {
        await employeeService.uploadEmployeeAvatar(userId, file);
      }
      showToast('Đã tải lên ảnh đại diện mới thành công!');
      await loadProfile();
    } catch (err: any) {
      showToast('Lỗi upload avatar: ' + (err.message || 'Không thể tải lên'));
    }
  };

  const handleToggleStatus = async () => {
    const currentActive = employee.isActive !== false;
    const nextActive = !currentActive;
    const actionText = nextActive ? 'kích hoạt lại' : 'KHÓA';
    if (!confirm(`Bạn có chắc chắn muốn ${actionText} tài khoản của nhân viên ${employee.fullName}?`)) {
      return;
    }

    try {
      await employeeService.updateStatus(userId, nextActive, nextActive ? 'HR kích hoạt lại' : 'Nhân viên thôi việc');
      showToast(nextActive ? 'Đã kích hoạt lại tài khoản thành công!' : 'Đã khóa tài khoản và hủy toàn bộ phiên đăng nhập!');
      await loadProfile();
    } catch (err: any) {
      showToast('Lỗi thay đổi trạng thái: ' + (err.message || 'Thao tác thất bại'));
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // 1. Basic Info
      await employeeService.updateBasicInfo(userId, {
        firstName: formData.firstName,
        lastName: formData.lastName
      });

      // 2. Legal Profile
      await employeeService.updateLegalProfile(userId, {
        phoneNumber: formData.phoneNumber,
        personalEmail: formData.personalEmail,
        placeOfBirth: formData.placeOfBirth,
        maritalStatus: formData.maritalStatus,
        nationality: formData.nationality,
        citizenIdNumber: formData.citizenIdNumber,
        socialInsuranceNumber: formData.socialInsuranceNumber,
        taxIdentificationNumber: formData.taxIdentificationNumber,
        emergencyContactName: formData.emergencyContactName,
        emergencyContactPhone: formData.emergencyContactPhone
      });

      // 3. Contract
      await employeeService.updateContract(userId, {
        contractType: formData.contractType,
        contractStartDate: formData.contractStartDate,
        contractEndDate: formData.contractEndDate || undefined
      });

      // 4. Payroll
      await employeeService.updatePayroll(userId, {
        baseSalary: Number(formData.baseSalary),
        bankName: formData.bankName,
        bankAccountNumber: formData.bankAccountNumber
      });

      showToast('Đã lưu toàn bộ thông tin hồ sơ nhân sự lên hệ thống!');
      setIsEditModalOpen(false);
      await loadProfile();
    } catch (err: any) {
      showToast('Lỗi lưu hồ sơ: ' + (err.message || 'Không thể cập nhật'));
    }
  };

  const avatarSrc = employee.profilePicUrl?.startsWith('http')
    ? employee.profilePicUrl
    : employee.profilePicUrl
    ? `http://localhost:8080${employee.profilePicUrl}`
    : null;

  return (
    <AppShell>
      <div className="space-y-6">
        {toastMsg && (
          <div className="fixed top-20 right-6 z-50 rounded-2xl bg-slate-900 text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold animate-in slide-in-from-top-4">
            <CheckCircle2 className="h-5 w-5 text-emerald-400" />
            <span>{toastMsg}</span>
          </div>
        )}

        {/* Back navigation & Edit Button */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <Link
            href="/employees"
            className="inline-flex items-center gap-2 text-xs font-bold text-slate-600 hover:text-blue-600 transition"
          >
            <ArrowLeft className="h-4 w-4" />
            <span>Quay lại Danh bạ Nhân sự</span>
          </Link>

          <div className="flex items-center gap-2">
            {canEdit && !isMe && (
              <button
                onClick={handleToggleStatus}
                className={`inline-flex items-center gap-1.5 rounded-xl px-3.5 py-2 text-xs font-bold shadow-xs transition cursor-pointer ${
                  employee.isActive !== false
                    ? 'bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-100'
                    : 'bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100'
                }`}
              >
                {employee.isActive !== false ? <UserX className="h-3.5 w-3.5" /> : <UserCheck className="h-3.5 w-3.5" />}
                <span>{employee.isActive !== false ? 'Khóa tài khoản (Thôi việc)' : 'Kích hoạt lại tài khoản'}</span>
              </button>
            )}

            {canEdit && (
              <button
                onClick={() => setIsEditModalOpen(true)}
                className="inline-flex items-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
              >
                <Edit3 className="h-3.5 w-3.5" />
                <span>Chỉnh sửa hồ sơ</span>
              </button>
            )}
          </div>
        </div>

        {/* Profile Card Header */}
        <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
            <div className="flex items-center gap-4 sm:gap-6">
              <div className="relative group">
                {avatarSrc ? (
                  <img
                    src={avatarSrc}
                    alt={employee.fullName}
                    className="h-16 w-16 sm:h-20 sm:w-20 rounded-3xl object-cover border-2 border-white shadow-md shadow-slate-200"
                  />
                ) : (
                  <div className="flex h-16 w-16 sm:h-20 sm:w-20 items-center justify-center rounded-3xl bg-gradient-to-br from-blue-600 to-indigo-700 text-white font-black text-2xl sm:text-3xl shadow-lg shadow-blue-500/25">
                    {employee.lastName?.[0] || employee.fullName?.[0]}
                  </div>
                )}
                {(canEdit || isMe) && (
                  <>
                    <button
                      onClick={() => fileInputRef.current?.click()}
                      className="absolute -bottom-1 -right-1 p-1.5 rounded-full bg-slate-900 text-white hover:bg-blue-600 shadow-md transition cursor-pointer"
                      title="Đổi ảnh đại diện"
                    >
                      <Camera className="h-3.5 w-3.5" />
                    </button>
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept="image/jpeg,image/png,image/webp,image/gif"
                      className="hidden"
                      onChange={handleAvatarUpload}
                    />
                  </>
                )}
              </div>

              <div>
                <div className="flex flex-wrap items-center gap-2 mb-1">
                  <h1 className="text-xl sm:text-2xl font-black text-slate-900">
                    {employee.fullName}
                  </h1>
                  <span className="font-mono text-xs font-bold bg-slate-100 text-slate-700 px-2 py-0.5 rounded-md">
                    {employee.employeeCode}
                  </span>
                  {isMe && (
                    <span className="rounded-full bg-blue-50 px-2 py-0.5 text-[10px] font-bold text-blue-700 border border-blue-200">
                      Hồ sơ của bạn
                    </span>
                  )}
                  {employee.isActive === false && (
                    <span className="rounded-full bg-rose-100 px-2 py-0.5 text-[10px] font-bold text-rose-800 border border-rose-200">
                      Đã thôi việc (Khóa)
                    </span>
                  )}
                </div>
                <p className="text-xs sm:text-sm font-semibold text-blue-600">
                  {employee.job} • {employee.department}
                </p>
                <div className="mt-2 flex flex-wrap items-center gap-3 text-xs text-slate-500">
                  <span className="flex items-center gap-1.5"><Mail className="h-3.5 w-3.5 text-slate-400" /> {employee.email}</span>
                  {employee.profile?.phoneNumber && (
                    <span className="flex items-center gap-1.5"><Phone className="h-3.5 w-3.5 text-slate-400" /> {employee.profile.phoneNumber}</span>
                  )}
                  <span className="flex items-center gap-1.5"><Calendar className="h-3.5 w-3.5 text-slate-400" /> Vào cty: {employee.joinedDate}</span>
                </div>
              </div>
            </div>

            <div className="flex flex-col sm:items-end gap-2 w-full sm:w-auto">
              <div className="flex items-center gap-2">
                <span className="text-xs text-slate-500 font-medium">Hôm nay:</span>
                {todayStatusBadge(employee.todayStatus)}
              </div>
              <div className="text-[11px] text-slate-400">
                Ca làm việc: <strong className="text-slate-700 font-semibold">{employee.shiftName || 'Ca Hành Chính'}</strong>
              </div>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-xs font-bold">
          <button
            onClick={() => setActiveTab('basic')}
            className={`px-4 py-2.5 rounded-xl transition cursor-pointer flex items-center gap-2 ${
              activeTab === 'basic' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            <UserCheck className="h-4 w-4" />
            <span>Tab 1: Thông tin Chung (Công khai)</span>
          </button>

          <button
            onClick={() => setActiveTab('legal')}
            disabled={!canViewLegal}
            className={`px-4 py-2.5 rounded-xl transition flex items-center gap-2 ${
              !canViewLegal
                ? 'opacity-40 cursor-not-allowed text-slate-400'
                : activeTab === 'legal'
                ? 'bg-blue-600 text-white shadow-xs cursor-pointer'
                : 'text-slate-600 hover:bg-slate-50 cursor-pointer'
            }`}
          >
            <IdCard className="h-4 w-4" />
            <span>Tab 2: Định danh & Pháp lý</span>
            {!canViewLegal && <Lock className="h-3 w-3 ml-1" />}
          </button>

          <button
            onClick={() => setActiveTab('contract')}
            disabled={!canViewContract}
            className={`px-4 py-2.5 rounded-xl transition flex items-center gap-2 ${
              !canViewContract
                ? 'opacity-40 cursor-not-allowed text-slate-400'
                : activeTab === 'contract'
                ? 'bg-blue-600 text-white shadow-xs cursor-pointer'
                : 'text-slate-600 hover:bg-slate-50 cursor-pointer'
            }`}
          >
            <FileText className="h-4 w-4" />
            <span>Tab 3: Hợp đồng Lao động</span>
            {!canViewContract && <Lock className="h-3 w-3 ml-1" />}
          </button>

          <button
            onClick={() => setActiveTab('salary')}
            disabled={!canViewSalary}
            className={`px-4 py-2.5 rounded-xl transition flex items-center gap-2 ${
              !canViewSalary
                ? 'opacity-40 cursor-not-allowed text-slate-400'
                : activeTab === 'salary'
                ? 'bg-blue-600 text-white shadow-xs cursor-pointer'
                : 'text-slate-600 hover:bg-slate-50 cursor-pointer'
            }`}
          >
            <CreditCard className="h-4 w-4" />
            <span>Tab 4: Lương & Ngân hàng</span>
            {!canViewSalary && <Lock className="h-3 w-3 ml-1" />}
          </button>

          <button
            onClick={() => setActiveTab('assignment')}
            className={`px-4 py-2.5 rounded-xl transition cursor-pointer flex items-center gap-2 ${
              activeTab === 'assignment' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-50'
            }`}
          >
            <Clock className="h-4 w-4" />
            <span>Tab 5: Lịch Trình & Ca Làm Việc</span>
          </button>
        </div>

        {/* Tab Content Display */}
        <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80">
          {/* TAB 1: BASIC INFO */}
          {activeTab === 'basic' && (
            <div className="space-y-6">
              <h3 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-3">
                Thông tin chung nhân sự (Công khai toàn công ty)
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 text-xs">
                <div>
                  <span className="text-slate-400 block mb-1">Mã nhân viên:</span>
                  <span className="font-mono font-bold text-slate-900 text-sm">{employee.employeeCode}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Họ và tên:</span>
                  <span className="font-bold text-slate-900 text-sm">{employee.fullName}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Phòng ban:</span>
                  <span className="font-semibold text-slate-800">{employee.department}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Chức vụ / Vị trí:</span>
                  <span className="font-semibold text-blue-600">{employee.job}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Email công việc:</span>
                  <span className="font-mono text-slate-800">{employee.email}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Số điện thoại:</span>
                  <span className="font-mono text-slate-800">{employee.profile?.phoneNumber || 'Chưa cập nhật'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Giới tính:</span>
                  <span className="font-semibold text-slate-800">{employee.gender || 'Nam'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Ngày sinh:</span>
                  <span className="font-mono text-slate-800">{employee.birthDate || 'Chưa cập nhật'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Ngày gia nhập công ty:</span>
                  <span className="font-mono text-slate-800 font-semibold">{employee.joinedDate}</span>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: LEGAL & IDENTITY */}
          {activeTab === 'legal' && canViewLegal && (
            <div className="space-y-6">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <h3 className="text-sm font-bold text-slate-900">
                  Thông tin định danh, thuế & bảo hiểm xã hội
                </h3>
                <span className="inline-flex items-center gap-1 text-[11px] text-amber-700 bg-amber-50 px-2.5 py-0.5 rounded-full border border-amber-200 font-semibold">
                  <Shield className="h-3.5 w-3.5" /> Dữ liệu bảo mật (Chỉ HR & Ban Giám Đốc)
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 text-xs">
                <div>
                  <span className="text-slate-400 block mb-1">Số Căn cước công dân (CCCD):</span>
                  <span className="font-mono font-bold text-slate-900 text-sm">{employee.profile?.citizenIdNumber || '001095012345'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Mã số thuế cá nhân:</span>
                  <span className="font-mono font-bold text-slate-900 text-sm">{employee.profile?.taxIdentificationNumber || '8541257896'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Mã số Bảo hiểm xã hội (BHXH):</span>
                  <span className="font-mono font-bold text-slate-900 text-sm">{employee.profile?.socialInsuranceNumber || '7912456789'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Nơi sinh / Nguyên quán:</span>
                  <span className="font-semibold text-slate-800">{employee.profile?.placeOfBirth || 'Hà Nội'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Tình trạng hôn nhân:</span>
                  <span className="font-semibold text-slate-800">{employee.profile?.maritalStatus || 'Độc thân'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Quốc tịch:</span>
                  <span className="font-semibold text-slate-800">{employee.profile?.nationality || 'Việt Nam'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Người liên hệ khẩn cấp:</span>
                  <span className="font-semibold text-slate-800">{employee.profile?.emergencyContactName || 'Chưa cập nhật'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">SĐT người liên hệ khẩn cấp:</span>
                  <span className="font-mono text-slate-800">{employee.profile?.emergencyContactPhone || 'Chưa cập nhật'}</span>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: CONTRACT */}
          {activeTab === 'contract' && canViewContract && (
            <div className="space-y-6">
              <h3 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-3">
                Thông tin Hợp đồng Lao động (user_contracts)
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 text-xs">
                <div>
                  <span className="text-slate-400 block mb-1">Loại hợp đồng:</span>
                  <span className="font-bold text-blue-700 text-sm">{employee.contract?.contractType || 'Hợp đồng lao động không xác định thời hạn'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Ngày bắt đầu hiệu lực:</span>
                  <span className="font-mono font-bold text-slate-900 text-sm">{employee.contract?.contractStartDate || employee.joinedDate}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Ngày kết thúc hợp đồng:</span>
                  <span className="font-mono text-slate-800">{employee.contract?.contractEndDate || 'Vô thời hạn'}</span>
                </div>
              </div>
            </div>
          )}

          {/* TAB 4: SALARY & BANK */}
          {activeTab === 'salary' && canViewSalary && (
            <div className="space-y-6">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3">
                <h3 className="text-sm font-bold text-slate-900">
                  Lương & Tài khoản Ngân hàng (salaries & user_bank_accounts)
                </h3>
                <span className="inline-flex items-center gap-1 text-[11px] text-rose-700 bg-rose-50 px-2.5 py-0.5 rounded-full border border-rose-200 font-bold">
                  <Shield className="h-3.5 w-3.5" /> Tuyệt mật: Trưởng phòng KHÔNG xem được
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 text-xs">
                <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200">
                  <span className="text-emerald-700 block text-[11px] font-bold mb-1">Lương cơ bản (Base Salary):</span>
                  <span className="font-mono font-black text-emerald-900 text-xl">
                    {(employee.salary?.baseSalary || 20000000).toLocaleString('vi-VN')} ₫
                  </span>
                  <span className="text-[10px] text-emerald-600 block mt-1">Chuẩn 22 ngày công thực tế</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Ngân hàng thụ hưởng:</span>
                  <span className="font-bold text-slate-900 text-sm">{employee.bankAccount?.bankName || 'Ngân hàng Vietcombank'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Số tài khoản ngân hàng:</span>
                  <span className="font-mono font-bold text-slate-900 text-sm">{employee.bankAccount?.bankAccountNumber || '012345678901'}</span>
                </div>
              </div>
            </div>
          )}

          {/* TAB 5: ASSIGNMENT & SHIFT */}
          {activeTab === 'assignment' && (
            <div className="space-y-6">
              <h3 className="text-sm font-bold text-slate-900 border-b border-slate-100 pb-3">
                Ca làm việc & Lịch trình tuần (work_shifts & work_shift_schedules)
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                <div className="p-4 rounded-2xl bg-blue-50 border border-blue-200">
                  <span className="text-blue-700 block text-[11px] font-bold mb-1">Ca làm việc áp dụng:</span>
                  <span className="font-bold text-blue-950 text-base">{employee.shiftName || 'Ca Hành Chính Chuẩn'}</span>
                  <p className="text-[11px] text-blue-600 mt-1">Thời gian: {employee.shiftStartTime || '08:00'} - {employee.shiftEndTime || '17:30'}</p>
                </div>
                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200">
                  <span className="text-slate-500 block text-[11px] font-bold mb-1">Ngày nghỉ trong tuần:</span>
                  <span className="font-bold text-slate-800 text-base">Thứ 7 & Chủ Nhật</span>
                  <p className="text-[11px] text-slate-500 mt-1">Đảm bảo luật lao động: ≤ 8h/ngày và ≤ 48h/tuần</p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Edit Modal (HR only) */}
        {isEditModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 overflow-y-auto">
            <div className="relative w-full max-w-2xl rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200 my-8 max-h-[90vh] overflow-y-auto">
              <button
                onClick={() => setIsEditModalOpen(false)}
                className="absolute right-4 top-4 rounded-full p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition"
              >
                <X className="h-5 w-5" />
              </button>

              <h2 className="text-lg font-black text-slate-900 mb-1">
                Chỉnh sửa thông tin hồ sơ nhân viên
              </h2>
              <p className="text-xs text-slate-500 mb-6">
                Chỉ Phòng Nhân Sự (HR) và Ban Giám Đốc mới có quyền cập nhật các trường này.
              </p>

              <form onSubmit={handleSave} className="space-y-4 text-xs">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Họ đệm</label>
                    <input
                      type="text"
                      value={formData.lastName}
                      onChange={e => setFormData({ ...formData, lastName: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Tên</label>
                    <input
                      type="text"
                      value={formData.firstName}
                      onChange={e => setFormData({ ...formData, firstName: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Số CCCD</label>
                    <input
                      type="text"
                      value={formData.citizenIdNumber}
                      onChange={e => setFormData({ ...formData, citizenIdNumber: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Mã số thuế</label>
                    <input
                      type="text"
                      value={formData.taxIdentificationNumber}
                      onChange={e => setFormData({ ...formData, taxIdentificationNumber: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Số điện thoại</label>
                    <input
                      type="text"
                      value={formData.phoneNumber}
                      onChange={e => setFormData({ ...formData, phoneNumber: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Email cá nhân</label>
                    <input
                      type="email"
                      value={formData.personalEmail}
                      onChange={e => setFormData({ ...formData, personalEmail: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Lương cơ bản (VNĐ)</label>
                    <input
                      type="number"
                      value={formData.baseSalary}
                      onChange={e => setFormData({ ...formData, baseSalary: Number(e.target.value) })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono font-bold focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Số tài khoản ngân hàng</label>
                    <input
                      type="text"
                      value={formData.bankAccountNumber}
                      onChange={e => setFormData({ ...formData, bankAccountNumber: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-mono focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                </div>

                <div className="flex justify-end gap-3 pt-4 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => setIsEditModalOpen(false)}
                    className="px-4 py-2.5 rounded-xl border border-slate-300 font-bold text-slate-700 hover:bg-slate-50 transition"
                  >
                    Hủy bỏ
                  </button>
                  <button
                    type="submit"
                    className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold shadow-md shadow-blue-500/20 transition"
                  >
                    <Save className="h-4 w-4" />
                    <span>Lưu hồ sơ</span>
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
