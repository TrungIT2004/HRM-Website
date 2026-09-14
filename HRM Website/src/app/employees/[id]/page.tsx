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
  Sparkles,
  RefreshCw
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

  // Contract Modal States
  const [contractModal, setContractModal] = useState<{
    open: boolean;
    mode: 'renew' | 'create' | 'edit';
    contractId?: string;
    contractType: string;
    startDate: string;
    endDate: string;
  }>({
    open: false,
    mode: 'renew',
    contractType: 'Fixed-term',
    startDate: '',
    endDate: ''
  });
  const [contractLoading, setContractLoading] = useState(false);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 4000);
  };

  const openRenewModal = () => {
    let nextStart = '';
    if (employee.contract?.contractEndDate) {
      const d = new Date(employee.contract.contractEndDate);
      d.setDate(d.getDate() + 1);
      nextStart = d.toISOString().split('T')[0];
    } else {
      nextStart = new Date().toISOString().split('T')[0];
    }
    const dEnd = new Date(nextStart);
    dEnd.setFullYear(dEnd.getFullYear() + 1);
    const nextEnd = dEnd.toISOString().split('T')[0];

    setContractModal({
      open: true,
      mode: 'renew',
      contractType: 'Fixed-term',
      startDate: nextStart,
      endDate: nextEnd
    });
  };

  const openCreateModal = () => {
    const today = new Date().toISOString().split('T')[0];
    const dEnd = new Date();
    dEnd.setFullYear(dEnd.getFullYear() + 1);

    setContractModal({
      open: true,
      mode: 'create',
      contractType: 'Fixed-term',
      startDate: today,
      endDate: dEnd.toISOString().split('T')[0]
    });
  };

  const openEditModal = (c: any) => {
    setContractModal({
      open: true,
      mode: 'edit',
      contractId: c.contractId,
      contractType: c.contractType || 'Fixed-term',
      startDate: c.contractStartDate || '',
      endDate: c.contractEndDate || ''
    });
  };

  const handleSaveContract = async () => {
    if (!contractModal.contractType || !contractModal.startDate) {
      showToast('Vui lòng chọn loại hợp đồng và ngày bắt đầu!');
      return;
    }
    setContractLoading(true);
    try {
      let updated: EmployeeDetailed;
      if (contractModal.mode === 'renew') {
        updated = await employeeService.renewContract(userId, {
          contractType: contractModal.contractType,
          contractStartDate: contractModal.startDate,
          contractEndDate: contractModal.endDate || undefined
        });
        showToast('Gia hạn hợp đồng thành công!');
      } else if (contractModal.mode === 'create') {
        updated = await employeeService.createContract(userId, {
          contractType: contractModal.contractType,
          contractStartDate: contractModal.startDate,
          contractEndDate: contractModal.endDate || undefined
        });
        showToast('Ký hợp đồng mới thành công!');
      } else {
        updated = await employeeService.updateSpecificContract(userId, contractModal.contractId!, {
          contractType: contractModal.contractType,
          contractStartDate: contractModal.startDate,
          contractEndDate: contractModal.endDate || undefined
        });
        showToast('Cập nhật hợp đồng thành công!');
      }
      setLiveEmployee(updated);
      setContractModal(prev => ({ ...prev, open: false }));
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Có lỗi xảy ra');
    } finally {
      setContractLoading(false);
    }
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
    ? employee.profilePicUrl
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
              {/* Active Contract Card */}
              <div className="rounded-2xl border border-blue-200 bg-gradient-to-br from-blue-50/70 to-indigo-50/40 p-6">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-blue-100 pb-4 mb-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-blue-600 text-white flex items-center justify-center font-bold">
                      <FileText className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h3 className="text-base font-bold text-slate-900">
                          Hợp Đồng Lao Động Hiện Tại
                        </h3>
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-700 bg-emerald-100/80 px-2 py-0.5 rounded-full">
                          <CheckCircle2 className="w-3 h-3" /> Đang hiệu lực
                        </span>
                      </div>
                      <p className="text-xs text-slate-500">Mã hợp đồng: {employee.contract?.contractId || 'HĐ-HIEN-HANH'}</p>
                    </div>
                  </div>

                  {canEdit && (
                    <div className="flex items-center gap-2 flex-wrap">
                      <button
                        onClick={openRenewModal}
                        className="px-3.5 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold shadow-xs transition-colors flex items-center gap-1.5"
                      >
                        <RefreshCw className="w-3.5 h-3.5" />
                        <span>Gia Hạn HĐ</span>
                      </button>

                      <button
                        onClick={() => openEditModal(employee.contract)}
                        className="px-3 py-2 bg-white hover:bg-slate-50 text-slate-700 border border-slate-200 rounded-xl text-xs font-semibold transition-colors flex items-center gap-1.5"
                      >
                        <Edit3 className="w-3.5 h-3.5" />
                        <span>Chỉnh Sửa</span>
                      </button>

                      <button
                        onClick={openCreateModal}
                        className="px-3 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-semibold transition-colors"
                      >
                        + Ký HĐ Mới
                      </button>
                    </div>
                  )}
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 text-xs">
                  <div>
                    <span className="text-slate-500 block mb-1 font-medium">Loại hợp đồng:</span>
                    <span className="font-bold text-blue-900 text-sm">
                      {employee.contract?.contractType === 'Indefinite'
                        ? 'Không xác định thời hạn (Indefinite)'
                        : employee.contract?.contractType === 'Fixed-term'
                        ? 'Xác định thời hạn (Fixed-term)'
                        : employee.contract?.contractType === 'Probation'
                        ? 'Hợp đồng Thử việc (Probation)'
                        : employee.contract?.contractType || 'Xác định thời hạn'}
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-500 block mb-1 font-medium">Ngày bắt đầu hiệu lực:</span>
                    <span className="font-mono font-bold text-slate-900 text-sm">
                      {employee.contract?.contractStartDate || employee.joinedDate}
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-500 block mb-1 font-medium">Ngày kết thúc hợp đồng:</span>
                    <span className="font-mono font-bold text-slate-900 text-sm">
                      {employee.contract?.contractEndDate || 'Vô thời hạn'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Contract History Table */}
              <div className="space-y-3 pt-2">
                <div className="flex items-center justify-between">
                  <h4 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                    <Clock className="w-4 h-4 text-slate-500" />
                    <span>Lịch Sử Ký Kết Hợp Đồng ({employee.contracts?.length || 1})</span>
                  </h4>
                </div>

                <div className="overflow-x-auto border border-slate-200 rounded-xl bg-white">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 text-slate-600 font-semibold border-b border-slate-200 uppercase tracking-wider text-[11px]">
                      <tr>
                        <th className="px-4 py-3">Loại Hợp Đồng</th>
                        <th className="px-4 py-3">Ngày Bắt Đầu</th>
                        <th className="px-4 py-3">Ngày Kết Thúc</th>
                        <th className="px-4 py-3 text-center">Trạng Thái</th>
                        {canEdit && <th className="px-4 py-3 text-right">Thao Tác</th>}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {(employee.contracts && employee.contracts.length > 0 ? employee.contracts : [employee.contract]).map((c, idx) => {
                        if (!c) return null;
                        const isCurrent = c.isActive !== false;
                        return (
                          <tr key={c.contractId || idx} className={`hover:bg-slate-50/80 transition-colors ${isCurrent ? 'bg-blue-50/30 font-medium' : ''}`}>
                            <td className="px-4 py-3 text-slate-900">
                              <span className="font-bold">
                                {c.contractType === 'Indefinite'
                                  ? 'Không xác định thời hạn'
                                  : c.contractType === 'Fixed-term'
                                  ? 'Xác định thời hạn'
                                  : c.contractType === 'Probation'
                                  ? 'Thử việc'
                                  : c.contractType || '---'}
                              </span>
                              <span className="text-[10px] text-slate-400 block font-mono">({c.contractType})</span>
                            </td>
                            <td className="px-4 py-3 font-mono text-slate-700">{c.contractStartDate || '---'}</td>
                            <td className="px-4 py-3 font-mono text-slate-700">{c.contractEndDate || 'Vô thời hạn'}</td>
                            <td className="px-4 py-3 text-center">
                              {isCurrent ? (
                                <span className="inline-block px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800">
                                  Đang hiệu lực
                                </span>
                              ) : (
                                <span className="inline-block px-2 py-0.5 rounded-full text-[10px] font-medium bg-slate-100 text-slate-600">
                                  Đã hết hạn
                                </span>
                              )}
                            </td>
                            {canEdit && (
                              <td className="px-4 py-3 text-right">
                                <button
                                  onClick={() => openEditModal(c)}
                                  className="text-blue-600 hover:text-blue-800 font-semibold text-xs"
                                >
                                  Sửa
                                </button>
                              </td>
                            )}
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
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

        {/* Contract Modal (Renew / Create / Edit) */}
        {contractModal.open && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
            <div className="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl border border-slate-100 space-y-4">
              <button
                onClick={() => setContractModal(prev => ({ ...prev, open: false }))}
                className="absolute right-4 top-4 rounded-full p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition"
              >
                <X className="h-5 w-5" />
              </button>

              <div className="flex items-center gap-3 border-b border-slate-100 pb-3">
                <div className="w-10 h-10 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold">
                  <FileText className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-slate-900">
                    {contractModal.mode === 'renew'
                      ? 'Gia Hạn Hợp Đồng Lao Động'
                      : contractModal.mode === 'create'
                      ? 'Ký Hợp Đồng Lao Động Mới'
                      : 'Chỉnh Sửa Thông Tin Hợp Đồng'}
                  </h3>
                  <p className="text-xs text-slate-500">{employee.fullName} ({employee.employeeCode})</p>
                </div>
              </div>

              {contractModal.mode === 'renew' && (
                <div className="bg-blue-50/70 border border-blue-200 rounded-xl p-3 text-xs text-blue-800">
                  ℹ️ Khi gia hạn, hợp đồng hiện tại sẽ tự động chuyển sang <strong>Đã hết hạn</strong>, và hợp đồng mới này sẽ trở thành <strong>Đang hiệu lực</strong>.
                </div>
              )}

              <div className="space-y-3 text-xs">
                <div>
                  <label className="block font-semibold text-slate-700 mb-1">
                    Loại hợp đồng <span className="text-rose-500">*</span>
                  </label>
                  <select
                    value={contractModal.contractType}
                    onChange={e => setContractModal(prev => ({ ...prev, contractType: e.target.value }))}
                    className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                  >
                    <option value="Fixed-term">Hợp đồng Xác định thời hạn (Fixed-term)</option>
                    <option value="Indefinite">Hợp đồng Không xác định thời hạn (Indefinite)</option>
                    <option value="Probation">Hợp đồng Thử việc (Probation)</option>
                  </select>
                </div>

                <div>
                  <label className="block font-semibold text-slate-700 mb-1">
                    Ngày bắt đầu hiệu lực <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="date"
                    value={contractModal.startDate}
                    onChange={e => setContractModal(prev => ({ ...prev, startDate: e.target.value }))}
                    className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                  />
                </div>

                {contractModal.contractType !== 'Indefinite' && (
                  <div>
                    <label className="block font-semibold text-slate-700 mb-1">
                      Ngày kết thúc hợp đồng
                    </label>
                    <input
                      type="date"
                      value={contractModal.endDate}
                      onChange={e => setContractModal(prev => ({ ...prev, endDate: e.target.value }))}
                      className="w-full rounded-xl border border-slate-300 p-2.5 font-medium focus:border-blue-600 focus:outline-hidden"
                    />
                  </div>
                )}
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setContractModal(prev => ({ ...prev, open: false }))}
                  className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl transition"
                >
                  Hủy bỏ
                </button>
                <button
                  type="button"
                  disabled={contractLoading}
                  onClick={handleSaveContract}
                  className="flex items-center gap-1.5 px-4 py-2 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-xl shadow-xs transition"
                >
                  {contractLoading ? (
                    <>
                      <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                      <span>Đang lưu...</span>
                    </>
                  ) : (
                    <>
                      <Save className="w-3.5 h-3.5" />
                      <span>Xác nhận lưu</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
