'use client';

import React, { createContext, useContext, useState, useEffect, useMemo, useCallback } from 'react';
import { User, RoleLevel, DepartmentName, JobTitle } from '@/types';
import { authService } from '@/services/authService';
import { employeeService } from '@/services/employeeService';

interface AuthContextType {
  currentUser: User | null;
  roleLevel: RoleLevel;
  isExecutive: boolean;
  isHR: boolean;
  isHRHead: boolean;
  isAdmin: boolean;
  isSysAdmin: boolean;
  isManager: boolean;
  isAccounting: boolean;
  isChiefAccountant: boolean;
  isStaff: boolean;
  login: (email: string, password?: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
  switchUser: (userId: string) => Promise<void>;
  allUsers: User[];
  refreshProfile: () => Promise<void>;
  isLoading: boolean;
  /** Grants Admin cấp thêm (đọc từ claim `permissions` trong JWT, không tốn API call) */
  permissions: string[];
  can: (key: string) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [allUsers, setAllUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Derive role level according to docs/api-reference.md (backend dept names are short: "IT", not "Information Technology")
  const getRoleLevel = (user: User | null): RoleLevel => {
    if (!user) return 'STAFF';
    if (user.department === 'Executive Leadership') return 'EXECUTIVE';
    const dept = (user.department || '').toLowerCase().trim();
    const job = (user.job || '').toLowerCase();
    const email = (user.email || '').toLowerCase();
    if (email === 'sysadmin@company.com') return 'ADMIN';
    // ponytail: exact 'it' match first ('it'.includes('it') is true but 'information technology'.includes('it') is false, so old substring check was fragile)
    if (
      (dept === 'it' || dept === 'information technology' || dept.includes('information technology') || dept.includes('công nghệ'))
      && (job.includes('system administrator') || job.includes('admin'))
    ) {
      return 'ADMIN';
    }
    if (dept.includes('human resources') || dept.includes('nhân sự')) return 'HR';
    if (job.startsWith('department head') || job.includes('trưởng phòng')) return 'MANAGER';
    return 'STAFF';
  };

  const roleLevel = getRoleLevel(currentUser);
  const isExecutive = roleLevel === 'EXECUTIVE';
  
  // System Admin: IT dept with System Administrator/Admin in job, OR Executive, OR sysadmin email
  const isSysAdmin = Boolean(
    roleLevel === 'ADMIN' ||
    currentUser?.email?.toLowerCase() === 'sysadmin@company.com' ||
    ((currentUser?.department === 'Information Technology' || currentUser?.department === ('IT' as any)) &&
      (currentUser?.job?.includes('System Administrator') || currentUser?.job?.includes('Admin')))
  );
  const isAdmin = Boolean(isSysAdmin || isExecutive);
  // Admin = nhân viên thường + quyền trang /admin; KHÔNG kế thừa quyền nghiệp vụ HR/Managaer (backend company endpoints chỉ cho Human Resources)
  const isHR = roleLevel === 'HR' || isExecutive;
  // roleLevel trả 'HR' cho MỌI người ở Human Resources nên "Department Head of Human Resources"
  // không bao giờ ra 'MANAGER'. Backend thì ở 11 chỗ check job.startsWith("Department Head")
  // → phải tính lại từ job, không tin roleLevel.
  const isDeptHeadJob = Boolean(currentUser?.job?.toLowerCase().startsWith('department head'));
  const isHRHead = (roleLevel === 'HR' && isDeptHeadJob) || isExecutive;
  const isManager = Boolean(roleLevel === 'MANAGER' || isExecutive || isDeptHeadJob);

  // Accounting & Chief Accountant roles from docs/api-reference.md
  const deptLower = (currentUser?.department || '').toLowerCase();
  const jobLower = (currentUser?.job || '').toLowerCase();
  const isAccounting = Boolean(
    deptLower.includes('accounting') ||
    deptLower.includes('finance') ||
    deptLower.includes('kế toán') ||
    deptLower.includes('tài chính') ||
    jobLower.includes('accountant') ||
    jobLower.includes('kế toán')
  );
  const isChiefAccountant = Boolean(
    isExecutive ||
    (isAccounting && (
      jobLower.includes('head') ||
      jobLower.includes('manager') ||
      jobLower.includes('lead') ||
      jobLower.includes('trưởng')
    ))
  );

  const isStaff = true;

  // ponytail: decode JWT tại chỗ thay vì state + API riêng; memo theo currentUser để `can` ổn định cho hooks deps
  // (grant đổi → backend đá session → login lại → currentUser đổi → tính lại)
  const permissions = useMemo((): string[] => {
    try {
      const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
      if (!token) return [];
      const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
      return Array.isArray(payload.permissions) ? payload.permissions : [];
    } catch {
      return [];
    }
  }, [currentUser]);
  const can = useCallback((key: string) => permissions.includes(key), [permissions]);

  // Load active user session from backend
  const refreshProfile = async () => {
    try {
      const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
      if (!token) {
        setCurrentUser(null);
        return;
      }

      const detailed = await employeeService.getMyDetailedProfile();
      if (detailed && detailed.userId) {
        const userObj: User = {
          userId: detailed.userId,
          employeeCode: detailed.employeeCode || 'EMP001',
          email: detailed.email,
          firstName: detailed.firstName || '',
          lastName: detailed.lastName || '',
          fullName: detailed.fullName || `${detailed.firstName || ''} ${detailed.lastName || ''}`.trim(),
          // ponytail: empty default = STAFF (old 'Executive Leadership' default silently granted executive rights on missing dept)
          department: (detailed.department as DepartmentName) || ('' as DepartmentName),
          job: (detailed.job as JobTitle) || ('' as JobTitle),
          profilePicUrl: detailed.profilePicUrl,
          todayStatus: detailed.todayStatus || 'WORKING',
          gender: detailed.gender,
          birthDate: detailed.birthDate,
          joinedDate: detailed.joinedDate,
          phoneNumber: detailed.phoneNumber,
          annualLeaveDays: detailed.annualLeaveDays || 12,
          usedLeaveDays: detailed.usedLeaveDays || 0,
          shiftName: detailed.shiftName || 'Ca Hành Chính',
          shiftStartTime: detailed.shiftStartTime || '08:00',
          shiftEndTime: detailed.shiftEndTime || '17:30',
          restDays: detailed.restDays || [6, 7]
        };
        setCurrentUser(userObj);
        if (typeof window !== 'undefined') {
          localStorage.setItem('act_hrm_user_id', userObj.userId);
        }
      }
    } catch (err: any) {
      setCurrentUser(null);
      // ponytail: only drop the token on 401 — a 500 (e.g. profile query bug) must not log the user out
      if (err?.status === 401 && typeof window !== 'undefined') {
        localStorage.removeItem('act_hrm_access_token');
        localStorage.removeItem('act_hrm_user_id');
      }
    }
  };

  useEffect(() => {
    const initAuth = async () => {
      setIsLoading(true);
      try {
        const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
        if (token) {
          await refreshProfile();
          const res = await employeeService.getEmployees({ size: 100 });
          if (res && res.content && res.content.length > 0) {
            setAllUsers(res.content);
          }
        }
      } catch {
        // Backend might still be starting
      } finally {
        setIsLoading(false);
      }
    };
    initAuth();
  }, []);

  const login = async (email: string, password = 'test@123'): Promise<{ success: boolean; error?: string }> => {
    setIsLoading(true);
    try {
      const res = await authService.login(email, password);
      if (res && res.accessToken) {
        if (typeof window !== 'undefined') {
          localStorage.setItem('act_hrm_access_token', res.accessToken);
        }
        await refreshProfile();
        try {
          const empRes = await employeeService.getEmployees({ size: 100 });
          if (empRes && empRes.content && empRes.content.length > 0) {
            setAllUsers(empRes.content);
          }
        } catch {
          // ignore directory fetch error
        }
        return { success: true };
      }
      return { success: false, error: 'Đăng nhập không thành công' };
    } catch (err: any) {
      const errorMsg = err.message || 'Email hoặc mật khẩu không chính xác';
      return { success: false, error: errorMsg };
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    try {
      await authService.logout();
    } catch {
      // ignore
    } finally {
      setCurrentUser(null);
      if (typeof window !== 'undefined') {
        localStorage.removeItem('act_hrm_access_token');
        localStorage.removeItem('act_hrm_user_id');
        window.location.href = '/login';
      }
    }
  };

  const switchUser = async (userId: string) => {
    const target = allUsers.find(u => u.userId === userId);
    if (!target) return;

    setIsLoading(true);
    try {
      const res = await authService.login(target.email, 'test@123');
      if (res && res.accessToken && typeof window !== 'undefined') {
        localStorage.setItem('act_hrm_access_token', res.accessToken);
        localStorage.setItem('act_hrm_user_id', target.userId);
        await refreshProfile();
      }
    } catch {
      // In case password was modified
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        roleLevel,
        isExecutive,
        isHR,
        isHRHead,
        isAdmin,
        isSysAdmin,
        isManager,
        isAccounting,
        isChiefAccountant,
        isStaff,
        login,
        logout,
        switchUser,
        allUsers,
        refreshProfile,
        isLoading,
        permissions,
        can
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
