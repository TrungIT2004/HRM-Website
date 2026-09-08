'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, RoleLevel } from '@/types';
import { MOCK_USERS, DEFAULT_USER } from '@/mock/users';

interface AuthContextType {
  currentUser: User | null;
  roleLevel: RoleLevel;
  isExecutive: boolean;
  isHR: boolean;
  isManager: boolean;
  isStaff: boolean;
  login: (email: string, password?: string) => Promise<boolean>;
  logout: () => void;
  switchUser: (userId: string) => void;
  allUsers: User[];
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  useEffect(() => {
    // Check saved session or default to DEFAULT_USER
    const savedId = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_user_id') : null;
    if (savedId) {
      const found = MOCK_USERS.find(u => u.userId === savedId);
      if (found) {
        setCurrentUser(found);
        return;
      }
    }
    // Default logged in user
    setCurrentUser(DEFAULT_USER);
  }, []);

  const getRoleLevel = (user: User | null): RoleLevel => {
    if (!user) return 'STAFF';
    if (user.department === 'Executive Leadership') return 'EXECUTIVE';
    if (user.department === 'Human Resources' && (user.job.includes('Head') || user.job.includes('Specialist') || user.job.includes('Generalist'))) return 'HR';
    if (user.job.includes('Department Head')) return 'MANAGER';
    return 'STAFF';
  };

  const roleLevel = getRoleLevel(currentUser);
  const isExecutive = roleLevel === 'EXECUTIVE';
  const isHR = roleLevel === 'HR' || isExecutive;
  const isManager = roleLevel === 'MANAGER' || isHR || isExecutive;
  const isStaff = true;

  const login = async (email: string, password = 'test@123'): Promise<boolean> => {
    const user = MOCK_USERS.find(u => u.email.toLowerCase() === email.toLowerCase());
    if (user && (password === 'test@123' || password.length > 0)) {
      setCurrentUser(user);
      if (typeof window !== 'undefined') {
        localStorage.setItem('act_hrm_user_id', user.userId);
      }
      return true;
    }
    return false;
  };

  const logout = () => {
    setCurrentUser(null);
    if (typeof window !== 'undefined') {
      localStorage.removeItem('act_hrm_user_id');
    }
  };

  const switchUser = (userId: string) => {
    const user = MOCK_USERS.find(u => u.userId === userId);
    if (user) {
      setCurrentUser(user);
      if (typeof window !== 'undefined') {
        localStorage.setItem('act_hrm_user_id', user.userId);
      }
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
        allUsers: MOCK_USERS
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
