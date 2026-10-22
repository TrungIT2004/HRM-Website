'use client';

import React, { useState, useEffect, use, useRef } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import TodayStatusBadge from '@/components/TodayStatusBadge';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { EmployeeDetailed, TodayAttendanceStatus } from '@/types';
import { employeeService } from '@/services/employeeService';
import { formatDateVN } from '@/utils/format';
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
  Sparkles,
  RefreshCw,
  Sun,
  Moon,
  Coffee,
  CalendarDays
} from 'lucide-react';

// ponytail: nhận thêm 2 prop để /my-profile tái dùng nguyên trang này
// thay vì phải nhân bản ~1700 dòng sang component riêng.
// EMPTY_PARAMS phải ở module scope: Promise tạo mới mỗi render sẽ khiến `use()` ném React #482.
const EMPTY_PARAMS = Promise.resolve({ id: '' });

export default function EmployeeDetailPage({
  params,
  userIdOverride,
  embedded
}: {
  params?: Promise<{ id: string }>;
  userIdOverride?: string;
  embedded?: boolean;
}) {
  const resolvedParams = use(params ?? EMPTY_PARAMS);
  const userId = userIdOverride || resolvedParams.id;

  const { isHR, isExecutive, currentUser, can } = useAuth();
  const { employeeDetails } = useHRMData();

  const [activeTab, setActiveTab] = useState<'basic' | 'legal' | 'contract' | 'salary' | 'assignment'>('basic');
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [liveEmployee, setLiveEmployee] = useState<EmployeeDetailed | null>(null);
  const [toastMsg, setToastMsg] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isUploadingAvatar, setIsUploadingAvatar] = useState(false);

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
    if (employee?.contract?.contractEndDate) {
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
  const employee: EmployeeDetailed | null = liveEmployee || employeeDetails[userId] || null;

  // Form states for modal editing (Must be declared before any conditional return)
  const [formData, setFormData] = useState({
    firstName: employee?.firstName || '',
    lastName: employee?.lastName || '',
    phoneNumber: employee?.profile?.phoneNumber || '',
    personalEmail: employee?.profile?.personalEmail || '',
    placeOfBirth: employee?.profile?.placeOfBirth || '',
    maritalStatus: employee?.profile?.maritalStatus || 'Độc thân',
    nationality: employee?.profile?.nationality || 'Việt Nam',
    citizenIdNumber: employee?.profile?.citizenIdNumber || '',
    socialInsuranceNumber: employee?.profile?.socialInsuranceNumber || '',
    taxIdentificationNumber: employee?.profile?.taxIdentificationNumber || '',
    emergencyContactName: employee?.profile?.emergencyContactName || '',
    emergencyContactPhone: employee?.profile?.emergencyContactPhone || '',
    contractType: employee?.contract?.contractType || 'Không xác định thời hạn',
    contractStartDate: employee?.contract?.contractStartDate || '2022-01-01',
    contractEndDate: employee?.contract?.contractEndDate || '',
    // Không có dữ liệu thì để trống, không bịa số tiền/tài khoản giả
    baseSalary: employee?.salary?.baseSalary || 0,
    bankName: employee?.payroll?.bankName || employee?.bankAccount?.bankName || '',
    bankAccountNumber: employee?.payroll?.bankAccountNumber || employee?.bankAccount?.accountNumber || '',
    department: employee?.department || '',
    job: employee?.job || '',
    shiftName: employee?.shiftName || ''
  });

  useEffect(() => {
    if (employee) {
      setFormData({
        firstName: employee.firstName || '',
        lastName: employee.lastName || '',
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
        baseSalary: employee.salary?.baseSalary || 0,
        bankName: employee.payroll?.bankName || employee.bankAccount?.bankName || '',
        bankAccountNumber: employee.payroll?.bankAccountNumber || employee.bankAccount?.accountNumber || '',
        department: employee.department || '',
        job: employee.job || '',
        shiftName: employee.shiftName || ''
      });
    }
  }, [employee]);

  if (!employee) {
    const loading = (
        <div className="flex flex-col items-center justify-center min-h-[60vh] text-center p-8 space-y-4">
          <div className="h-12 w-12 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center">
            <RefreshCw className="h-6 w-6 animate-spin" />
          </div>
          <div>
            <h2 className="text-base font-bold text-slate-900">Đang tải hồ sơ nhân sự...</h2>
            <p className="text-xs text-slate-500 mt-1">Đang đồng bộ dữ liệu hồ sơ từ máy chủ Backend.</p>
          </div>
          <Link
            href="/employees"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-blue-600 hover:text-blue-700 mt-2"
          >
            <ArrowLeft className="h-4 w-4" />
            <span>Quay lại Danh bạ nhân sự</span>
          </Link>
        </div>
    );
    return embedded ? loading : <AppShell>{loading}</AppShell>;
  }

  const isMe = currentUser?.userId === userId;
  const isTargetSameDeptHead = !!(
    currentUser?.job?.startsWith('Department Head') && 
    currentUser?.department === employee.department
  );

  // ponytail: so sánh phòng ban thô, KHÔNG dùng cờ isHR — isHR đã bị OR isExecutive nên sẽ cho
  // Executive thấy nút trong khi backend checkHRAccess (EmployeeService.java:743) chỉ cho HR
  const isHRRaw = (currentUser?.department || '').toLowerCase() === 'human resources';
  // 3 tab dưới chứa dữ liệu nhạy cảm nên backend tách EMPLOYEE_VIEW_ALL khỏi quyền gốc.
  // Phải khai báo giống hệt ở đây, nếu không sẽ khóa tab trong khi API vẫn trả dữ liệu.
  const canViewAllProfile = can('EMPLOYEE_VIEW_ALL');
  const canViewLegal = isMe || isHR || isExecutive || canViewAllProfile;
  const canViewContract = isMe || isTargetSameDeptHead || isHR || isExecutive || canViewAllProfile;
  const canViewSalary = isMe || isHR || isExecutive || canViewAllProfile;
  const canEdit = isHRRaw;
  // ponytail: SoD hợp đồng — HR thật (khớp check backend equalsIgnoreCase) được sửa HĐ người khác, không bao giờ tự sửa; Executive view-only (backend 403 mọi write)
  const canEditContract = isHRRaw && !isMe;


  const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    e.target.value = ''; // ponytail: reset để chọn lại cùng 1 file vẫn bắn onChange
    setIsUploadingAvatar(true);
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
    } finally {
      setIsUploadingAvatar(false);
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

  // ponytail: /my-profile tái dùng nguyên trang này nên phải bỏ AppShell lần nữa, nếu không sẽ lồng 2 sidebar.
  const body = (
      <div className="space-y-6">
        {toastMsg && (
          <div className="fixed top-20 right-6 z-50 rounded-2xl bg-slate-900 text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold animate-in slide-in-from-top-4">
            <CheckCircle2 className="h-5 w-5 text-emerald-400" />
            <span>{toastMsg}</span>
          </div>
        )}

        {/* Back navigation & Edit Button */}
        <div className="flex flex-wrap items-center justify-between gap-3">
          {!embedded && (
          <Link
            href="/employees"
            className="inline-flex items-center gap-2 text-xs font-bold text-slate-600 hover:text-blue-600 transition"
          >
            <ArrowLeft className="h-4 w-4" />
            <span>Quay lại Danh bạ Nhân sự</span>
          </Link>
          )}

          {/* Khóa / mở tài khoản chỉ làm ở tab Quản lý tài khoản của /admin — bỏ nút ở đây. */}
          <div className="flex items-center gap-2">
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
                      disabled={isUploadingAvatar}
                      className="absolute -bottom-1 -right-1 p-1.5 rounded-full bg-slate-900 text-white hover:bg-blue-600 shadow-md transition cursor-pointer disabled:opacity-60"
                      title="Đổi ảnh đại diện"
                    >
                      {isUploadingAvatar ? (
                        <RefreshCw className="h-3.5 w-3.5 animate-spin" />
                      ) : (
                        <Camera className="h-3.5 w-3.5" />
                      )}
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
                  <span className="flex items-center gap-1.5"><Calendar className="h-3.5 w-3.5 text-slate-400" /> Vào cty: {formatDateVN(employee.joinedDate)}</span>
                </div>
              </div>
            </div>

            <div className="flex flex-col sm:items-end gap-2 w-full sm:w-auto">
              <div className="flex items-center gap-2">
                <span className="text-xs text-slate-500 font-medium">Hôm nay:</span>
                <TodayStatusBadge status={employee.todayStatus} overtime={employee.todayOvertimeStatus} />
              </div>
              <div className="text-[11px] text-slate-400">
                Ca làm việc: <strong className="text-slate-700 font-semibold">{employee.shiftName || 'Ca Hành Chính'}</strong>
              </div>
            </div>
          </div>
        </div>

        {/* Tab Navigation */}
        <div role="tablist" className="rounded-2xl bg-white p-1.5 border border-slate-200 shadow-xs flex flex-wrap gap-1 text-sm font-extrabold">
          <button
            role="tab"
            aria-selected={activeTab === 'basic'}
            onClick={() => setActiveTab('basic')}
            className={`px-4 py-2.5 rounded-xl transition cursor-pointer flex items-center gap-2 ${
              activeTab === 'basic' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-700 hover:bg-slate-50'
            }`}
          >
            <UserCheck className="h-[18px] w-[18px]" aria-hidden="true" />
            <span>Thông tin Chung</span>
          </button>

          <button
            role="tab"
            aria-selected={activeTab === 'legal'}
            onClick={() => setActiveTab('legal')}
            disabled={!canViewLegal}
            className={`px-4 py-2.5 rounded-xl transition flex items-center gap-2 ${
              !canViewLegal
                ? 'opacity-40 cursor-not-allowed text-slate-400'
                : activeTab === 'legal'
                ? 'bg-blue-600 text-white shadow-xs cursor-pointer'
                : 'text-slate-700 hover:bg-slate-50 cursor-pointer'
            }`}
          >
            <IdCard className="h-[18px] w-[18px]" aria-hidden="true" />
            <span>Định danh & Pháp lý</span>
            {!canViewLegal && <Lock className="h-3.5 w-3.5" aria-hidden="true" />}
          </button>

          <button
            role="tab"
            aria-selected={activeTab === 'contract'}
            onClick={() => setActiveTab('contract')}
            disabled={!canViewContract}
            className={`px-4 py-2.5 rounded-xl transition flex items-center gap-2 ${
              !canViewContract
                ? 'opacity-40 cursor-not-allowed text-slate-400'
                : activeTab === 'contract'
                ? 'bg-blue-600 text-white shadow-xs cursor-pointer'
                : 'text-slate-700 hover:bg-slate-50 cursor-pointer'
            }`}
          >
            <FileText className="h-[18px] w-[18px]" aria-hidden="true" />
            <span>Hợp đồng Lao động</span>
            {!canViewContract && <Lock className="h-3.5 w-3.5" aria-hidden="true" />}
          </button>

          <button
            role="tab"
            aria-selected={activeTab === 'salary'}
            onClick={() => setActiveTab('salary')}
            disabled={!canViewSalary}
            className={`px-4 py-2.5 rounded-xl transition flex items-center gap-2 ${
              !canViewSalary
                ? 'opacity-40 cursor-not-allowed text-slate-400'
                : activeTab === 'salary'
                ? 'bg-blue-600 text-white shadow-xs cursor-pointer'
                : 'text-slate-700 hover:bg-slate-50 cursor-pointer'
            }`}
          >
            <CreditCard className="h-[18px] w-[18px]" aria-hidden="true" />
            <span>Lương & Ngân hàng</span>
            {!canViewSalary && <Lock className="h-3.5 w-3.5" aria-hidden="true" />}
          </button>

          <button
            role="tab"
            aria-selected={activeTab === 'assignment'}
            onClick={() => setActiveTab('assignment')}
            className={`px-4 py-2.5 rounded-xl transition cursor-pointer flex items-center gap-2 ${
              activeTab === 'assignment' ? 'bg-blue-600 text-white shadow-xs' : 'text-slate-700 hover:bg-slate-50'
            }`}
          >
            <Clock className="h-[18px] w-[18px]" aria-hidden="true" />
            <span>Lịch Trình & Ca Làm Việc</span>
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
                  <span className="font-mono text-slate-800">{formatDateVN(employee.birthDate) || 'Chưa cập nhật'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Ngày gia nhập công ty:</span>
                  <span className="font-mono text-slate-800 font-semibold">{formatDateVN(employee.joinedDate)}</span>
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
                      {/* <p className="text-xs text-slate-500">Mã hợp đồng: {employee.contract?.contractId || 'HĐ-HIEN-HANH'}</p> */}
                    </div>
                  </div>

                  {canEditContract && (
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
                        ? 'Không xác định thời hạn'
                        : employee.contract?.contractType === 'Fixed-term'
                        ? 'Xác định thời hạn'
                        : employee.contract?.contractType === 'Probation'
                        ? 'Hợp đồng Thử việc'
                        : employee.contract?.contractType || 'Xác định thời hạn'}
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-500 block mb-1 font-medium">Ngày bắt đầu hiệu lực:</span>
                    <span className="font-mono font-bold text-slate-900 text-sm">
                      {formatDateVN(employee.contract?.contractStartDate) || formatDateVN(employee.joinedDate)}
                    </span>
                  </div>

                  <div>
                    <span className="text-slate-500 block mb-1 font-medium">Ngày kết thúc hợp đồng:</span>
                    <span className="font-mono font-bold text-slate-900 text-sm">
                      {formatDateVN(employee.contract?.contractEndDate) || 'Vô thời hạn'}
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
                        {canEditContract && <th className="px-4 py-3 text-right">Thao Tác</th>}
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
                            </td>
                            <td className="px-4 py-3 font-mono text-slate-700">{formatDateVN(c.contractStartDate) || '---'}</td>
                            <td className="px-4 py-3 font-mono text-slate-700">{formatDateVN(c.contractEndDate) || 'Vô thời hạn'}</td>
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
                            {canEditContract && (
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
                  Lương & Tài khoản Ngân hàng
                </h3>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 text-xs">
                <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200">
                  <span className="text-emerald-700 block text-[11px] font-bold mb-1">Lương cơ bản:</span>
                  <span className="font-mono font-black text-emerald-900 text-xl">
                    {employee.salary?.baseSalary
                      ? employee.salary.baseSalary.toLocaleString('vi-VN') + ' ₫'
                      : <span className="text-sm font-bold text-slate-400">Chưa cấu hình</span>}
                  </span>
                  <span className="text-[10px] text-emerald-600 block mt-1">Chuẩn 22 ngày công thực tế</span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Ngân hàng thụ hưởng:</span>
                  <span className="font-bold text-slate-900 text-sm">{employee.payroll?.bankName || <span className="text-slate-400">Chưa cấu hình</span>}</span>
                  {employee.payroll?.bankCode && (
                    <span className="block text-[10px] text-slate-400 font-mono mt-0.5">BIN {employee.payroll.bankCode}</span>
                  )}
                </div>
                <div>
                  <span className="text-slate-400 block mb-1">Số tài khoản ngân hàng:</span>
                  <span className="font-mono font-bold text-slate-900 text-sm">{employee.payroll?.bankAccountNumber || <span className="text-slate-400">Chưa cấu hình</span>}</span>
                  {employee.payroll?.accountHolderName && (
                    <span className="block text-[10px] text-slate-500 mt-0.5">Chủ tài khoản: {employee.payroll.accountHolderName}</span>
                  )}
                </div>
                {employee.payroll?.isDefaultBank && (
                  <div className="sm:col-span-2 lg:col-span-3">
                    <span className="inline-flex items-center gap-1.5 text-[11px] font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-lg px-2.5 py-1">
                      Tài khoản nhận lương
                    </span>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* TAB 5: ASSIGNMENT & SHIFT (THỜI KHÓA BIỂU HỌC SINH / LỊCH LÀM VIỆC TUẦN) */}
          {activeTab === 'assignment' && (() => {
            const rawSchedules = (employee.weeklySchedule && employee.weeklySchedule.length > 0)
              ? employee.weeklySchedule
              : [
                  { dayOfWeek: 1, dayName: 'Thứ 2', isWorking: true, startTime: employee.shiftStartTime || '08:00', endTime: employee.shiftEndTime || '17:30', restStartTime: '12:00', restEndTime: '13:30' },
                  { dayOfWeek: 2, dayName: 'Thứ 3', isWorking: true, startTime: employee.shiftStartTime || '08:00', endTime: employee.shiftEndTime || '17:30', restStartTime: '12:00', restEndTime: '13:30' },
                  { dayOfWeek: 3, dayName: 'Thứ 4', isWorking: true, startTime: employee.shiftStartTime || '08:00', endTime: employee.shiftEndTime || '17:30', restStartTime: '12:00', restEndTime: '13:30' },
                  { dayOfWeek: 4, dayName: 'Thứ 5', isWorking: true, startTime: employee.shiftStartTime || '08:00', endTime: employee.shiftEndTime || '17:30', restStartTime: '12:00', restEndTime: '13:30' },
                  { dayOfWeek: 5, dayName: 'Thứ 6', isWorking: true, startTime: employee.shiftStartTime || '08:00', endTime: employee.shiftEndTime || '17:30', restStartTime: '12:00', restEndTime: '13:30' },
                  { dayOfWeek: 6, dayName: 'Thứ 7', isWorking: false, startTime: '00:00', endTime: '00:00' },
                  { dayOfWeek: 7, dayName: 'Chủ Nhật', isWorking: false, startTime: '00:00', endTime: '00:00' },
                ];

            // Ensure 7 days sorted Monday (1) to Sunday (7)
            const sortedSchedules = [...rawSchedules].sort((a, b) => a.dayOfWeek - b.dayOfWeek);

            const calcHours = (start?: string, end?: string): number => {
              if (!start || !end) return 0;
              const [sh, sm] = start.split(':').map(Number);
              const [eh, em] = end.split(':').map(Number);
              if (isNaN(sh) || isNaN(eh)) return 0;
              const diffMin = (eh * 60 + (em || 0)) - (sh * 60 + (sm || 0));
              return Math.max(0, Math.round((diffMin / 60) * 10) / 10);
            };

            const calcDayNet = (item: any): number => {
              if (!item.isWorking || !item.startTime || !item.endTime) return 0;
              const total = calcHours(item.startTime, item.endTime);
              const rest = (item.restStartTime && item.restEndTime) ? calcHours(item.restStartTime, item.restEndTime) : 0;
              return Math.max(0, Math.round((total - rest) * 10) / 10);
            };

            const workingDaysCount = sortedSchedules.filter(s => s.isWorking).length;
            const totalWeeklyHours = sortedSchedules.reduce((acc, s) => acc + calcDayNet(s), 0);
            const restDaysNames = sortedSchedules.filter(s => !s.isWorking).map(s => s.dayName).join(' & ') || 'Không có';

            // Today highlight
            const jsDay = new Date().getDay(); // 0 is Sun, 1 is Mon...
            const todayDayOfWeek = jsDay === 0 ? 7 : jsDay;

            return (
              <div className="space-y-6">
                {/* 1. Header Overview & KPI Chips */}
                <div className="rounded-3xl border border-blue-100 bg-gradient-to-br from-blue-50/70 via-indigo-50/40 to-slate-50 p-5 sm:p-6 shadow-xs">
                  <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                    <div>
                      <div className="flex items-center gap-2 mb-1.5">
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-blue-600 text-white shadow-xs">
                          <CalendarDays className="w-3.5 h-3.5" />
                          Thời Khóa Biểu Tuần
                        </span>
                        <span className="text-[11px] font-semibold text-blue-700 bg-blue-100/70 px-2.5 py-0.5 rounded-full border border-blue-200">
                          Áp dụng chính thức
                        </span>
                      </div>
                      <h3 className="text-lg sm:text-xl font-black text-slate-900 flex items-center gap-2">
                        {employee.shiftName || 'Giờ hành chính (T2-T6)'}
                      </h3>
                      <p className="text-xs text-slate-600 mt-1 flex flex-wrap items-center gap-2">
                        <span>Khung giờ chuẩn: <strong>{employee.shiftStartTime || '08:00'} - {employee.shiftEndTime || '17:30'}</strong></span>
                        <span className="text-slate-300">•</span>
                        <span>Nghỉ trưa: <strong>12:00 - 13:30 (1h 30m)</strong></span>
                      </p>
                    </div>

                    {/* Quick Metric Badges */}
                    <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 text-xs">
                      <div className="bg-white/90 border border-slate-200/80 rounded-2xl p-3 shadow-xs">
                        <span className="text-slate-400 block text-[10px] font-bold uppercase tracking-wider">Ngày làm việc</span>
                        <span className="text-slate-900 font-black text-sm block mt-0.5">{workingDaysCount} ngày/tuần</span>
                        <span className="text-[10px] text-blue-600 font-medium">Thứ 2 - {sortedSchedules.filter(s => s.isWorking).pop()?.dayName || 'Thứ 6'}</span>
                      </div>

                      <div className="bg-white/90 border border-slate-200/80 rounded-2xl p-3 shadow-xs">
                        <span className="text-slate-400 block text-[10px] font-bold uppercase tracking-wider">Tổng thời lượng</span>
                        <span className="text-blue-900 font-black text-sm font-mono block mt-0.5">{totalWeeklyHours.toFixed(1)}h / tuần</span>
                        <span className="text-[10px] text-emerald-600 font-medium">Bình quân {(totalWeeklyHours / (workingDaysCount || 1)).toFixed(1)}h/ngày</span>
                      </div>

                      <div className="bg-white/90 border border-slate-200/80 rounded-2xl p-3 shadow-xs">
                        <span className="text-slate-400 block text-[10px] font-bold uppercase tracking-wider">Luật Lao Động</span>
                        <span className={`font-black text-sm block mt-0.5 ${totalWeeklyHours <= 48 ? 'text-emerald-700' : 'text-rose-600'}`}>
                          {totalWeeklyHours <= 48 ? 'Đạt chuẩn' : 'Vượt trần'}
                        </span>
                        <span className="text-[10px] text-slate-500 font-medium">≤ 48h/tuần, ≤ 8h/ngày</span>
                      </div>

                      <div className="bg-white/90 border border-slate-200/80 rounded-2xl p-3 shadow-xs">
                        <span className="text-slate-400 block text-[10px] font-bold uppercase tracking-wider">Ngày nghỉ tuần</span>
                        <span className="text-slate-800 font-bold text-xs truncate block mt-0.5" title={restDaysNames}>
                          {restDaysNames}
                        </span>
                        <span className="text-[10px] text-slate-500 font-medium">Nghỉ hưởng nguyên lương</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* 2. THE STUDENT TIMETABLE (BẢNG THỜI KHÓA BIỂU HỌC ĐƯỜNG) */}
                <div className="rounded-3xl border border-slate-200 bg-white shadow-sm overflow-hidden">
                  <div className="px-5 py-4 border-b border-slate-100 flex flex-wrap items-center justify-between gap-3 bg-slate-50/50">
                    <div>
                      <h4 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                        <Clock className="w-4 h-4 text-blue-600" />
                        Thời Khóa Biểu Làm Việc Chi Tiết Theo Ngày
                      </h4>
                      <p className="text-xs text-slate-500 mt-0.5">
                        Phân bố tiết làm buổi sáng, nghỉ giữa ca và buổi chiều của từng ngày trong tuần.
                      </p>
                    </div>

                    <div className="flex items-center gap-2">
                      <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-50 text-blue-700 text-xs font-bold border border-blue-200">
                        <span className="w-2 h-2 rounded-full bg-blue-600 animate-pulse"></span>
                        Cột có viền xanh là Hôm nay
                      </span>
                    </div>
                  </div>

                  {/* Timetable Matrix */}
                  <div className="overflow-x-auto">
                    <table className="w-full text-xs text-left border-collapse min-w-[760px]">
                      <thead>
                        <tr className="border-b border-slate-200 bg-slate-100/70">
                          <th className="p-3.5 font-bold text-slate-700 w-44 min-w-[170px] border-r border-slate-200">
                            <div className="flex items-center gap-1.5 text-slate-800 uppercase tracking-wider text-[10px]">
                              <CalendarDays className="w-3.5 h-3.5 text-slate-500" />
                              Khung Giờ / Thứ
                            </div>
                          </th>
                          {sortedSchedules.map((s) => {
                            const isToday = s.dayOfWeek === todayDayOfWeek;
                            return (
                              <th
                                key={s.dayOfWeek}
                                className={`p-3 text-center border-r border-slate-200 last:border-r-0 transition ${
                                  isToday
                                    ? 'bg-blue-100/60 font-black text-blue-900'
                                    : s.isWorking
                                    ? 'bg-slate-50/70 text-slate-900'
                                    : 'bg-slate-100/50 text-slate-500'
                                }`}
                              >
                                <div className="flex flex-col items-center gap-1">
                                  {isToday && (
                                    <span className="px-2 py-0.5 rounded-full bg-blue-600 text-white text-[9px] font-black uppercase tracking-wider shadow-xs animate-bounce">
                                      Hôm nay
                                    </span>
                                  )}
                                  <span className="font-black text-sm">{s.dayName}</span>
                                  <span
                                    className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${
                                      s.isWorking
                                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                        : 'bg-slate-100 text-slate-500 border-slate-200'
                                    }`}
                                  >
                                    {s.isWorking ? 'Làm việc' : 'Nghỉ tuần'}
                                  </span>
                                </div>
                              </th>
                            );
                          })}
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {/* Hàng 1: Ca Sáng */}
                        <tr className="hover:bg-slate-50/50 transition">
                          <td className="p-3.5 font-bold text-slate-800 bg-slate-50/40 border-r border-slate-200">
                            <div className="flex items-start gap-2.5">
                              <div className="p-2 rounded-xl bg-blue-100/80 text-blue-700 shrink-0">
                                <Sun className="w-4 h-4" />
                              </div>
                              <div>
                                <span className="font-black text-slate-900 block text-xs">🌅 Buổi Sáng</span>
                                <span className="text-[10px] text-slate-500 block font-normal">Vào ca - Nghỉ trưa</span>
                              </div>
                            </div>
                          </td>
                          {sortedSchedules.map((s) => {
                            const isToday = s.dayOfWeek === todayDayOfWeek;
                            const morningEnd = s.restStartTime || '12:00';
                            const morningHours = s.isWorking ? calcHours(s.startTime, morningEnd) : 0;
                            return (
                              <td
                                key={s.dayOfWeek}
                                className={`p-2.5 text-center border-r border-slate-100 last:border-r-0 ${
                                  isToday ? 'bg-blue-50/30' : ''
                                }`}
                              >
                                {s.isWorking ? (
                                  <div className="rounded-xl border border-blue-200/90 bg-blue-50/60 p-2.5 shadow-2xs hover:shadow-xs transition">
                                    <span className="font-mono font-black text-blue-950 text-xs block">
                                      {s.startTime} - {morningEnd}
                                    </span>
                                    <span className="text-[10px] font-bold text-blue-600 block mt-1">
                                      {morningHours.toFixed(1)} giờ làm
                                    </span>
                                  </div>
                                ) : (
                                  <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50/50 p-2.5 text-slate-300">
                                    <span className="font-bold text-sm block">—</span>
                                    <span className="text-[10px] font-medium text-slate-400 block mt-0.5">Nghỉ ca</span>
                                  </div>
                                )}
                              </td>
                            );
                          })}
                        </tr>

                        {/* Hàng 2: Nghỉ Giữa Ca (Ăn Trưa) */}
                        <tr className="hover:bg-slate-50/50 transition">
                          <td className="p-3.5 font-bold text-slate-800 bg-slate-50/40 border-r border-slate-200">
                            <div className="flex items-start gap-2.5">
                              <div className="p-2 rounded-xl bg-amber-100/80 text-amber-700 shrink-0">
                                <Coffee className="w-4 h-4" />
                              </div>
                              <div>
                                <span className="font-black text-slate-900 block text-xs">🥪 Nghỉ Giữa Ca</span>
                                <span className="text-[10px] text-slate-500 block font-normal">Ăn trưa & Tái tạo sức</span>
                              </div>
                            </div>
                          </td>
                          {sortedSchedules.map((s) => {
                            const isToday = s.dayOfWeek === todayDayOfWeek;
                            const restStart = s.restStartTime || '12:00';
                            const restEnd = s.restEndTime || '13:30';
                            const restH = (s.isWorking && s.restStartTime && s.restEndTime) ? calcHours(restStart, restEnd) : 0;
                            return (
                              <td
                                key={s.dayOfWeek}
                                className={`p-2.5 text-center border-r border-slate-100 last:border-r-0 ${
                                  isToday ? 'bg-blue-50/30' : ''
                                }`}
                              >
                                {s.isWorking && s.restStartTime && s.restEndTime ? (
                                  <div className="rounded-xl border border-amber-200/90 bg-amber-50/60 p-2 shadow-2xs hover:shadow-xs transition">
                                    <span className="font-mono font-black text-amber-950 text-xs block">
                                      {restStart} - {restEnd}
                                    </span>
                                    <span className="text-[10px] font-bold text-amber-700 block mt-0.5">
                                      {restH === 1.5 ? '1h 30m nghỉ' : `${restH}h nghỉ`}
                                    </span>
                                  </div>
                                ) : (
                                  <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50/50 p-2 text-slate-300">
                                    <span className="font-bold text-sm block">—</span>
                                    <span className="text-[10px] font-medium text-slate-400 block mt-0.5">Không có</span>
                                  </div>
                                )}
                              </td>
                            );
                          })}
                        </tr>

                        {/* Hàng 3: Ca Chiều */}
                        <tr className="hover:bg-slate-50/50 transition">
                          <td className="p-3.5 font-bold text-slate-800 bg-slate-50/40 border-r border-slate-200">
                            <div className="flex items-start gap-2.5">
                              <div className="p-2 rounded-xl bg-indigo-100/80 text-indigo-700 shrink-0">
                                <Clock className="w-4 h-4" />
                              </div>
                              <div>
                                <span className="font-black text-slate-900 block text-xs">🌇 Buổi Chiều</span>
                                <span className="text-[10px] text-slate-500 block font-normal">Chiều - Tan ca về</span>
                              </div>
                            </div>
                          </td>
                          {sortedSchedules.map((s) => {
                            const isToday = s.dayOfWeek === todayDayOfWeek;
                            const afternoonStart = s.restEndTime || '13:30';
                            const afternoonHours = s.isWorking ? calcHours(afternoonStart, s.endTime) : 0;
                            return (
                              <td
                                key={s.dayOfWeek}
                                className={`p-2.5 text-center border-r border-slate-100 last:border-r-0 ${
                                  isToday ? 'bg-blue-50/30' : ''
                                }`}
                              >
                                {s.isWorking ? (
                                  <div className="rounded-xl border border-indigo-200/90 bg-indigo-50/60 p-2.5 shadow-2xs hover:shadow-xs transition">
                                    <span className="font-mono font-black text-indigo-950 text-xs block">
                                      {afternoonStart} - {s.endTime}
                                    </span>
                                    <span className="text-[10px] font-bold text-indigo-600 block mt-1">
                                      {afternoonHours.toFixed(1)} giờ làm
                                    </span>
                                  </div>
                                ) : (
                                  <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50/50 p-2.5 text-slate-300">
                                    <span className="font-bold text-sm block">—</span>
                                    <span className="text-[10px] font-medium text-slate-400 block mt-0.5">Nghỉ ca</span>
                                  </div>
                                )}
                              </td>
                            );
                          })}
                        </tr>

                        {/* Hàng 4: Thực Làm Trong Ngày */}
                        <tr className="hover:bg-slate-50/50 transition bg-slate-50/30">
                          <td className="p-3.5 font-bold text-slate-800 bg-slate-100/50 border-r border-slate-200">
                            <div className="flex items-start gap-2.5">
                              <div className="p-2 rounded-xl bg-emerald-100/80 text-emerald-700 shrink-0">
                                <CheckCircle2 className="w-4 h-4" />
                              </div>
                              <div>
                                <span className="font-black text-slate-900 block text-xs">⏱️ Thực Làm Ngày</span>
                                <span className="text-[10px] text-slate-500 block font-normal">Trừ giờ nghỉ trưa</span>
                              </div>
                            </div>
                          </td>
                          {sortedSchedules.map((s) => {
                            const isToday = s.dayOfWeek === todayDayOfWeek;
                            const net = calcDayNet(s);
                            return (
                              <td
                                key={s.dayOfWeek}
                                className={`p-2.5 text-center border-r border-slate-100 last:border-r-0 ${
                                  isToday ? 'bg-blue-50/40' : ''
                                }`}
                              >
                                {s.isWorking ? (
                                  <div className="rounded-xl border border-emerald-200 bg-emerald-50/80 p-2 text-center shadow-xs">
                                    <span className="font-mono font-black text-emerald-900 text-sm block">
                                      {net.toFixed(1)}h
                                    </span>
                                    <span className="text-[9px] font-bold text-emerald-700 block uppercase">
                                      Chuẩn 1 công
                                    </span>
                                  </div>
                                ) : (
                                  <div className="rounded-xl border border-slate-200 bg-slate-100/70 p-2 text-center">
                                    <span className="font-mono font-bold text-slate-400 text-sm block">0h</span>
                                    <span className="text-[9px] font-medium text-slate-400 block uppercase">Nghỉ tuần</span>
                                  </div>
                                )}
                              </td>
                            );
                          })}
                        </tr>

                        {/* Hàng 5: Trạng Thái Đi Làm */}
                        <tr className="hover:bg-slate-50/50 transition">
                          <td className="p-3.5 font-bold text-slate-800 bg-slate-50/40 border-r border-slate-200">
                            <span className="font-black text-slate-900 block text-xs">🏷️ Trạng Thái Ca</span>
                            <span className="text-[10px] text-slate-500 block font-normal">Quy định chấm công</span>
                          </td>
                          {sortedSchedules.map((s) => {
                            const isToday = s.dayOfWeek === todayDayOfWeek;
                            return (
                              <td
                                key={s.dayOfWeek}
                                className={`p-2.5 text-center border-r border-slate-100 last:border-r-0 ${
                                  isToday ? 'bg-blue-50/30' : ''
                                }`}
                              >
                                {s.isWorking ? (
                                  <span className="inline-flex items-center justify-center gap-1 w-full text-[11px] font-bold text-emerald-700 bg-emerald-50 py-1.5 px-2 rounded-xl border border-emerald-200">
                                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                                    Đi làm
                                  </span>
                                ) : (
                                  <span className="inline-flex items-center justify-center gap-1 w-full text-[11px] font-bold text-slate-500 bg-slate-100 py-1.5 px-2 rounded-xl border border-slate-200">
                                    <Moon className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                                    Nghỉ ca
                                  </span>
                                )}
                              </td>
                            );
                          })}
                        </tr>
                      </tbody>
                    </table>
                  </div>

                  {/* 3. Timetable Legend & Labor Law Compliance */}
                  <div className="p-4 sm:p-5 bg-slate-50 border-t border-slate-200/80 flex flex-col md:flex-row md:items-center justify-between gap-4 text-xs">
                    <div className="flex flex-wrap items-center gap-3">
                      <span className="font-bold text-slate-700 text-[11px] uppercase tracking-wider">Chú thích màu:</span>
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-blue-50 border border-blue-200 text-blue-800 font-bold text-[11px]">
                        <span className="w-2.5 h-2.5 rounded-full bg-blue-600"></span> Ca Sáng
                      </span>
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-amber-50 border border-amber-200 text-amber-800 font-bold text-[11px]">
                        <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span> Nghỉ Giữa Ca
                      </span>
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-indigo-50 border border-indigo-200 text-indigo-800 font-bold text-[11px]">
                        <span className="w-2.5 h-2.5 rounded-full bg-indigo-600"></span> Ca Chiều
                      </span>
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-800 font-bold text-[11px]">
                        <span className="w-2.5 h-2.5 rounded-full bg-emerald-600"></span> Thực Làm (Công chuẩn)
                      </span>
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-slate-100 border border-slate-200 text-slate-600 font-bold text-[11px]">
                        <span className="w-2.5 h-2.5 rounded-full bg-slate-400"></span> Nghỉ Tuần (OFF)
                      </span>
                    </div>

                    <div className="text-[11px] text-slate-500 bg-white px-3 py-1.5 rounded-xl border border-slate-200 shrink-0">
                      ⚖️ <strong>Điều 105 BLLĐ 2019</strong>: Ca làm ≤ 8h/ngày và ≤ 48h/tuần.
                    </div>
                  </div>
                </div>
              </div>
            );
          })()}

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
                    <option value="Fixed-term">Hợp đồng Xác định thời hạn</option>
                    <option value="Indefinite">Hợp đồng Không xác định thời hạn</option>
                    <option value="Probation">Hợp đồng Thử việc</option>
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
  );

  return embedded ? body : <AppShell>{body}</AppShell>;
}
