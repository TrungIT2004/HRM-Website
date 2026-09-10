'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, RoleLevel, DepartmentName, JobTitle } from '@/types';
import { MOCK_USERS, DEFAULT_USER } from '@/mock/users';
import { authService } from '@/services/authService';
import { employeeService } from '@/services/employeeService';

interface AuthContextType {
  currentUser: User | null;
  roleLevel: RoleLevel;
  isExecutive: boolean;
  isHR: boolean;
  isManager: boolean;
  isStaff: boolean;
  login: (email: string, password?: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
  switchUser: (userId: string) => Promise<void>;
  allUsers: User[];
  refreshProfile: () => Promise<void>;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [allUsers, setAllUsers] = useState<User[]>(MOCK_USERS);
  const [isLoading, setIsLoading] = useState(true);

  const getRoleLevel = (user: User | null): RoleLevel => {
    if (!user) return 'STAFF';
    if (user.department === 'Executive Leadership') return 'EXECUTIVE';
    if (
      user.department === 'Human Resources' &&
      (user.job.includes('Head') || user.job.includes('Specialist') || user.job.includes('Generalist'))
    )
      return 'HR';
    if (user.job.includes('Department Head')) return 'MANAGER';
    return 'STAFF';
  };

  const roleLevel = getRoleLevel(currentUser);
  const isExecutive = roleLevel === 'EXECUTIVE';
  const isHR = roleLevel === 'HR' || isExecutive;
  const isManager = roleLevel === 'MANAGER' || isHR || isExecutive;
  const isStaff = true;

  // Load active user session on app launch
  const refreshProfile = async () => {
    try {
      const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
      if (!token) {
        // No token, try fallback to saved mock user or null
        const savedId = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_user_id') : null;
        if (savedId) {
          const found = allUsers.find(u => u.userId === savedId);
          if (found) {
            setCurrentUser(found);
            return;
          }
        }
        setCurrentUser(DEFAULT_USER);
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
          department: (detailed.department as DepartmentName) || 'Executive Leadership',
          job: (detailed.job as JobTitle) || 'Chairman',
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
    } catch {
      // Fallback
      const savedId = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_user_id') : null;
      const found = allUsers.find(u => u.userId === savedId);
      setCurrentUser(found || DEFAULT_USER);
    }
  };

  useEffect(() => {
    const initAuth = async () => {
      setIsLoading(true);
      await refreshProfile();
      // Load real employees for directory and RoleSwitcher
      try {
        const res = await employeeService.getEmployees({ size: 50 });
        if (res && res.content && res.content.length > 0) {
          setAllUsers(res.content);
        }
      } catch {
        // Fallback to MOCK_USERS if backend is not yet populated
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

        // Fetch detailed profile
        await refreshProfile();
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
      }
    }
  };

  const switchUser = async (userId: string) => {
    const target = allUsers.find(u => u.userId === userId) || MOCK_USERS.find(u => u.userId === userId);
    if (!target) return;

    setIsLoading(true);
    try {
      // Try login to backend with target user's email and default password test@123
      const res = await authService.login(target.email, 'test@123');
      if (res && res.accessToken && typeof window !== 'undefined') {
        localStorage.setItem('act_hrm_access_token', res.accessToken);
        localStorage.setItem('act_hrm_user_id', target.userId);
        await refreshProfile();
        return;
      }
    } catch {
      // If login fails (e.g. customized password), set local user for preview
    } finally {
      setCurrentUser(target);
      if (typeof window !== 'undefined') {
        localStorage.setItem('act_hrm_user_id', target.userId);
      }
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
        isManager,
        isStaff,
        login,
        logout,
        switchUser,
        allUsers,
        refreshProfile,
        isLoading
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
