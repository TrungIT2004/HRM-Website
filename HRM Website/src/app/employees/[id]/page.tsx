'use client';

import React, { useState, use } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { getEmployeeDetail } from '@/mock/employeeDetails';
import { EmployeeDetailed, TodayAttendanceStatus } from '@/types';
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
  EyeOff
} from 'lucide-react';

export default function EmployeeDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const resolvedParams = use(params);
  const userId = resolvedParams.id;

  const { isHR, isExecutive, currentUser } = useAuth();
  const { employeeDetails, updateEmployeeProfile } = useHRMData();

  const [activeTab, setActiveTab] = useState<'basic' | 'legal' | 'contract' | 'salary' | 'assignment'>('basic');
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);

  // Retrieve target employee
  const employee: EmployeeDetailed = employeeDetails[userId] || getEmployeeDetail(userId);

  // Phân quyền theo chuẩn Spring Boot EmployeeService.java (dòng 173-245):
  const isMe = currentUser?.userId === userId;
  const isTargetSameDeptHead = !!(
    currentUser?.job?.startsWith('Department Head') && 
    currentUser?.department === employee.department
  );

  // 1. Tab 1: Công khai (ai cũng xem được)
  // 2. Tab 2: Pháp lý & Định danh (Chỉ isMe + HR + Executive)
  const canViewLegal = isMe || isHR || isExecutive;

  // 3. Tab 3: Hợp đồng lao động (isMe + Trưởng phòng cùng bộ phận + HR + Executive)
  const canViewContract = isMe || isTargetSameDeptHead || isHR || isExecutive;

  // 4. Tab 4: Lương & Ngân hàng (CHỈ isMe + HR + Executive - Trưởng phòng KHÔNG được xem lương nhân viên!)
  const canViewSalary = isMe || isHR || isExecutive;

  // 5. Quyền chỉnh sửa (Chỉ HR + Executive)
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

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    updateEmployeeProfile(userId, {
      firstName: formData.firstName,
      lastName: formData.lastName,
      fullName: `${formData.lastName} ${formData.firstName}`,
      department: formData.department as any,
      job: formData.job as any,
      shiftName: formData.shiftName,
      profile: {
        ...employee.profile,
        phoneNumber: formData.phoneNumber,
        personalEmail: formData.personalEmail,
        placeOfBirth: formData.placeOfBirth,
        maritalStatus: formData.maritalStatus as any,
        nationality: formData.nationality,
        citizenIdNumber: formData.citizenIdNumber,
        socialInsuranceNumber: formData.socialInsuranceNumber,
        taxIdentificationNumber: formData.taxIdentificationNumber,
        emergencyContactName: formData.emergencyContactName,
        emergencyContactPhone: formData.emergencyContactPhone
      },
      contract: {
        ...employee.contract,
        contractType: formData.contractType as any,
        contractStartDate: formData.contractStartDate,
        contractEndDate: formData.contractEndDate
      },
      salary: {
        ...employee.salary,
        baseSalary: Number(formData.baseSalary)
      },
      bankAccount: {
        bankName: formData.bankName,
        bankAccountNumber: formData.bankAccountNumber
      }
    });

    setIsEditModalOpen(false);
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Back navigation & Edit Button */}
        <div className="flex items-center justify-between">
          <Link
            href="/employees"
            className="inline-flex items-center gap-2 text-xs font-bold text-slate-600 hover:text-blue-600 transition"
          >
            <ArrowLeft className="h-4 w-4" />
            <span>Quay lại Danh bạ Nhân sự</span>
          </Link>

          {canEdit && (
            <button
              onClick={() => setIsEditModalOpen(true)}
              className="inline-flex items-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
            >
              <Edit3 className="h-3.5 w-3.5" />
              <span>Chỉnh sửa hồ sơ (Quyền HR/BGĐ)</span>
            </button>
          )}
        </div>

        {/* Profile Card Header */}
        <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
            <div className="flex items-center gap-4 sm:gap-6">
              <div className="flex h-16 w-16 sm:h-20 sm:w-20 items-center justify-center rounded-3xl bg-gradient-to-br from-blue-600 to-indigo-700 text-white font-black text-2xl sm:text-3xl shadow-lg shadow-blue-500/25">
                {employee.lastName?.[0] || employee.fullName?.[0]}
              </div>
              <div>
                <div className="flex items-center gap-2 mb-1">
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

            <div className="flex flex-col sm:items-end gap-2 text-xs">
              <div className="flex items-center gap-2">
                <span className="text-slate-400 font-medium">Trạng thái hôm nay:</span>
                {todayStatusBadge(employee.todayStatus)}
              </div>
              <div className="flex items-center gap-2">
                <span className="text-slate-400 font-medium">Ca làm việc:</span>
                <span className="inline-flex items-center gap-1.5 rounded-full bg-blue-50 px-3 py-1 font-bold text-blue-700 border border-blue-200">
                  <Clock className="h-3.5 w-3.5" />
                  <span>{employee.shiftName} ({employee.shiftStartTime} - {employee.shiftEndTime})</span>
                </span>
              </div>
            </div>
          </div>

          {/* Tab Navigation with Lock Badges */}
          <div className="mt-8 border-b border-slate-200 flex flex-wrap gap-2 text-xs font-bold">
            <button
              onClick={() => setActiveTab('basic')}
              className={`pb-3 px-3 border-b-2 transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'basic' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <span>1. Tổng Quan & Lịch Biểu</span>
            </button>

            <button
              onClick={() => setActiveTab('legal')}
              className={`pb-3 px-3 border-b-2 transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'legal' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <span>2. Pháp Lý & Định Danh</span>
              {!canViewLegal && <Lock className="h-3 w-3 text-slate-400" />}
            </button>

            <button
              onClick={() => setActiveTab('contract')}
              className={`pb-3 px-3 border-b-2 transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'contract' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <span>3. Hợp Đồng Lao Động</span>
              {!canViewContract && <Lock className="h-3 w-3 text-slate-400" />}
            </button>

            <button
              onClick={() => setActiveTab('salary')}
              className={`pb-3 px-3 border-b-2 transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'salary' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <span>4. Lương & Ngân Hàng</span>
              {!canViewSalary && <Lock className="h-3 w-3 text-slate-400" />}
            </button>

            <button
              onClick={() => setActiveTab('assignment')}
              className={`pb-3 px-3 border-b-2 transition cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'assignment' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <span>5. Phân Công Công Tác</span>
            </button>
          </div>
        </div>

        {/* Tab 1: Tổng Quan & Lịch Biểu (Công khai) */}
        {activeTab === 'basic' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="rounded-3xl bg-white p-6 shadow-sm border border-slate-200/80">
              <h3 className="text-sm font-bold text-slate-900 mb-4 flex items-center gap-2">
                <UserCheck className="h-4 w-4 text-blue-600" />
                <span>Thông tin cá nhân cơ bản (Public Profile)</span>
              </h3>
              <dl className="grid grid-cols-2 gap-4 text-xs">
                <div>
                  <dt className="text-slate-400 font-medium">Họ và tên</dt>
                  <dd className="mt-1 font-bold text-slate-800">{employee.fullName}</dd>
                </div>
                <div>
                  <dt className="text-slate-400 font-medium">Giới tính</dt>
                  <dd className="mt-1 font-bold text-slate-800">{employee.gender || 'Nam'}</dd>
                </div>
                <div>
                  <dt className="text-slate-400 font-medium">Ngày sinh</dt>
                  <dd className="mt-1 font-bold text-slate-800">{employee.birthDate || 'Chưa cập nhật'}</dd>
                </div>
                <div>
                  <dt className="text-slate-400 font-medium">Ngày vào công ty</dt>
                  <dd className="mt-1 font-bold text-slate-800">{employee.joinedDate}</dd>
                </div>
                <div>
                  <dt className="text-slate-400 font-medium">Email công vụ</dt>
                  <dd className="mt-1 font-bold text-slate-800 font-mono text-[11px]">{employee.email}</dd>
                </div>
                <div>
                  <dt className="text-slate-400 font-medium">Số điện thoại</dt>
                  <dd className="mt-1 font-bold text-slate-800 font-mono text-[11px]">{employee.profile?.phoneNumber || '0901234567'}</dd>
                </div>
              </dl>
            </div>

            <div className="rounded-3xl bg-white p-6 shadow-sm border border-slate-200/80">
              <h3 className="text-sm font-bold text-slate-900 mb-4 flex items-center gap-2">
                <Clock className="h-4 w-4 text-blue-600" />
                <span>Lịch làm việc ca kíp trong tuần</span>
              </h3>
              <div className="space-y-2">
                {employee.weeklySchedule?.map(sched => (
                  <div key={sched.dayOfWeek} className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 text-xs">
                    <span className="font-bold text-slate-700">{sched.dayName}</span>
                    {sched.isWorking ? (
                      <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-2.5 text-right">
                        <span className="text-emerald-700 font-bold bg-emerald-100/60 px-2 py-0.5 rounded">
                          Làm việc: {sched.startTime} - {sched.endTime}
                        </span>
                        {sched.restStartTime && sched.restEndTime && (
                          <span className="text-slate-500 font-medium text-[11px] bg-slate-100 px-2 py-0.5 rounded">
                            Nghỉ trưa: {sched.restStartTime} - {sched.restEndTime}
                          </span>
                        )}
                      </div>
                    ) : (
                      <span className="text-slate-400 font-medium bg-slate-100 px-2 py-0.5 rounded">
                        Nghỉ cuối tuần
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Tab 2: Pháp lý & Nhân thân */}
        {activeTab === 'legal' && (
          canViewLegal ? (
            <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                  <IdCard className="h-4 w-4 text-blue-600" />
                  <span>Hồ sơ định danh, Thuế & Bảo hiểm Xã hội (Spring Boot UserProfile)</span>
                </h3>
                <span className="rounded-full bg-blue-50 px-2.5 py-0.5 text-[11px] font-bold text-blue-700 border border-blue-200">
                  {isMe ? 'Chính chủ' : 'Quyền HR/BGĐ'}
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6 text-xs">
                <div>
                  <span className="text-slate-400 block font-medium">Số Căn cước công dân (CCCD)</span>
                  <span className="mt-1 font-mono font-bold text-sm text-slate-900 block">{employee.profile?.citizenIdNumber || '001080001234'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Mã số thuế cá nhân (TNCN)</span>
                  <span className="mt-1 font-mono font-bold text-sm text-slate-900 block">{employee.profile?.taxIdentificationNumber || '8012345678'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Mã số sổ BHXH</span>
                  <span className="mt-1 font-mono font-bold text-sm text-slate-900 block">{employee.profile?.socialInsuranceNumber || '7912345678'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Ngày bắt đầu đóng BHXH</span>
                  <span className="mt-1 font-bold text-slate-800 block">{employee.profile?.socialInsuranceStartDate || '2020-02-01'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Nơi sinh (Nguyên quán)</span>
                  <span className="mt-1 font-bold text-slate-800 block">{employee.profile?.placeOfBirth || 'Hà Nội'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Tình trạng hôn nhân</span>
                  <span className="mt-1 font-bold text-slate-800 block">{employee.profile?.maritalStatus || 'Độc thân'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Quốc tịch</span>
                  <span className="mt-1 font-bold text-slate-800 block">{employee.profile?.nationality || 'Việt Nam'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Người liên hệ khẩn cấp</span>
                  <span className="mt-1 font-bold text-slate-800 block">{employee.profile?.emergencyContactName || 'Chưa cập nhật'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Số điện thoại khẩn cấp</span>
                  <span className="mt-1 font-mono font-bold text-slate-800 block">{employee.profile?.emergencyContactPhone || 'Chưa cập nhật'}</span>
                </div>
              </div>
            </div>
          ) : (
            <div className="rounded-3xl bg-white p-8 sm:p-12 shadow-sm border border-slate-200/80 text-center max-w-lg mx-auto">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-amber-50 text-amber-600 mb-4 border border-amber-200">
                <Lock className="h-7 w-7" />
              </div>
              <h3 className="text-base font-bold text-slate-900">Dữ liệu Pháp lý & Định danh được Bảo mật</h3>
              <p className="mt-2 text-xs text-slate-500 leading-relaxed">
                Theo quy định bảo mật thông tin nhân sự và cơ chế phân quyền Spring Boot (<code className="font-mono text-[11px] bg-slate-100 px-1 py-0.5 rounded">EmployeeService.java</code>), thông tin Số CCCD, Mã số thuế và Bảo hiểm xã hội chỉ hiển thị cho chính chủ nhân sự, Phòng Nhân sự (HR) và Ban Giám Đốc.
              </p>
            </div>
          )
        )}

        {/* Tab 3: Hợp đồng lao động */}
        {activeTab === 'contract' && (
          canViewContract ? (
            <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                  <FileText className="h-4 w-4 text-blue-600" />
                  <span>Hợp đồng lao động & Tái ký (Spring Boot UserContract)</span>
                </h3>
                <span className="rounded-full bg-blue-50 px-2.5 py-0.5 text-[11px] font-bold text-blue-700 border border-blue-200">
                  {isMe ? 'Chính chủ' : isTargetSameDeptHead ? 'Trưởng phòng phụ trách' : 'Quyền HR/BGĐ'}
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6 text-xs">
                <div>
                  <span className="text-slate-400 block font-medium">Loại hợp đồng</span>
                  <span className="mt-1 font-bold text-sm text-blue-700 block">{employee.contract?.contractType || 'Không xác định thời hạn'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Ngày bắt đầu hiệu lực</span>
                  <span className="mt-1 font-bold text-slate-900 block">{employee.contract?.contractStartDate}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Ngày hết hạn</span>
                  <span className="mt-1 font-bold text-slate-900 block">{employee.contract?.contractEndDate || 'Vô thời hạn'}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Thời gian thử việc</span>
                  <span className="mt-1 font-bold text-slate-900 block">{employee.contract?.probationEndDate ? `Đã hoàn thành (${employee.contract.probationEndDate})` : 'Miễn thử việc'}</span>
                </div>
              </div>
            </div>
          ) : (
            <div className="rounded-3xl bg-white p-8 sm:p-12 shadow-sm border border-slate-200/80 text-center max-w-lg mx-auto">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-blue-50 text-blue-600 mb-4 border border-blue-200">
                <Lock className="h-7 w-7" />
              </div>
              <h3 className="text-base font-bold text-slate-900">Thông tin Hợp đồng Lao động được Giới hạn</h3>
              <p className="mt-2 text-xs text-slate-500 leading-relaxed">
                Hợp đồng lao động và thời hạn hợp đồng chỉ hiển thị cho chính nhân viên, Trưởng phòng phụ trách ({employee.department}), Phòng Nhân sự và Ban Giám Đốc.
              </p>
            </div>
          )
        )}

        {/* Tab 4: Lương & Ngân hàng (Tuyệt mật) */}
        {activeTab === 'salary' && (
          canViewSalary ? (
            <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                  <CreditCard className="h-4 w-4 text-blue-600" />
                  <span>Lương thỏa thuận & Tài khoản thụ hưởng (Spring Boot Salary & UserBankAccount)</span>
                </h3>
                <span className="rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-bold text-emerald-700 border border-emerald-200">
                  {isMe ? 'Lương của bạn' : 'Quyền HR/BGĐ'}
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-5 text-xs">
                <div className="p-4 rounded-2xl bg-blue-50 border border-blue-100">
                  <span className="text-blue-600 block font-medium">Mức lương cơ bản (GROSS)</span>
                  <span className="mt-1 font-black text-xl text-blue-900 block">
                    {(employee.salary?.baseSalary || 20000000).toLocaleString('vi-VN')} ₫
                  </span>
                  <div className="mt-2 text-[11px] text-blue-700 space-y-0.5 border-t border-blue-200/60 pt-2">
                    <div>Chu kỳ: <strong className="font-semibold">{employee.salary?.payFrequency === 'MONTHLY' ? 'Hàng tháng (MONTHLY)' : employee.salary?.payFrequency || 'Hàng tháng'}</strong></div>
                    <div>Trạng thái: <strong className="font-semibold text-emerald-700">{employee.salary?.isActive !== false ? 'Đang hiệu lực (ACTIVE)' : 'Hết hiệu lực'}</strong></div>
                  </div>
                </div>

                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200">
                  <span className="text-slate-400 block font-medium">Ngân hàng thụ hưởng</span>
                  <span className="mt-1 font-bold text-sm text-slate-800 block">
                    {employee.bankAccount?.bankName || 'Vietcombank'}
                  </span>
                  <span className="text-slate-400 block font-medium mt-3">Số tài khoản ngân hàng</span>
                  <span className="mt-0.5 font-mono font-bold text-sm text-slate-900 block">
                    {employee.bankAccount?.bankAccountNumber || '0011002233445'}
                  </span>
                </div>

                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200">
                  <span className="text-slate-400 block font-medium">Công chuẩn & Ngày áp dụng</span>
                  <span className="mt-1 font-bold text-base text-slate-800 block">{employee.salary?.workDays || 26} ngày công/tháng</span>
                  <div className="mt-2 text-[11px] text-slate-500 space-y-0.5 border-t border-slate-200/60 pt-2">
                    <div>Áp dụng từ: <strong className="font-semibold text-slate-700">{employee.salary?.startDate || employee.joinedDate}</strong></div>
                    <div>Công thức 1 giờ: <strong className="font-mono text-slate-700">Lương / ({employee.salary?.workDays || 26} x 8h)</strong></div>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="rounded-3xl bg-white p-8 sm:p-12 shadow-sm border border-slate-200/80 text-center max-w-lg mx-auto">
              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-red-50 text-red-600 mb-4 border border-red-200">
                <Lock className="h-7 w-7" />
              </div>
              <h3 className="text-base font-bold text-slate-900">Thông tin Lương & Ngân hàng là Dữ liệu Tuyệt mật</h3>
              <p className="mt-2 text-xs text-slate-500 leading-relaxed">
                Theo quy chế tiền lương doanh nghiệp và chuẩn Spring Boot <code className="font-mono text-[11px] bg-slate-100 px-1 py-0.5 rounded">EmployeeService.java</code> (dòng 221: <code className="font-mono text-[11px] bg-slate-100 px-1 py-0.5 rounded">if (isMe || isHR || isExecutive)</code>), mức lương cơ bản và tài khoản ngân hàng không được tiết lộ cho bất kỳ đồng nghiệp nào (kể cả Trưởng phòng). Dữ liệu này chỉ hiển thị duy nhất cho chính nhân viên đó, Phòng Nhân sự (HR) và Ban Giám Đốc.
              </p>
            </div>
          )
        )}

        {/* Tab 5: Phân công công tác */}
        {activeTab === 'assignment' && (
          <div className="rounded-3xl bg-white p-6 sm:p-8 shadow-sm border border-slate-200/80">
            <h3 className="text-sm font-bold text-slate-900 mb-6 flex items-center gap-2">
              <Building2 className="h-4 w-4 text-blue-600" />
              <span>Phòng ban, Chức danh & Ca trực (Spring Boot Assignment)</span>
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 text-xs">
              <div>
                <span className="text-slate-400 block font-medium">Phòng ban phụ trách</span>
                <span className="mt-1 font-bold text-sm text-slate-900 block">{employee.department}</span>
              </div>
              <div>
                <span className="text-slate-400 block font-medium">Vị trí / Chức danh</span>
                <span className="mt-1 font-bold text-sm text-slate-900 block">{employee.job}</span>
              </div>
              <div>
                <span className="text-slate-400 block font-medium">Ca làm việc</span>
                <span className="mt-1 font-bold text-sm text-slate-900 block">{employee.shiftName} ({employee.shiftStartTime} - {employee.shiftEndTime})</span>
              </div>
            </div>
          </div>
        )}

        {/* Modal Chỉnh Sửa Dành Riêng Cho HR / BGĐ */}
        {isEditModalOpen && canEdit && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 overflow-y-auto">
            <div className="relative w-full max-w-2xl rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-slate-200 my-8">
              <div className="flex items-center justify-between pb-4 border-b border-slate-100">
                <div className="flex items-center gap-2 text-blue-600 font-bold text-base">
                  <Edit3 className="h-5 w-5" />
                  <span>Cập nhật Hồ sơ Nhân sự (Quyền HR / BGĐ)</span>
                </div>
                <button
                  onClick={() => setIsEditModalOpen(false)}
                  className="rounded-full p-1 text-slate-400 hover:bg-slate-100 transition"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>

              <form onSubmit={handleSave} className="mt-5 space-y-4 text-xs">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Họ đệm</label>
                    <input
                      type="text"
                      value={formData.lastName}
                      onChange={e => setFormData({ ...formData, lastName: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Tên</label>
                    <input
                      type="text"
                      value={formData.firstName}
                      onChange={e => setFormData({ ...formData, firstName: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
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
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800 font-mono"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Mã số thuế</label>
                    <input
                      type="text"
                      value={formData.taxIdentificationNumber}
                      onChange={e => setFormData({ ...formData, taxIdentificationNumber: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800 font-mono"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Số BHXH</label>
                    <input
                      type="text"
                      value={formData.socialInsuranceNumber}
                      onChange={e => setFormData({ ...formData, socialInsuranceNumber: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800 font-mono"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Mức lương cơ bản (₫)</label>
                    <input
                      type="number"
                      value={formData.baseSalary}
                      onChange={e => setFormData({ ...formData, baseSalary: Number(e.target.value) })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800 font-bold"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Ngân hàng</label>
                    <input
                      type="text"
                      value={formData.bankName}
                      onChange={e => setFormData({ ...formData, bankName: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800"
                    />
                  </div>
                  <div>
                    <label className="block font-bold text-slate-700 mb-1">Số tài khoản ngân hàng</label>
                    <input
                      type="text"
                      value={formData.bankAccountNumber}
                      onChange={e => setFormData({ ...formData, bankAccountNumber: e.target.value })}
                      className="w-full rounded-xl border border-slate-300 p-2.5 text-xs text-slate-800 font-mono"
                    />
                  </div>
                </div>

                <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setIsEditModalOpen(false)}
                    className="rounded-xl px-4 py-2 text-xs font-bold text-slate-600 hover:bg-slate-100 transition"
                  >
                    Hủy bỏ
                  </button>
                  <button
                    type="submit"
                    className="flex items-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white px-5 py-2 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
                  >
                    <Save className="h-4 w-4" />
                    <span>Lưu thay đổi</span>
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
