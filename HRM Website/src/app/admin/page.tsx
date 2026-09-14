'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { adminService, PendingUserItem, AdminAccountItem, AdminSessionItem } from '@/services/adminService';
import {
  Shield,
  UserCheck,
  KeyRound,
  Laptop,
  Smartphone,
  Tablet,
  Globe,
  Lock,
  Unlock,
  RefreshCw,
  LogOut,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  Clock,
  Search,
  Building2,
  Briefcase,
  Sliders,
  Eye,
  EyeOff,
  UserPlus
} from 'lucide-react';

export default function AdminPage() {
  const { currentUser, isAdmin } = useAuth();

  const [activeTab, setActiveTab] = useState<'pending' | 'accounts' | 'sessions' | 'master'>('pending');
  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [toastMessage, setToastMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Data states
  const [pendingUsers, setPendingUsers] = useState<PendingUserItem[]>([]);
  const [accounts, setAccounts] = useState<AdminAccountItem[]>([]);
  const [sessions, setSessions] = useState<AdminSessionItem[]>([]);

  // Search/Filters
  const [searchKeyword, setSearchKeyword] = useState('');

  // Modals
  const [provisionModal, setProvisionModal] = useState<{ open: boolean; user?: PendingUserItem }>({ open: false });
  const [corporateEmail, setCorporateEmail] = useState('');
  const [tempPassword, setTempPassword] = useState('Hrm@123456');
  const [showPassword, setShowPassword] = useState(false);

  const [rejectModal, setRejectModal] = useState<{ open: boolean; user?: PendingUserItem }>({ open: false });
  const [rejectReason, setRejectReason] = useState('');

  const [resetPassModal, setResetPassModal] = useState<{ open: boolean; user?: AdminAccountItem }>({ open: false });
  const [newResetPassword, setNewResetPassword] = useState('Hrm@123456');

  const [statusConfirmModal, setStatusConfirmModal] = useState<{ open: boolean; user?: AdminAccountItem; nextStatus?: boolean }>({ open: false });

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 4000);
  };

  // Fetch data on tab change
  useEffect(() => {
    if (!isAdmin) return;
    loadTabData();
  }, [activeTab, isAdmin]);

  const loadTabData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'pending') {
        const data = await adminService.getPendingUsers('PENDING');
        setPendingUsers(data);
      } else if (activeTab === 'accounts') {
        const data = await adminService.getAllAccounts();
        setAccounts(data);
      } else if (activeTab === 'sessions') {
        const data = await adminService.getAllSessions();
        setSessions(data);
      }
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Không thể tải dữ liệu', 'error');
    } finally {
      setLoading(false);
    }
  };

  if (!isAdmin) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] text-center p-6">
        <div className="w-16 h-16 bg-red-100 text-red-600 rounded-full flex items-center justify-center mb-4">
          <AlertTriangle className="w-8 h-8" />
        </div>
        <h2 className="text-xl font-bold text-slate-800 mb-2">Truy Cập Bị Từ Chối</h2>
        <p className="text-slate-600 max-w-md">
          Chỉ Quản trị viên Hệ thống (System Administrator) thuộc bộ phận Công nghệ thông tin hoặc Ban Giám Đốc mới có quyền truy cập trang này.
        </p>
      </div>
    );
  }

  // Handle Provision Account
  const handleOpenProvision = (user: PendingUserItem) => {
    const cleanName = (user.firstName + '.' + user.lastName).toLowerCase().replace(/\s+/g, '');
    const suggestedEmail = `${cleanName}@company.com`;
    setCorporateEmail(suggestedEmail);
    setTempPassword('Hrm@123456');
    setProvisionModal({ open: true, user });
  };

  const handleExecuteProvision = async () => {
    if (!provisionModal.user) return;
    if (!corporateEmail.trim()) {
      showToast('Vui lòng nhập email công ty!', 'error');
      return;
    }
    setActionLoading(true);
    try {
      await adminService.provisionUser(provisionModal.user.pendingId, {
        corporateEmail: corporateEmail.trim(),
        temporaryPassword: tempPassword.trim()
      });
      showToast(`Đã cấp tài khoản thành công cho ${provisionModal.user.fullName}!`);
      setProvisionModal({ open: false });
      loadTabData();
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Lỗi cấp tài khoản', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // Handle Reject Pending User
  const handleExecuteReject = async () => {
    if (!rejectModal.user) return;
    if (!rejectReason.trim()) {
      showToast('Vui lòng nhập lý do từ chối!', 'error');
      return;
    }
    setActionLoading(true);
    try {
      await adminService.rejectPendingUser(rejectModal.user.pendingId, rejectReason.trim());
      showToast(`Đã từ chối hồ sơ của ${rejectModal.user.fullName}`);
      setRejectModal({ open: false });
      setRejectReason('');
      loadTabData();
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Lỗi từ chối hồ sơ', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // Handle Account Lock/Unlock
  const handleExecuteStatusToggle = async () => {
    if (!statusConfirmModal.user || statusConfirmModal.nextStatus === undefined) return;
    setActionLoading(true);
    try {
      await adminService.updateAccountStatus(
        statusConfirmModal.user.userId,
        statusConfirmModal.nextStatus,
        statusConfirmModal.nextStatus ? 'Admin kích hoạt lại' : 'Admin tạm khóa tài khoản'
      );
      showToast(statusConfirmModal.nextStatus ? 'Đã kích hoạt lại tài khoản' : 'Đã khóa tài khoản và ngắt toàn bộ phiên');
      setStatusConfirmModal({ open: false });
      loadTabData();
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Lỗi cập nhật trạng thái', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // Handle Reset Password
  const handleExecuteResetPassword = async () => {
    if (!resetPassModal.user) return;
    if (!newResetPassword.trim() || newResetPassword.length < 8) {
      showToast('Mật khẩu tạm phải có tối thiểu 8 ký tự!', 'error');
      return;
    }
    setActionLoading(true);
    try {
      await adminService.resetPassword(resetPassModal.user.userId, newResetPassword.trim());
      showToast(`Đã reset mật khẩu cho ${resetPassModal.user.fullName}. Đã ngắt các phiên cũ!`);
      setResetPassModal({ open: false });
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Lỗi reset mật khẩu', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // Handle Revoke Session
  const handleRevokeSession = async (sessionId: string) => {
    if (!confirm('Bạn có chắc chắn muốn ngắt kết nối thiết bị này?')) return;
    setActionLoading(true);
    try {
      await adminService.revokeSession(sessionId);
      showToast('Đã thu hồi phiên đăng nhập thành công!');
      loadTabData();
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Lỗi thu hồi phiên', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  const handleRevokeAllUserSessions = async (userId: string, userName: string) => {
    if (!confirm(`Bạn có chắc muốn đăng xuất TẤT CẢ thiết bị của nhân viên ${userName}?`)) return;
    setActionLoading(true);
    try {
      await adminService.revokeAllUserSessions(userId);
      showToast(`Đã đăng xuất toàn bộ thiết bị của ${userName}!`);
      loadTabData();
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Lỗi thu hồi phiên', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Toast Alert */}
      {toastMessage && (
        <div className={`fixed top-5 right-5 z-50 flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg text-sm font-medium transition-all ${
          toastMessage.type === 'success' ? 'bg-emerald-600 text-white' : 'bg-rose-600 text-white'
        }`}>
          {toastMessage.type === 'success' ? <CheckCircle2 className="w-5 h-5" /> : <XCircle className="w-5 h-5" />}
          <span>{toastMessage.text}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 p-6 rounded-2xl text-white shadow-sm">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <span className="bg-indigo-500/30 text-indigo-300 text-xs font-semibold px-2.5 py-1 rounded-full border border-indigo-400/20 flex items-center gap-1.5">
              <Shield className="w-3.5 h-3.5" />
              IT System Administration
            </span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight">Trung Tâm Quản Trị Hệ Thống</h1>
          <p className="text-slate-400 text-sm mt-1">
            Cấp tài khoản Onboarding, kiểm soát phiên đăng nhập, khóa/mở tài khoản và danh mục cơ sở.
          </p>
        </div>

        <button
          onClick={loadTabData}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2.5 bg-white/10 hover:bg-white/20 text-white rounded-xl text-sm font-medium transition-all border border-white/10 shrink-0 w-fit"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          <span>Làm mới dữ liệu</span>
        </button>
      </div>

      {/* Tabs Bar */}
      <div className="flex border-b border-slate-200 bg-white rounded-t-xl px-4 pt-2 gap-2 overflow-x-auto">
        <button
          onClick={() => setActiveTab('pending')}
          className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-all shrink-0 ${
            activeTab === 'pending'
              ? 'border-indigo-600 text-indigo-600 font-semibold'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <UserPlus className="w-4 h-4" />
          <span>Duyệt Cấp Tài Khoản</span>
          {pendingUsers.length > 0 && (
            <span className="bg-indigo-100 text-indigo-700 text-xs font-bold px-2 py-0.5 rounded-full">
              {pendingUsers.length}
            </span>
          )}
        </button>

        <button
          onClick={() => setActiveTab('accounts')}
          className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-all shrink-0 ${
            activeTab === 'accounts'
              ? 'border-indigo-600 text-indigo-600 font-semibold'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <UserCheck className="w-4 h-4" />
          <span>Tài Khoản & Bảo Mật</span>
        </button>

        <button
          onClick={() => setActiveTab('sessions')}
          className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-all shrink-0 ${
            activeTab === 'sessions'
              ? 'border-indigo-600 text-indigo-600 font-semibold'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <Laptop className="w-4 h-4" />
          <span>Giám Sát Phiên & Thiết Bị</span>
          {sessions.filter(s => !s.revoked).length > 0 && (
            <span className="bg-emerald-100 text-emerald-700 text-xs font-bold px-2 py-0.5 rounded-full">
              {sessions.filter(s => !s.revoked).length} Online
            </span>
          )}
        </button>
      </div>

      {/* TAB CONTENT */}
      <div className="bg-white rounded-b-xl border border-t-0 border-slate-200 p-6 min-h-[400px]">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 text-slate-400">
            <RefreshCw className="w-8 h-8 animate-spin mb-3 text-indigo-600" />
            <p className="text-sm">Đang nạp dữ liệu quản trị...</p>
          </div>
        ) : (
          <>
            {/* ─── TAB 1: PENDING USERS PROVISIONING ─── */}
            {activeTab === 'pending' && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-base font-semibold text-slate-900">Danh Sách Hồ Sơ Tuyển Dụng Chờ Cấp Tài Khoản</h3>
                    <p className="text-xs text-slate-500">
                      Do phòng Nhân Sự (HR) nộp sang. Admin xem xét và cấp Email công ty cùng Mật khẩu khởi tạo.
                    </p>
                  </div>
                </div>

                {pendingUsers.length === 0 ? (
                  <div className="text-center py-16 border-2 border-dashed border-slate-200 rounded-xl">
                    <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
                    <h4 className="text-slate-800 font-semibold">Hiện không có hồ sơ nào chờ duyệt</h4>
                    <p className="text-slate-500 text-sm mt-1">
                      Mọi yêu cầu tuyển dụng từ HR đã được xử lý hoàn tất.
                    </p>
                  </div>
                ) : (
                  <div className="overflow-x-auto border border-slate-200 rounded-xl">
                    <table className="w-full text-left text-sm">
                      <thead className="bg-slate-50 text-slate-600 text-xs font-semibold border-b border-slate-200 uppercase tracking-wider">
                        <tr>
                          <th className="px-4 py-3">Họ và Tên</th>
                          <th className="px-4 py-3">Email Cá Nhân</th>
                          <th className="px-4 py-3">Phòng Ban & Chức Danh</th>
                          <th className="px-4 py-3">Loại HĐ / Lương</th>
                          <th className="px-4 py-3">Người Tạo (HR)</th>
                          <th className="px-4 py-3 text-right">Thao Tác</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {pendingUsers.map(u => (
                          <tr key={u.pendingId} className="hover:bg-slate-50/80 transition-colors">
                            <td className="px-4 py-3.5">
                              <div className="font-semibold text-slate-900">{u.fullName}</div>
                              <div className="text-xs text-slate-400">CCCD: {u.citizenId || '---'} | SĐT: {u.phoneNumber || '---'}</div>
                            </td>
                            <td className="px-4 py-3.5 text-slate-600">{u.personalEmail}</td>
                            <td className="px-4 py-3.5">
                              <span className="font-medium text-slate-800">{u.jobTitle}</span>
                              <div className="text-xs text-slate-500">{u.departmentName}</div>
                            </td>
                            <td className="px-4 py-3.5">
                              <span className="inline-block text-xs bg-slate-100 text-slate-700 px-2 py-0.5 rounded font-medium">
                                {u.contractType || 'Fixed-term'}
                              </span>
                              <div className="text-xs text-emerald-600 font-semibold mt-0.5">
                                {u.baseSalary ? `${u.baseSalary.toLocaleString('vi-VN')} đ` : '---'}
                              </div>
                            </td>
                            <td className="px-4 py-3.5">
                              <div className="text-slate-700 font-medium">{u.createdByName || 'HR Onboarding'}</div>
                              <div className="text-xs text-slate-400">{u.createdAt ? u.createdAt.slice(0, 10) : ''}</div>
                            </td>
                            <td className="px-4 py-3.5 text-right space-x-2">
                              <button
                                onClick={() => handleOpenProvision(u)}
                                className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-xs font-semibold shadow-xs transition-colors"
                              >
                                Cấp Tài Khoản
                              </button>
                              <button
                                onClick={() => {
                                  setRejectReason('');
                                  setRejectModal({ open: true, user: u });
                                }}
                                className="px-2.5 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 rounded-lg text-xs font-semibold transition-colors"
                              >
                                Từ Chối
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}

            {/* ─── TAB 2: ACCOUNTS & SECURITY ─── */}
            {activeTab === 'accounts' && (
              <div className="space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div>
                    <h3 className="text-base font-semibold text-slate-900">Quản Trị Tài Khoản & Quyền Đăng Nhập</h3>
                    <p className="text-xs text-slate-500">
                      Khóa khẩn cấp tài khoản hoặc cấp mật khẩu tạm thời cho nhân viên khi có sự cố.
                    </p>
                  </div>
                  <div className="relative w-full sm:w-64">
                    <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      placeholder="Tìm nhân viên, email..."
                      value={searchKeyword}
                      onChange={e => setSearchKeyword(e.target.value)}
                      className="w-full pl-9 pr-3 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    />
                  </div>
                </div>

                <div className="overflow-x-auto border border-slate-200 rounded-xl">
                  <table className="w-full text-left text-sm">
                    <thead className="bg-slate-50 text-slate-600 text-xs font-semibold border-b border-slate-200 uppercase tracking-wider">
                      <tr>
                        <th className="px-4 py-3">Mã NV</th>
                        <th className="px-4 py-3">Họ và Tên</th>
                        <th className="px-4 py-3">Email Công Ty</th>
                        <th className="px-4 py-3">Phòng Ban & Vị Trí</th>
                        <th className="px-4 py-3 text-center">Thiết Bị Online</th>
                        <th className="px-4 py-3 text-center">Trạng Thái</th>
                        <th className="px-4 py-3 text-right">Thao Tác</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {accounts
                        .filter(a =>
                          !searchKeyword ||
                          a.fullName?.toLowerCase().includes(searchKeyword.toLowerCase()) ||
                          a.email?.toLowerCase().includes(searchKeyword.toLowerCase()) ||
                          a.employeeCode?.toLowerCase().includes(searchKeyword.toLowerCase())
                        )
                        .map(a => (
                          <tr key={a.userId} className="hover:bg-slate-50/80 transition-colors">
                            <td className="px-4 py-3.5 font-mono text-xs text-slate-500 font-semibold">
                              {a.employeeCode || '---'}
                            </td>
                            <td className="px-4 py-3.5 font-semibold text-slate-900">{a.fullName}</td>
                            <td className="px-4 py-3.5 text-slate-600">{a.email}</td>
                            <td className="px-4 py-3.5">
                              <span className="font-medium text-slate-800">{a.jobTitle}</span>
                              <div className="text-xs text-slate-400">{a.departmentName}</div>
                            </td>
                            <td className="px-4 py-3.5 text-center">
                              {a.activeSessionCount > 0 ? (
                                <span className="inline-flex items-center gap-1 bg-emerald-50 text-emerald-700 text-xs font-semibold px-2 py-0.5 rounded-full border border-emerald-200">
                                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                  {a.activeSessionCount} máy
                                </span>
                              ) : (
                                <span className="text-xs text-slate-400">Offline</span>
                              )}
                            </td>
                            <td className="px-4 py-3.5 text-center">
                              {a.isActive ? (
                                <span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-700 bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-200">
                                  <CheckCircle2 className="w-3.5 h-3.5" /> Hoạt động
                                </span>
                              ) : (
                                <span className="inline-flex items-center gap-1 text-xs font-semibold text-rose-700 bg-rose-50 px-2.5 py-1 rounded-full border border-rose-200">
                                  <Lock className="w-3.5 h-3.5" /> Bị khóa
                                </span>
                              )}
                            </td>
                            <td className="px-4 py-3.5 text-right space-x-2">
                              <button
                                onClick={() => {
                                  setNewResetPassword('Hrm@123456');
                                  setResetPassModal({ open: true, user: a });
                                }}
                                className="px-2.5 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg text-xs font-semibold transition-colors inline-flex items-center gap-1"
                                title="Cấp mật khẩu tạm thời"
                              >
                                <KeyRound className="w-3.5 h-3.5" /> Reset Pass
                              </button>

                              {a.userId !== currentUser?.userId && (
                                <button
                                  onClick={() =>
                                    setStatusConfirmModal({
                                      open: true,
                                      user: a,
                                      nextStatus: !a.isActive
                                    })
                                  }
                                  className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-colors inline-flex items-center gap-1 ${
                                    a.isActive
                                      ? 'bg-amber-50 hover:bg-amber-100 text-amber-700 border border-amber-200'
                                      : 'bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200'
                                  }`}
                                >
                                  {a.isActive ? (
                                    <>
                                      <Lock className="w-3.5 h-3.5" /> Khóa
                                    </>
                                  ) : (
                                    <>
                                      <Unlock className="w-3.5 h-3.5" /> Mở khóa
                                    </>
                                  )}
                                </button>
                              )}
                            </td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* ─── TAB 3: SESSIONS & DEVICES ─── */}
            {activeTab === 'sessions' && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-base font-semibold text-slate-900">Giám Sát Phiên Đăng Nhập & Thiết Bị</h3>
                    <p className="text-xs text-slate-500">
                      Hiển thị toàn bộ thiết bị đang kết nối. Admin có thể ngắt kết nối từng máy hoặc đăng xuất toàn bộ.
                    </p>
                  </div>
                </div>

                <div className="overflow-x-auto border border-slate-200 rounded-xl">
                  <table className="w-full text-left text-sm">
                    <thead className="bg-slate-50 text-slate-600 text-xs font-semibold border-b border-slate-200 uppercase tracking-wider">
                      <tr>
                        <th className="px-4 py-3">Nhân Viên</th>
                        <th className="px-4 py-3">Thiết Bị & HĐH</th>
                        <th className="px-4 py-3">Trình Duyệt</th>
                        <th className="px-4 py-3">Địa Chỉ IP & Nhà Mạng</th>
                        <th className="px-4 py-3">Vị Trí</th>
                        <th className="px-4 py-3">Đăng Nhập Lúc</th>
                        <th className="px-4 py-3 text-center">Trạng Thái</th>
                        <th className="px-4 py-3 text-right">Thao Tác</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {sessions.map(s => {
                        const isPhone = s.deviceType?.toLowerCase().includes('phone') || s.deviceType?.toLowerCase().includes('mobile');
                        const isTablet = s.deviceType?.toLowerCase().includes('tablet');

                        return (
                          <tr key={s.sessionId} className={`hover:bg-slate-50/80 transition-colors ${s.revoked ? 'opacity-50 bg-slate-50/50' : ''}`}>
                            <td className="px-4 py-3.5">
                              <div className="font-semibold text-slate-900">{s.userFullName}</div>
                              <div className="text-xs text-slate-500">{s.userEmail}</div>
                            </td>
                            <td className="px-4 py-3.5">
                              <div className="flex items-center gap-2">
                                {isPhone ? (
                                  <Smartphone className="w-4 h-4 text-slate-500" />
                                ) : isTablet ? (
                                  <Tablet className="w-4 h-4 text-slate-500" />
                                ) : (
                                  <Laptop className="w-4 h-4 text-slate-500" />
                                )}
                                <span className="font-medium text-slate-800">{s.deviceOS || 'Unknown OS'}</span>
                              </div>
                              <div className="text-xs text-slate-400 pl-6">{s.deviceType || 'Desktop'}</div>
                            </td>
                            <td className="px-4 py-3.5 text-slate-700">{s.browser || 'Browser'}</td>
                            <td className="px-4 py-3.5">
                              <div className="font-mono text-xs text-indigo-600 font-semibold">{s.ipAddr || '---'}</div>
                              <div className="text-xs text-slate-400">{s.isp || 'Local Network'}</div>
                            </td>
                            <td className="px-4 py-3.5 text-slate-600 text-xs">
                              {s.city && s.country ? `${s.city}, ${s.country}` : 'LocalHost'}
                            </td>
                            <td className="px-4 py-3.5 text-xs text-slate-500">
                              {s.createdAt ? s.createdAt.replace('T', ' ').slice(0, 19) : '---'}
                            </td>
                            <td className="px-4 py-3.5 text-center">
                              {s.revoked ? (
                                <span className="text-xs bg-slate-100 text-slate-500 px-2 py-0.5 rounded font-medium">
                                  Đã thu hồi
                                </span>
                              ) : (
                                <span className="text-xs bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full font-semibold border border-emerald-200">
                                  🟢 Online
                                </span>
                              )}
                            </td>
                            <td className="px-4 py-3.5 text-right space-x-1">
                              {!s.revoked && (
                                <>
                                  <button
                                    onClick={() => handleRevokeSession(s.sessionId)}
                                    className="px-2.5 py-1 bg-amber-50 hover:bg-amber-100 text-amber-700 border border-amber-200 rounded-lg text-xs font-semibold transition-colors"
                                    title="Ngắt kết nối máy này"
                                  >
                                    Đá máy này
                                  </button>
                                  <button
                                    onClick={() => handleRevokeAllUserSessions(s.userId, s.userFullName)}
                                    className="px-2.5 py-1 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-lg text-xs font-semibold transition-colors"
                                    title="Đăng xuất khỏi tất cả các thiết bị"
                                  >
                                    Đá toàn bộ
                                  </button>
                                </>
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
          </>
        )}
      </div>

      {/* ─── MODAL 1: CẤP TÀI KHOẢN (PROVISIONING) ─── */}
      {provisionModal.open && provisionModal.user && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4 border border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center">
                <UserPlus className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900">Cấp Tài Khoản Nhân Viên</h3>
                <p className="text-xs text-slate-500">{provisionModal.user.fullName} ({provisionModal.user.jobTitle})</p>
              </div>
            </div>

            <div className="space-y-3 pt-2">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Email Công Ty Chính Thức <span className="text-rose-500">*</span>
                </label>
                <input
                  type="email"
                  value={corporateEmail}
                  onChange={e => setCorporateEmail(e.target.value)}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  placeholder="username@company.com"
                />
                <p className="text-[11px] text-slate-400 mt-1">
                  Email cá nhân nhận bàn giao: {provisionModal.user.personalEmail}
                </p>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Mật Khẩu Khởi Tạo Tạm Thời <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={tempPassword}
                    onChange={e => setTempPassword(e.target.value)}
                    className="w-full px-3 py-2 border border-slate-300 rounded-xl text-sm pr-10 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setProvisionModal({ open: false })}
                className="px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-100 rounded-xl transition-colors"
              >
                Hủy bỏ
              </button>
              <button
                type="button"
                disabled={actionLoading}
                onClick={handleExecuteProvision}
                className="px-4 py-2 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-xs transition-colors flex items-center gap-2"
              >
                {actionLoading && <RefreshCw className="w-4 h-4 animate-spin" />}
                <span>Xác nhận Cấp & Kích hoạt</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─── MODAL 2: TỪ CHỐI HỒ SƠ ─── */}
      {rejectModal.open && rejectModal.user && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4 border border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900">Từ Chối Hồ Sơ Tuyển Dụng</h3>
                <p className="text-xs text-slate-500">{rejectModal.user.fullName}</p>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Lý do từ chối gửi HR <span className="text-rose-500">*</span>
              </label>
              <textarea
                rows={3}
                value={rejectReason}
                onChange={e => setRejectReason(e.target.value)}
                placeholder="Ví dụ: Thiếu số CCCD, chức vụ không khớp với phòng ban..."
                className="w-full px-3 py-2 border border-slate-300 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-rose-500"
              />
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setRejectModal({ open: false })}
                className="px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-100 rounded-xl"
              >
                Hủy
              </button>
              <button
                type="button"
                disabled={actionLoading}
                onClick={handleExecuteReject}
                className="px-4 py-2 text-sm font-semibold text-white bg-rose-600 hover:bg-rose-700 rounded-xl shadow-xs"
              >
                {actionLoading ? 'Đang gửi...' : 'Xác nhận Từ chối'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─── MODAL 3: RESET MẬT KHẨU TẠM ─── */}
      {resetPassModal.open && resetPassModal.user && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4 border border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center">
                <KeyRound className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900">Cấp Lại Mật Khẩu Tạm Thời</h3>
                <p className="text-xs text-slate-500">{resetPassModal.user.fullName} ({resetPassModal.user.email})</p>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Mật khẩu mới (Tối thiểu 8 ký tự)
              </label>
              <input
                type="text"
                value={newResetPassword}
                onChange={e => setNewResetPassword(e.target.value)}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl text-sm font-mono focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
              <p className="text-[11px] text-slate-500 mt-1">
                ⚠️ Lưu ý: Sau khi đổi, toàn bộ phiên đăng nhập trên mọi thiết bị cũ của nhân viên sẽ bị hủy lập tức.
              </p>
            </div>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setResetPassModal({ open: false })}
                className="px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-100 rounded-xl"
              >
                Hủy
              </button>
              <button
                type="button"
                disabled={actionLoading}
                onClick={handleExecuteResetPassword}
                className="px-4 py-2 text-sm font-semibold text-white bg-amber-600 hover:bg-amber-700 rounded-xl shadow-xs"
              >
                {actionLoading ? 'Đang cập nhật...' : 'Cập nhật Mật Khẩu'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─── MODAL 4: XÁC NHẬN KHÓA / MỞ KHÓA TÀI KHOẢN ─── */}
      {statusConfirmModal.open && statusConfirmModal.user && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl space-y-4 border border-slate-100">
            <div className="flex items-center gap-3">
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                statusConfirmModal.nextStatus ? 'bg-emerald-100 text-emerald-600' : 'bg-rose-100 text-rose-600'
              }`}>
                {statusConfirmModal.nextStatus ? <Unlock className="w-5 h-5" /> : <Lock className="w-5 h-5" />}
              </div>
              <div>
                <h3 className="text-base font-bold text-slate-900">
                  {statusConfirmModal.nextStatus ? 'Kích Hoạt Lại Tài Khoản' : 'Khóa Tài Khoản Nhân Viên'}
                </h3>
                <p className="text-xs text-slate-500">{statusConfirmModal.user.fullName} ({statusConfirmModal.user.email})</p>
              </div>
            </div>

            <p className="text-sm text-slate-600">
              {statusConfirmModal.nextStatus
                ? 'Nhân viên này sẽ có thể tiếp tục đăng nhập và sử dụng hệ thống bình thường.'
                : 'Bạn có chắc chắn muốn KHÓA tài khoản này? Toàn bộ phiên làm việc trên mọi thiết bị sẽ bị ngắt kết nối ngay lập tức.'}
            </p>

            <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setStatusConfirmModal({ open: false })}
                className="px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-100 rounded-xl"
              >
                Hủy
              </button>
              <button
                type="button"
                disabled={actionLoading}
                onClick={handleExecuteStatusToggle}
                className={`px-4 py-2 text-sm font-semibold text-white rounded-xl shadow-xs ${
                  statusConfirmModal.nextStatus ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-rose-600 hover:bg-rose-700'
                }`}
              >
                {actionLoading ? 'Đang xử lý...' : statusConfirmModal.nextStatus ? 'Xác nhận Mở Khóa' : 'Xác nhận Khóa Tài Khoản'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
