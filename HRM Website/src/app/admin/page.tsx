'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { adminService, PendingUserItem, AdminAccountItem, AdminSessionItem, UserPermissionItem, PERMISSION_KEYS, PERMISSION_GROUPS, PERMISSION_LABELS, PERMISSION_DESCRIPTIONS } from '@/services/adminService';
import { organizationService, DepartmentDto, JobDto } from '@/services/organizationService';
import { workShiftService, WorkShiftResponse } from '@/services/workShiftService';
import { formatDateVN } from '@/utils/format';
import {
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
  UserPlus,
  Plus,
  Settings,
  X,
  Filter,
  MoreHorizontal,
  MoreVertical
} from 'lucide-react';

export interface DayScheduleForm {
  dayOfWeek: number;
  dayName: string;
  isWorking: boolean;
  startTime: string;
  endTime: string;
  restStartTime: string;
  restEndTime: string;
}

const DEFAULT_SCHEDULES: DayScheduleForm[] = [
  { dayOfWeek: 1, dayName: 'Thứ 2', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 2, dayName: 'Thứ 3', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 3, dayName: 'Thứ 4', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 4, dayName: 'Thứ 5', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 5, dayName: 'Thứ 6', isWorking: true, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' },
  { dayOfWeek: 6, dayName: 'Thứ 7', isWorking: false, startTime: '08:00', endTime: '12:00', restStartTime: '', restEndTime: '' },
  { dayOfWeek: 7, dayName: 'Chủ Nhật', isWorking: false, startTime: '08:00', endTime: '17:30', restStartTime: '12:00', restEndTime: '13:30' }
];

export const calculateDayWorkHours = (d: DayScheduleForm): number => {
  if (!d.isWorking || !d.startTime || !d.endTime) return 0;
  const [sh, sm] = d.startTime.split(':').map(Number);
  const [eh, em] = d.endTime.split(':').map(Number);
  let totalMin = (eh * 60 + (em || 0)) - (sh * 60 + (sm || 0));
  if (totalMin < 0) totalMin = 0;

  if (d.restStartTime && d.restEndTime) {
    const [rsh, rsm] = d.restStartTime.split(':').map(Number);
    const [reh, rem] = d.restEndTime.split(':').map(Number);
    const restMin = (reh * 60 + (rem || 0)) - (rsh * 60 + (rsm || 0));
    if (restMin > 0 && restMin < totalMin) {
      totalMin -= restMin;
    }
  }
  return Math.round((totalMin / 60) * 10) / 10;
};

export default function AdminPage() {
  const { currentUser, isAdmin, isSysAdmin, can } = useAuth();

  // isAdmin còn cho Executive vào /admin, nhưng cấp quyền thì tách riêng (khớp
  // AdminService.checkPermissionGrantAccess) — vào được không đồng nghĩa được phát quyền.
  const canGrantPermissions = isSysAdmin || can('PERMISSION_GRANT');
  // khớp AdminService.canManageAccounts: có ACCOUNT_LOCK thì vào được tab Tài Khoản & Bảo Mật
  const canLockAccounts = isSysAdmin || can('ACCOUNT_LOCK');
  const canManageOrganization = (currentUser?.department || '').toLowerCase() === 'human resources' || can('ORG_MANAGE');

  // Người chỉ có PERMISSION_GRANT thì tab mặc định phải là "Phân quyền",
  // nếu không sẽ đáp vào tab "pending" mà backend chặn 403.
  const canEnterAdmin = isAdmin || canGrantPermissions || canLockAccounts;
  const defaultTab = !isAdmin && canGrantPermissions ? 'permissions' : isAdmin ? 'pending' : 'accounts';
  const [activeTab, setActiveTab] = useState<'pending' | 'accounts' | 'organization' | 'permissions'>(defaultTab);
  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [toastMessage, setToastMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Dropdown menu state
  const [activeDropdownUser, setActiveDropdownUser] = useState<AdminAccountItem | null>(null);
  const [dropdownPos, setDropdownPos] = useState<{ top: number; right: number } | null>(null);

  const handleToggleDropdown = (e: React.MouseEvent<HTMLButtonElement>, user: AdminAccountItem) => {
    e.stopPropagation();
    if (activeDropdownUser?.userId === user.userId) {
      setActiveDropdownUser(null);
      setDropdownPos(null);
      return;
    }
    const rect = e.currentTarget.getBoundingClientRect();
    const menuHeight = 220;
    const opensUpward = rect.bottom + menuHeight > window.innerHeight;
    setDropdownPos({
      top: opensUpward ? Math.max(10, rect.top - menuHeight) : rect.bottom + 6,
      right: Math.max(10, window.innerWidth - rect.right)
    });
    setActiveDropdownUser(user);
  };

  // Data states
  const [pendingUsers, setPendingUsers] = useState<PendingUserItem[]>([]);
  const [accounts, setAccounts] = useState<AdminAccountItem[]>([]);

  // User Sessions Modal state
  const [userSessionsModal, setUserSessionsModal] = useState<{
    open: boolean;
    user?: AdminAccountItem;
    sessions: AdminSessionItem[];
    loading: boolean;
    search: string;
    statusFilter: 'ALL' | 'ONLINE' | 'REVOKED';
  }>({
    open: false,
    user: undefined,
    sessions: [],
    loading: false,
    search: '',
    statusFilter: 'ALL'
  });

  // Organization Master Data states
  const [departments, setDepartments] = useState<DepartmentDto[]>([]);
  const [jobs, setJobs] = useState<JobDto[]>([]);
  const [selectedDeptFilter, setSelectedDeptFilter] = useState<string>('all');

  // Search states for Organization sub-tabs
  const [deptSearchKeyword, setDeptSearchKeyword] = useState('');
  const [jobSearchKeyword, setJobSearchKeyword] = useState('');
  const [shiftSearchKeyword, setShiftSearchKeyword] = useState('');

  // Phân quyền theo người (grants)
  const [permSearch, setPermSearch] = useState('');
  const [permSelected, setPermSelected] = useState<AdminAccountItem | null>(null);
  const [permGrants, setPermGrants] = useState<UserPermissionItem[]>([]);
  const [permChecked, setPermChecked] = useState<string[]>([]);
  const [permLoading, setPermLoading] = useState(false);

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
    if (!canEnterAdmin) return;
    loadTabData();
  }, [activeTab, canEnterAdmin]);

  // Đuổi khỏi tab mà không đủ quyền
  useEffect(() => {
    if (loading) return;
    if (isAdmin) return;
    if (activeTab === 'permissions' && !canGrantPermissions) setActiveTab(canLockAccounts ? 'accounts' : 'pending');
    if (activeTab === 'accounts' && !canLockAccounts) setActiveTab(canGrantPermissions ? 'permissions' : 'pending');
  }, [loading, isAdmin, canGrantPermissions, canLockAccounts, activeTab]);

  const loadTabData = async () => {
    setLoading(true);
    try {
      // "pending" chỉ dành cho admin; "accounts" cần ACCOUNT_LOCK; "permissions" cần PERMISSION_GRANT
      if (activeTab === 'pending' && !isAdmin) return;
      if (activeTab === 'accounts' && !canLockAccounts) return;
      if (activeTab === 'pending') {
        const data = await adminService.getPendingUsers('PENDING');
        setPendingUsers(data);
      } else if (activeTab === 'accounts') {
        const data = await adminService.getAllAccounts();
        setAccounts(data);
      } else if (activeTab === 'permissions') {
        // ponytail: tái dùng danh sách accounts, khỏi API riêng
        if (accounts.length === 0) {
          const data = await adminService.getAllAccounts();
          setAccounts(data);
        }
      }
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Không thể tải dữ liệu', 'error');
    } finally {
      setLoading(false);
    }
  };

  // ─── Phân quyền theo người ───
  const filteredPermAccounts = accounts.filter(a => {
    if (!permSearch.trim()) return true;
    const kw = permSearch.trim().toLowerCase();
    return (a.fullName + ' ' + a.email + ' ' + a.employeeCode).toLowerCase().includes(kw);
  });

  const handleSelectPermUser = async (user: AdminAccountItem) => {
    setPermSelected(user);
    setPermLoading(true);
    try {
      const grants = await adminService.getUserPermissions(user.userId);
      setPermGrants(grants);
      setPermChecked(grants.map(g => g.key));
    } catch (err: any) {
      showToast(err?.message || 'Không tải được phân quyền', 'error');
      setPermGrants([]);
      setPermChecked([]);
    } finally {
      setPermLoading(false);
    }
  };

  const togglePermKey = (key: string) => {
    setPermChecked(prev => (prev.includes(key) ? prev.filter(k => k !== key) : [...prev, key]));
  };

  // ponytail: disable Lưu khi chưa đổi gì — mỗi lần lưu backend đá văng sessions của người ta
  const permDirty =
    JSON.stringify([...permChecked].sort()) !== JSON.stringify(permGrants.map(g => g.key).sort());

  const handleSavePermissions = async () => {
    if (!permSelected || !permDirty) return;
    // ponytail: backend chặn tự cấp (AdminService.saveUserPermissions); frontend chặn sớm để khỏi gọi API vô ích
    if (currentUser && permSelected.userId === currentUser.userId) {
      showToast('Không thể tự cấp quyền cho chính mình! Nhờ SysAdmin hoặc người được ủy quyền khác thực hiện.', 'error');
      return;
    }
    setActionLoading(true);
    try {
      const saved = await adminService.saveUserPermissions(permSelected.userId, permChecked);
      setPermGrants(saved);
      setPermChecked(saved.map(g => g.key));
      showToast(`Đã lưu phân quyền cho ${permSelected.fullName}. Người này phải đăng nhập lại để nhận quyền mới.`);
    } catch (err: any) {
      showToast(err?.message || 'Lưu phân quyền thất bại', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  if (!canEnterAdmin) {
    return (
      <AppShell>
        <div className="flex flex-col items-center justify-center min-h-[60vh] text-center p-8 space-y-4">
          <div className="w-16 h-16 bg-red-50 text-red-600 rounded-2xl flex items-center justify-center border border-red-200">
            <AlertTriangle className="w-8 h-8" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-slate-900 mb-1">Truy Cập Bị Từ Chối</h2>
            <p className="text-xs text-slate-500 max-w-md">
              Chỉ Quản trị viên Hệ thống (System Administrator), Ban Giám Đốc, hoặc người được cấp quyền
              <span className="font-semibold"> Cấp quyền cho nhân viên khác</span> mới vào được trang này.
            </p>
          </div>
          <Link
            href="/dashboard"
            className="inline-flex items-center gap-2 rounded-xl bg-blue-600 text-white px-4 py-2 text-xs font-bold shadow-xs hover:bg-blue-700 transition"
          >
            <span>Về Bảng điều khiển</span>
          </Link>
        </div>
      </AppShell>
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

  // User Sessions Modal Handlers
  const handleOpenUserSessions = async (user: AdminAccountItem) => {
    setUserSessionsModal({
      open: true,
      user,
      sessions: [],
      loading: true,
      search: '',
      statusFilter: 'ALL'
    });
    try {
      const list = await adminService.getUserSessions(user.userId);
      setUserSessionsModal(prev => ({
        ...prev,
        sessions: list || [],
        loading: false
      }));
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Không thể tải danh sách phiên thiết bị', 'error');
      setUserSessionsModal(prev => ({ ...prev, loading: false }));
    }
  };

  const handleRefreshUserSessions = async () => {
    if (!userSessionsModal.user) return;
    setUserSessionsModal(prev => ({ ...prev, loading: true }));
    try {
      const list = await adminService.getUserSessions(userSessionsModal.user.userId);
      setUserSessionsModal(prev => ({
        ...prev,
        sessions: list || [],
        loading: false
      }));
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Không thể làm mới danh sách phiên', 'error');
      setUserSessionsModal(prev => ({ ...prev, loading: false }));
    }
  };

  // Handle Revoke Single Session
  const handleRevokeSession = async (sessionId: string) => {
    if (!confirm('Bạn có chắc chắn muốn ngắt kết nối thiết bị này?')) return;
    setActionLoading(true);
    try {
      await adminService.revokeSession(sessionId);
      showToast('Đã thu hồi phiên đăng nhập thành công!');
      // Update session status in modal
      setUserSessionsModal(prev => ({
        ...prev,
        sessions: prev.sessions.map(s => (s.sessionId === sessionId ? { ...s, revoked: true } : s))
      }));
      // Update activeSessionCount in accounts list
      if (userSessionsModal.user) {
        setAccounts(prev =>
          prev.map(acc => {
            if (acc.userId === userSessionsModal.user?.userId) {
              return { ...acc, activeSessionCount: Math.max(0, acc.activeSessionCount - 1) };
            }
            return acc;
          })
        );
      }
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Lỗi thu hồi phiên', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // Handle Revoke All Sessions for User
  const handleRevokeAllUserSessions = async (userId: string, userName: string) => {
    if (!confirm(`Bạn có chắc muốn đăng xuất TẤT CẢ thiết bị của nhân viên ${userName}?`)) return;
    setActionLoading(true);
    try {
      await adminService.revokeAllUserSessions(userId);
      showToast(`Đã đăng xuất toàn bộ thiết bị của ${userName}!`);
      // Update session status in modal if currently open
      setUserSessionsModal(prev => {
        if (prev.user?.userId === userId) {
          return {
            ...prev,
            sessions: prev.sessions.map(s => ({ ...s, revoked: true }))
          };
        }
        return prev;
      });
      // Update activeSessionCount in accounts list
      setAccounts(prev =>
        prev.map(acc => {
          if (acc.userId === userId) {
            return { ...acc, activeSessionCount: 0 };
          }
          return acc;
        })
      );
    } catch (err: any) {
      showToast(err?.response?.data?.message || err?.message || 'Lỗi thu hồi phiên', 'error');
    } finally {
      setActionLoading(false);
    }
  };

  // Filtered sessions for User Sessions Modal
  const filteredModalSessions = userSessionsModal.sessions.filter(s => {
    if (userSessionsModal.statusFilter === 'ONLINE' && s.revoked) return false;
    if (userSessionsModal.statusFilter === 'REVOKED' && !s.revoked) return false;

    if (!userSessionsModal.search.trim()) return true;
    const q = userSessionsModal.search.toLowerCase();
    return (
      s.deviceOS?.toLowerCase().includes(q) ||
      s.deviceType?.toLowerCase().includes(q) ||
      s.browser?.toLowerCase().includes(q) ||
      s.ipAddr?.toLowerCase().includes(q) ||
      s.city?.toLowerCase().includes(q) ||
      s.country?.toLowerCase().includes(q) ||
      s.isp?.toLowerCase().includes(q)
    );
  });

  return (
    <AppShell>
      <div className="space-y-6">
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
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black tracking-tight text-slate-900">
            {isAdmin ? 'Quản Trị Hệ Thống' : 'Quản Lý Tài Khoản & Phân Quyền'}
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            {isAdmin
              ? 'Cấp tài khoản onboarding, kiểm soát phiên đăng nhập, khóa/mở tài khoản và danh mục cơ sở.'
              : 'Xem tài khoản, phiên đăng nhập, khóa/mở khóa và cấp quyền cho từng cá nhân.'}
          </p>
        </div>

        <button
          onClick={loadTabData}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2.5 bg-white hover:bg-slate-50 text-slate-700 rounded-xl text-xs font-bold transition-all border border-slate-200 shadow-xs shrink-0 w-fit cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 text-blue-600 ${loading ? 'animate-spin' : ''}`} />
          <span>Làm mới dữ liệu</span>
        </button>
      </div>

      {/* Tabs Bar */}
      <div className="flex border-b border-slate-200 bg-white rounded-t-xl px-4 pt-2 gap-2 overflow-x-auto">
        {isAdmin && (
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
        )}

        {(isAdmin || canLockAccounts) && (
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
        )}

        {canGrantPermissions && (
        <button
          onClick={() => setActiveTab('permissions')}
          className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-all shrink-0 ${
            activeTab === 'permissions'
              ? 'border-indigo-600 text-indigo-600 font-semibold'
              : 'border-transparent text-slate-500 hover:text-slate-700'
          }`}
        >
          <KeyRound className="w-4 h-4" />
          <span>Phân quyền</span>
        </button>
        )}
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
                  <div className="text-center py-16 border-2 border-dashed border-slate-200 rounded-xl bg-slate-50/50">
                    <CheckCircle2 className="w-12 h-12 text-emerald-500 mx-auto mb-3" />
                    <h4 className="text-slate-800 font-semibold">Hiện không có hồ sơ nào chờ duyệt</h4>
                    <p className="text-slate-500 text-sm mt-1">
                      Mọi yêu cầu tuyển dụng từ HR đã được xử lý hoàn tất.
                    </p>
                  </div>
                ) : (
                  <div className="overflow-hidden border border-slate-200 rounded-xl shadow-xs">
                    <div className="overflow-x-auto">
                      <table className="w-full text-left text-sm table-auto border-collapse">
                        <thead className="bg-slate-50 text-slate-600 text-xs font-semibold border-b border-slate-200 uppercase tracking-wider">
                          <tr>
                            <th className="px-4 py-3.5 min-w-[200px]">Họ và Tên</th>
                            <th className="px-4 py-3.5 min-w-[200px]">Email Cá Nhân</th>
                            <th className="px-4 py-3.5 min-w-[190px]">Phòng Ban & Chức Danh</th>
                            <th className="px-4 py-3.5 w-40">Loại HĐ / Lương</th>
                            <th className="px-4 py-3.5 w-36">Người Tạo (HR)</th>
                            <th className="px-4 py-3.5 text-right w-48">Thao Tác</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100 bg-white">
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
                              <div className="text-xs text-slate-400">{u.createdAt ? formatDateVN(u.createdAt) : ''}</div>
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
                      Xem danh sách phiên, đăng xuất thiết bị từ xa, khóa tài khoản khẩn cấp hoặc cấp mật khẩu tạm.
                    </p>
                  </div>
                  <div className="relative w-full sm:w-72">
                    <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      placeholder="Tìm nhân viên, email, mã NV..."
                      value={searchKeyword}
                      onChange={e => setSearchKeyword(e.target.value)}
                      className="w-full pl-9 pr-3 py-1.5 text-xs sm:text-sm border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white"
                    />
                  </div>
                </div>

                <div className="overflow-hidden border border-slate-200 rounded-xl shadow-xs">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm table-auto border-collapse">
                      <thead className="bg-slate-50 text-slate-600 text-xs font-semibold border-b border-slate-200 uppercase tracking-wider">
                        <tr>
                          <th className="px-4 py-3.5 w-24">Mã NV</th>
                          <th className="px-4 py-3.5 min-w-[200px]">Họ và Tên</th>
                          <th className="px-4 py-3.5 min-w-[220px]">Email Công Ty</th>
                          <th className="px-4 py-3.5 min-w-[200px]">Phòng Ban & Vị Trí</th>
                          <th className="px-4 py-3.5 text-center w-36">Thiết Bị</th>
                          <th className="px-4 py-3.5 text-center w-32">Trạng Thái</th>
                          <th className="px-4 py-3.5 text-center w-20">Thao Tác</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100 bg-white">
                        {accounts
                          .filter(a =>
                            !searchKeyword ||
                            a.fullName?.toLowerCase().includes(searchKeyword.toLowerCase()) ||
                            a.email?.toLowerCase().includes(searchKeyword.toLowerCase()) ||
                            a.employeeCode?.toLowerCase().includes(searchKeyword.toLowerCase()) ||
                            a.departmentName?.toLowerCase().includes(searchKeyword.toLowerCase()) ||
                            a.jobTitle?.toLowerCase().includes(searchKeyword.toLowerCase())
                          )
                          .map(a => (
                            <tr key={a.userId} className="hover:bg-slate-50/80 transition-colors">
                              {/* Mã NV */}
                              <td className="px-4 py-3.5 font-mono text-xs font-semibold">
                                <span className="inline-block px-2 py-0.5 bg-slate-100 text-slate-700 rounded border border-slate-200/60">
                                  {a.employeeCode || '---'}
                                </span>
                              </td>

                              {/* Họ và Tên */}
                              <td className="px-4 py-3.5">
                                <div className="flex items-center gap-3">
                                  <div className="w-8 h-8 rounded-full bg-indigo-100 text-indigo-700 font-bold text-xs flex items-center justify-center shrink-0">
                                    {a.fullName ? a.fullName.split(' ').map((n: string) => n[0]).slice(-2).join('') : 'U'}
                                  </div>
                                  <div>
                                    <div className="font-semibold text-slate-900 leading-tight">{a.fullName}</div>
                                    <div className="text-[11px] text-slate-400 mt-0.5">Gia nhập: {a.joinedDate || '---'}</div>
                                  </div>
                                </div>
                              </td>

                              {/* Email */}
                              <td className="px-4 py-3.5 font-mono text-xs text-slate-600">
                                {a.email}
                              </td>

                              {/* Vị trí & Phòng ban */}
                              <td className="px-4 py-3.5">
                                <div className="font-medium text-slate-800 text-xs">{a.jobTitle}</div>
                                <div className="text-[11px] text-slate-400 mt-0.5">{a.departmentName}</div>
                              </td>

                              {/* Thiết Bị Online - Nhấn để mở Modal xem phiên */}
                              <td className="px-4 py-3.5 text-center">
                                {a.activeSessionCount > 0 ? (
                                  <button
                                    type="button"
                                    onClick={() => handleOpenUserSessions(a)}
                                    className="inline-flex items-center gap-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-xs font-semibold px-2.5 py-1 rounded-full border border-emerald-200 transition-all hover:shadow-xs cursor-pointer group"
                                    title="Nhấn để xem danh sách phiên thiết bị"
                                  >
                                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                    <span>{a.activeSessionCount} máy</span>
                                    <Eye className="w-3 h-3 text-emerald-600 opacity-60 group-hover:opacity-100 transition-opacity ml-0.5" />
                                  </button>
                                ) : (
                                  <button
                                    type="button"
                                    onClick={() => handleOpenUserSessions(a)}
                                    className="inline-flex items-center gap-1 text-xs text-slate-400 hover:text-slate-600 bg-slate-50 hover:bg-slate-100 px-2.5 py-0.5 rounded-full border border-slate-200 transition-colors cursor-pointer"
                                    title="Nhấn để xem lịch sử phiên"
                                  >
                                    <span>Offline</span>
                                  </button>
                                )}
                              </td>

                              {/* Trạng Thái */}
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

                              {/* Thao Tác: 3-dots Dropdown Trigger */}
                              <td className="px-4 py-3.5 text-center">
                                <button
                                  type="button"
                                  onClick={(e) => handleToggleDropdown(e, a)}
                                  className={`w-8 h-8 rounded-lg inline-flex items-center justify-center transition-all cursor-pointer ${
                                    activeDropdownUser?.userId === a.userId
                                      ? 'bg-indigo-600 text-white shadow-xs scale-105'
                                      : 'text-slate-500 hover:text-slate-900 hover:bg-slate-100 border border-slate-200/80 hover:border-slate-300'
                                  }`}
                                  title="Tùy chọn thao tác"
                                >
                                  <MoreHorizontal className="w-4 h-4" />
                                </button>
                              </td>
                            </tr>
                          ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'permissions' && (
              <div className="space-y-4">
                <div>
                  <h3 className="text-base font-semibold text-slate-900">Phân Quyền Xem & Duyệt Theo Từng Nhân Sự</h3>
                  <p className="text-xs text-slate-500">
                    Checkbox trống = chưa cấp thêm (quyền theo phòng ban/chức danh vẫn giữ nguyên).
                    Lưu xong người này bị đăng xuất và phải đăng nhập lại để nhận quyền mới.
                  </p>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
                  {/* Cột trái: tìm + chọn người */}
                  <div className="lg:col-span-2 space-y-3">
                    <div className="relative">
                      <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                      <input
                        type="text"
                        value={permSearch}
                        onChange={e => setPermSearch(e.target.value)}
                        placeholder="Tìm tên, email, mã NV..."
                        aria-label="Tìm nhân sự để phân quyền"
                        className="w-full rounded-xl border border-slate-200 pl-9 pr-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>
                    <div className="border border-slate-200 rounded-xl overflow-hidden max-h-[420px] overflow-y-auto">
                      {filteredPermAccounts.length === 0 ? (
                        <p className="text-xs text-slate-400 text-center py-8">Không tìm thấy nhân sự.</p>
                      ) : (
                        filteredPermAccounts.map(a => (
                          <button
                            key={a.userId}
                            type="button"
                            onClick={() => handleSelectPermUser(a)}
                            className={`w-full text-left px-3.5 py-2.5 border-b border-slate-100 last:border-0 transition-colors cursor-pointer ${
                              permSelected?.userId === a.userId ? 'bg-indigo-50/70' : 'hover:bg-slate-50'
                            }`}
                          >
                            <div className="text-xs font-bold text-slate-900 truncate">{a.fullName}</div>
                            <div className="text-[11px] text-slate-400 font-mono truncate">
                              {a.employeeCode} · {a.email}
                            </div>
                            <div className="text-[11px] text-slate-500 truncate">
                              {a.jobTitle} · {a.departmentName}
                            </div>
                          </button>
                        ))
                      )}
                    </div>
                  </div>

                  {/* Cột phải: checklist quyền */}
                  <div className="lg:col-span-3">
                    {!permSelected ? (
                      <div className="h-full min-h-[200px] flex items-center justify-center border-2 border-dashed border-slate-200 rounded-xl bg-slate-50/50">
                        <p className="text-xs text-slate-400">Chọn 1 nhân sự bên trái để xem và cấp quyền.</p>
                      </div>
                    ) : permLoading ? (
                      <div className="flex items-center justify-center py-20 text-slate-400">
                        <RefreshCw className="w-6 h-6 animate-spin text-indigo-600" />
                      </div>
                    ) : (
                      <div className="space-y-4">
                        <div className="flex items-center justify-between gap-3 flex-wrap">
                          <div>
                            <div className="text-sm font-bold text-slate-900">{permSelected.fullName}</div>
                            <div className="text-[11px] text-slate-500">
                              {permSelected.jobTitle} · {permSelected.departmentName}
                            </div>
                          </div>
                          <button
                            type="button"
                            disabled={!permDirty || actionLoading || (!!currentUser && permSelected.userId === currentUser.userId)}
                            onClick={handleSavePermissions}
                            title={!!currentUser && permSelected.userId === currentUser.userId ? 'Không thể tự cấp quyền cho chính mình' : undefined}
                            className="flex items-center gap-1.5 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold transition-all cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                          >
                            <CheckCircle2 className="w-4 h-4" />
                            <span>{actionLoading ? 'Đang lưu...' : 'Lưu phân quyền'}</span>
                          </button>
                        </div>
                        {currentUser && permSelected.userId === currentUser.userId && (
                          <div className="flex items-start gap-2 px-3.5 py-2.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-800 text-xs font-medium">
                            <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
                            <span>Đang xem chính tài khoản của bạn — hệ thống không cho tự cấp / tự gỡ quyền (chống leo thang đặc quyền). Nhờ SysAdmin hoặc người được ủy quyền khác thực hiện.</span>
                          </div>
                        )}

                        {PERMISSION_GROUPS.map(group => (
                          <div key={group.title} className="border border-slate-200 rounded-xl overflow-hidden">
                            <div className="px-3.5 py-2 bg-slate-50 border-b border-slate-200 text-xs font-bold text-slate-700">
                              {group.title}
                            </div>
                            <div className="divide-y divide-slate-100">
                              {group.keys.map(key => {
                                const granted = permGrants.find(g => g.key === key);
                                const checked = permChecked.includes(key);
                                return (
                                  <label
                                    key={key}
                                    title={PERMISSION_DESCRIPTIONS[key]}
                                    className="flex items-start gap-3 px-3.5 py-2.5 cursor-pointer hover:bg-slate-50 transition-colors"
                                  >
                                    <input
                                      type="checkbox"
                                      checked={checked}
                                      onChange={() => togglePermKey(key)}
                                      disabled={!!currentUser && !!permSelected && permSelected.userId === currentUser.userId}
                                      aria-label={PERMISSION_LABELS[key]}
                                      className="mt-0.5 w-4 h-4 accent-indigo-600 cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed"
                                    />
                                    <span className="flex-1">
                                      <span className="block text-xs font-semibold text-slate-800">
                                        {PERMISSION_LABELS[key]}
                                      </span>
                                      {granted && (
                                        <span className="block text-[11px] text-emerald-700 mt-0.5">
                                          Được cấp bởi {granted.grantedByName}
                                          {granted.grantedAt ? ` · ${formatDateVN(granted.grantedAt)}` : ''}
                                        </span>
                                      )}
                                    </span>
                                  </label>
                                );
                              })}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
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
      {/* ─── MODAL 8: QUẢN LÝ PHIÊN THIẾT BỊ CỦA NHÂN VIÊN ─── */}
      {userSessionsModal.open && userSessionsModal.user && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 z-50 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl max-w-4xl w-full shadow-2xl border border-slate-100 overflow-hidden flex flex-col max-h-[90vh]">
            {/* Modal Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between p-5 bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 text-white gap-4 shrink-0">
              <div className="flex items-center gap-3">
                <div className="w-11 h-11 rounded-xl bg-indigo-500/30 border border-indigo-400/30 text-indigo-200 flex items-center justify-center font-bold text-base shrink-0">
                  {userSessionsModal.user.fullName
                    ? userSessionsModal.user.fullName.split(' ').map((n: string) => n[0]).slice(-2).join('')
                    : 'U'}
                </div>
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <h3 className="text-base font-bold text-white">
                      Phiên Thiết Bị: {userSessionsModal.user.fullName}
                    </h3>
                    <span className="font-mono text-xs px-2 py-0.5 bg-white/10 rounded text-indigo-300 font-semibold">
                      {userSessionsModal.user.employeeCode}
                    </span>
                  </div>
                  <p className="text-xs text-slate-300 mt-0.5">
                    {userSessionsModal.user.email} • {userSessionsModal.user.jobTitle} ({userSessionsModal.user.departmentName})
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2 self-end sm:self-auto">
                {/* Nút Đăng xuất toàn bộ thiết bị */}
                <button
                  type="button"
                  disabled={actionLoading || userSessionsModal.sessions.filter(s => !s.revoked).length === 0}
                  onClick={() =>
                    handleRevokeAllUserSessions(userSessionsModal.user!.userId, userSessionsModal.user!.fullName)
                  }
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-rose-600 hover:bg-rose-700 disabled:opacity-40 disabled:hover:bg-rose-600 text-white rounded-xl text-xs font-semibold shadow-xs transition-colors cursor-pointer disabled:cursor-not-allowed"
                  title="Đăng xuất khỏi toàn bộ các thiết bị đang kết nối"
                >
                  <LogOut className="w-3.5 h-3.5" />
                  <span>Đăng xuất tất cả thiết bị</span>
                </button>

                <button
                  type="button"
                  onClick={() => setUserSessionsModal(prev => ({ ...prev, open: false }))}
                  className="p-1.5 text-slate-400 hover:text-white hover:bg-white/10 rounded-lg transition-colors cursor-pointer"
                  title="Đóng modal"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Filter and Search Bar */}
            <div className="p-4 bg-slate-50 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shrink-0">
              <div className="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0">
                <button
                  type="button"
                  onClick={() => setUserSessionsModal(prev => ({ ...prev, statusFilter: 'ALL' }))}
                  className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
                    userSessionsModal.statusFilter === 'ALL'
                      ? 'bg-indigo-600 text-white shadow-xs'
                      : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
                  }`}
                >
                  Tất cả ({userSessionsModal.sessions.length})
                </button>
                <button
                  type="button"
                  onClick={() => setUserSessionsModal(prev => ({ ...prev, statusFilter: 'ONLINE' }))}
                  className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all flex items-center gap-1.5 cursor-pointer ${
                    userSessionsModal.statusFilter === 'ONLINE'
                      ? 'bg-emerald-600 text-white shadow-xs'
                      : 'bg-white text-emerald-700 hover:bg-emerald-50 border border-emerald-200'
                  }`}
                >
                  <span
                    className={`w-1.5 h-1.5 rounded-full ${
                      userSessionsModal.statusFilter === 'ONLINE' ? 'bg-white' : 'bg-emerald-500'
                    } animate-pulse`}
                  ></span>
                  <span>Đang Online ({userSessionsModal.sessions.filter(s => !s.revoked).length})</span>
                </button>
                <button
                  type="button"
                  onClick={() => setUserSessionsModal(prev => ({ ...prev, statusFilter: 'REVOKED' }))}
                  className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
                    userSessionsModal.statusFilter === 'REVOKED'
                      ? 'bg-slate-700 text-white shadow-xs'
                      : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
                  }`}
                >
                  Đã thu hồi ({userSessionsModal.sessions.filter(s => s.revoked).length})
                </button>
              </div>

              <div className="flex items-center gap-2">
                <div className="relative w-full sm:w-64">
                  <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder="Tìm OS, trình duyệt, IP..."
                    value={userSessionsModal.search}
                    onChange={e => setUserSessionsModal(prev => ({ ...prev, search: e.target.value }))}
                    className="w-full pl-8 pr-3 py-1.5 text-xs bg-white border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                <button
                  type="button"
                  onClick={handleRefreshUserSessions}
                  disabled={userSessionsModal.loading}
                  className="p-1.5 bg-white border border-slate-200 hover:bg-slate-100 text-slate-600 rounded-lg transition-colors shrink-0 cursor-pointer"
                  title="Làm mới danh sách phiên"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${userSessionsModal.loading ? 'animate-spin' : ''}`} />
                </button>
              </div>
            </div>

            {/* Modal Table Body */}
            <div className="overflow-y-auto p-4 flex-1">
              {userSessionsModal.loading ? (
                <div className="flex flex-col items-center justify-center py-16 text-slate-400">
                  <RefreshCw className="w-7 h-7 animate-spin mb-2 text-indigo-600" />
                  <p className="text-xs">Đang nạp danh sách phiên thiết bị...</p>
                </div>
              ) : filteredModalSessions.length === 0 ? (
                <div className="text-center py-12 border-2 border-dashed border-slate-200 rounded-xl bg-slate-50/50">
                  <Laptop className="w-10 h-10 text-slate-300 mx-auto mb-2" />
                  <p className="text-sm font-semibold text-slate-700">Không tìm thấy phiên đăng nhập nào</p>
                  <p className="text-xs text-slate-400 mt-1">
                    {userSessionsModal.search || userSessionsModal.statusFilter !== 'ALL'
                      ? 'Thử đổi từ khóa tìm kiếm hoặc chọn bộ lọc Tất cả.'
                      : 'Nhân viên này hiện không có phiên đăng nhập nào được ghi nhận.'}
                  </p>
                </div>
              ) : (
                <div className="overflow-hidden border border-slate-200 rounded-xl">
                  <table className="w-full text-left text-xs">
                    <thead className="bg-slate-50 text-slate-600 font-semibold border-b border-slate-200 uppercase tracking-wider">
                      <tr>
                        <th className="px-3.5 py-3">Thiết Bị & HĐH</th>
                        <th className="px-3.5 py-3">Trình Duyệt</th>
                        <th className="px-3.5 py-3">Địa Chỉ IP & Vị Trí</th>
                        <th className="px-3.5 py-3">Đăng Nhập Lúc</th>
                        <th className="px-3.5 py-3 text-center">Trạng Thái</th>
                        <th className="px-3.5 py-3 text-right">Thao Tác</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 bg-white">
                      {filteredModalSessions.map(s => {
                        const isPhone =
                          s.deviceType?.toLowerCase().includes('phone') || s.deviceType?.toLowerCase().includes('mobile');
                        const isTablet = s.deviceType?.toLowerCase().includes('tablet');

                        return (
                          <tr
                            key={s.sessionId}
                            className={`hover:bg-slate-50/80 transition-colors ${
                              s.revoked ? 'opacity-60 bg-slate-50/40' : ''
                            }`}
                          >
                            <td className="px-3.5 py-3">
                              <div className="flex items-center gap-2.5">
                                <div className="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center shrink-0">
                                  {isPhone ? (
                                    <Smartphone className="w-4 h-4 text-slate-600" />
                                  ) : isTablet ? (
                                    <Tablet className="w-4 h-4 text-slate-600" />
                                  ) : (
                                    <Laptop className="w-4 h-4 text-slate-600" />
                                  )}
                                </div>
                                <div>
                                  <div className="font-semibold text-slate-900">{s.deviceOS || 'Unknown OS'}</div>
                                  <div className="text-[10px] text-slate-400">{s.deviceType || 'Desktop'}</div>
                                </div>
                              </div>
                            </td>

                            <td className="px-3.5 py-3 text-slate-700">
                              <div className="font-medium">{s.browser || 'Browser'}</div>
                            </td>

                            <td className="px-3.5 py-3">
                              <div className="font-mono text-indigo-600 font-semibold">{s.ipAddr || '---'}</div>
                              <div className="text-[10px] text-slate-400">
                                {s.city && s.country ? `${s.city}, ${s.country}` : s.isp || 'Localhost / Intranet'}
                              </div>
                            </td>

                            <td className="px-3.5 py-3 text-slate-500">
                              <div>{s.createdAt ? formatDateVN(s.createdAt) : '---'}</div>
                            </td>

                            <td className="px-3.5 py-3 text-center">
                              {s.revoked ? (
                                <span className="inline-block text-[11px] bg-slate-100 text-slate-500 px-2 py-0.5 rounded font-medium">
                                  Đã thu hồi
                                </span>
                              ) : (
                                <span className="inline-flex items-center gap-1 text-[11px] bg-emerald-50 text-emerald-700 px-2.5 py-0.5 rounded-full font-semibold border border-emerald-200">
                                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                  Online
                                </span>
                              )}
                            </td>

                            <td className="px-3.5 py-3 text-right">
                              {!s.revoked ? (
                                <button
                                  type="button"
                                  disabled={actionLoading}
                                  onClick={() => handleRevokeSession(s.sessionId)}
                                  className="inline-flex items-center gap-1 px-2.5 py-1 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-lg text-xs font-semibold transition-colors cursor-pointer"
                                  title="Ngắt kết nối phiên này"
                                >
                                  <LogOut className="w-3 h-3 text-rose-600" />
                                  <span>Đá phiên</span>
                                </button>
                              ) : (
                                <span className="text-[11px] text-slate-400 italic">Đã ngắt</span>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* Modal Footer */}
            <div className="p-4 bg-slate-50 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500 shrink-0">
              <p>💡 Thu hồi phiên sẽ vô hiệu hóa Token và buộc thiết bị phải đăng xuất ngay lập tức.</p>
              <button
                type="button"
                onClick={() => setUserSessionsModal(prev => ({ ...prev, open: false }))}
                className="px-4 py-2 bg-slate-200 hover:bg-slate-300 text-slate-800 rounded-xl font-semibold transition-colors cursor-pointer"
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ─── FLOATING ACTION DROPDOWN MENU ─── */}
      {activeDropdownUser && dropdownPos && (
        <>
          {/* Backdrop to close dropdown on click outside */}
          <div
            className="fixed inset-0 z-40 bg-transparent"
            onClick={() => {
              setActiveDropdownUser(null);
              setDropdownPos(null);
            }}
          />

          {/* Dropdown Card */}
          <div
            style={{ position: 'fixed', top: dropdownPos.top, right: dropdownPos.right }}
            className="z-50 w-64 bg-white rounded-2xl shadow-2xl border border-slate-200/90 p-1.5 animate-in fade-in zoom-in-95 duration-100 text-left select-none"
          >
            {/* Header info */}
            <div className="px-3 py-2 border-b border-slate-100 mb-1">
              <div className="text-xs font-bold text-slate-900 truncate">{activeDropdownUser.fullName}</div>
              <div className="text-[11px] text-slate-400 font-mono truncate">
                {activeDropdownUser.employeeCode} · {activeDropdownUser.email}
              </div>
            </div>

            {/* Menu Actions */}
            <div className="space-y-0.5">
              {/* Xem phiên & thiết bị */}
              <button
                type="button"
                onClick={() => {
                  const user = activeDropdownUser;
                  setActiveDropdownUser(null);
                  setDropdownPos(null);
                  handleOpenUserSessions(user);
                }}
                className="w-full flex items-center justify-between px-3 py-2 text-xs font-medium text-slate-700 hover:text-indigo-600 hover:bg-indigo-50/70 rounded-xl transition-colors cursor-pointer group"
              >
                <div className="flex items-center gap-2.5">
                  <Laptop className="w-4 h-4 text-slate-400 group-hover:text-indigo-600" />
                  <span>Xem phiên & thiết bị</span>
                </div>
                {activeDropdownUser.activeSessionCount > 0 ? (
                  <span className="text-[10px] font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                    {activeDropdownUser.activeSessionCount} online
                  </span>
                ) : (
                  <span className="text-[10px] text-slate-400">Offline</span>
                )}
              </button>

              {/* Đăng xuất toàn bộ */}
              <button
                type="button"
                disabled={activeDropdownUser.activeSessionCount === 0 || actionLoading}
                onClick={() => {
                  const user = activeDropdownUser;
                  setActiveDropdownUser(null);
                  setDropdownPos(null);
                  handleRevokeAllUserSessions(user.userId, user.fullName);
                }}
                className="w-full flex items-center justify-between px-3 py-2 text-xs font-medium rounded-xl transition-colors cursor-pointer text-rose-600 hover:bg-rose-50 disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:bg-transparent"
              >
                <div className="flex items-center gap-2.5">
                  <LogOut className="w-4 h-4 text-rose-500" />
                  <span>Đăng xuất toàn bộ</span>
                </div>
                {activeDropdownUser.activeSessionCount > 0 && (
                  <span className="text-[10px] font-semibold text-rose-600 bg-rose-50 px-1.5 py-0.5 rounded-md">
                    {activeDropdownUser.activeSessionCount} máy
                  </span>
                )}
              </button>

              <div className="my-1 border-t border-slate-100" />

              {/* Cấp lại mật khẩu tạm */}
              {/* Cấp lại mật khẩu tạm — quyền riêng của admin, ACCOUNT_LOCK không gồm */}
              {isAdmin && (
              <button
                type="button"
                onClick={() => {
                  const user = activeDropdownUser;
                  setActiveDropdownUser(null);
                  setDropdownPos(null);
                  setResetPassModal({ open: true, user });
                }}
                className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-700 hover:text-amber-700 hover:bg-amber-50/70 rounded-xl transition-colors cursor-pointer group"
              >
                <KeyRound className="w-4 h-4 text-slate-400 group-hover:text-amber-600" />
                <span>Cấp lại mật khẩu tạm</span>
              </button>
              )}

              {/* Khóa / Mở khóa tài khoản */}
              <button
                type="button"
                disabled={actionLoading}
                onClick={() => {
                  const user = activeDropdownUser;
                  setActiveDropdownUser(null);
                  setDropdownPos(null);
                  setStatusConfirmModal({
                    open: true,
                    user,
                    nextStatus: !user.isActive
                  });
                }}
                className={`w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium rounded-xl transition-colors cursor-pointer ${
                  activeDropdownUser.isActive
                    ? 'text-rose-600 hover:bg-rose-50'
                    : 'text-emerald-700 hover:bg-emerald-50'
                }`}
              >
                {activeDropdownUser.isActive ? (
                  <>
                    <Lock className="w-4 h-4 text-rose-500" />
                    <span>Khóa tài khoản</span>
                  </>
                ) : (
                  <>
                    <Unlock className="w-4 h-4 text-emerald-600" />
                    <span>Mở khóa tài khoản</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </>
      )}
      </div>
    </AppShell>
  );
}
