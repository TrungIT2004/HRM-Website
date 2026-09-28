'use client';

import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Shield, ChevronUp, ChevronDown, Check, UserCheck, Sparkles } from 'lucide-react';

export default function RoleSwitcher() {
  const { currentUser, switchUser, allUsers, roleLevel } = useAuth();
  const [isOpen, setIsOpen] = useState(false);

  // Group users by Tier
  const executiveUsers = allUsers.filter(u => u.department === 'Executive Leadership');
  const adminUsers = allUsers.filter(u => 
    (u.department === 'Information Technology' && (u.job.includes('System Administrator') || u.job.includes('Admin'))) || 
    u.email === 'sysadmin@company.com'
  );
  const hrUsers = allUsers.filter(u => u.department === 'Human Resources');
  const managerUsers = allUsers.filter(u => u.department !== 'Executive Leadership' && u.department !== 'Human Resources' && u.job.includes('Department Head'));
  const staffUsers = allUsers.filter(u => 
    !u.job.includes('Department Head') && 
    u.department !== 'Executive Leadership' && 
    u.department !== 'Human Resources' &&
    !adminUsers.some(a => a.userId === u.userId)
  );

  if (!currentUser) return null;

  return (
    <div className="fixed bottom-20 right-3.5 md:bottom-4 md:right-4 z-40">
      {/* Popover Card */}
      {isOpen && (
        <div className="mb-2 w-80 sm:w-96 rounded-2xl bg-white p-4 shadow-2xl border border-slate-200 animate-in slide-in-from-bottom-5 duration-200 max-h-[75vh] overflow-y-auto">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2">
              <Shield className="h-5 w-5 text-blue-600" />
              <span className="text-sm font-bold text-slate-900">Bộ Chuyển Đổi Quyền Hạn (Demo)</span>
            </div>
            <button
              onClick={() => setIsOpen(false)}
              className="text-xs text-slate-400 hover:text-slate-600 cursor-pointer"
            >
              Đóng
            </button>
          </div>

          <p className="mt-2 text-[11px] text-slate-500">
            Chuyển nhanh sang 1 trong 15 nhân viên trong cơ sở dữ liệu để kiểm tra giao diện phân quyền tương ứng.
          </p>

          <div className="mt-3 space-y-3 text-xs">
            {/* 1. Ban Giám Đốc */}
            <div>
              <div className="font-bold text-purple-700 uppercase tracking-wider text-[10px] mb-1.5 flex items-center gap-1">
                <span>👑 Ban Giám Đốc (Super-Admin)</span>
              </div>
              <div className="space-y-1">
                {executiveUsers.map(u => (
                  <button
                    key={u.userId}
                    onClick={() => {
                      switchUser(u.userId);
                      setIsOpen(false);
                    }}
                    className={`w-full flex items-center justify-between p-2 rounded-lg text-left transition cursor-pointer ${
                      currentUser?.userId === u.userId
                        ? 'bg-purple-50 text-purple-900 font-semibold ring-1 ring-purple-300'
                        : 'hover:bg-slate-50 text-slate-700'
                    }`}
                  >
                    <div>
                      <div className="font-medium text-xs">{u.fullName}</div>
                      <div className="text-[10px] text-slate-400">{u.job} ({u.employeeCode})</div>
                    </div>
                    {currentUser?.userId === u.userId && <Check className="h-4 w-4 text-purple-600" />}
                  </button>
                ))}
              </div>
            </div>

            {/* 1.5. Quản Trị Hệ Thống (Admin) */}
            {adminUsers.length > 0 && (
              <div>
                <div className="font-bold text-indigo-700 uppercase tracking-wider text-[10px] mb-1.5 flex items-center gap-1">
                  <span>🛡️ Quản Trị Hệ Thống (System Admin)</span>
                </div>
                <div className="space-y-1">
                  {adminUsers.map(u => (
                    <button
                      key={u.userId}
                      onClick={() => {
                        switchUser(u.userId);
                        setIsOpen(false);
                      }}
                      className={`w-full flex items-center justify-between p-2 rounded-lg text-left transition cursor-pointer ${
                        currentUser?.userId === u.userId
                          ? 'bg-indigo-50 text-indigo-900 font-semibold ring-1 ring-indigo-300'
                          : 'hover:bg-slate-50 text-slate-700'
                      }`}
                    >
                      <div>
                        <div className="font-medium text-xs">{u.fullName}</div>
                        <div className="text-[10px] text-slate-400">{u.job} ({u.employeeCode})</div>
                      </div>
                      {currentUser?.userId === u.userId && <Check className="h-4 w-4 text-indigo-600" />}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* 2. Quản Trị Nhân Sự */}
            <div>
              <div className="font-bold text-blue-700 uppercase tracking-wider text-[10px] mb-1.5">
                💼 Phòng Nhân Sự (HR Management)
              </div>
              <div className="space-y-1">
                {hrUsers.map(u => (
                  <button
                    key={u.userId}
                    onClick={() => {
                      switchUser(u.userId);
                      setIsOpen(false);
                    }}
                    className={`w-full flex items-center justify-between p-2 rounded-lg text-left transition cursor-pointer ${
                      currentUser?.userId === u.userId
                        ? 'bg-blue-50 text-blue-900 font-semibold ring-1 ring-blue-300'
                        : 'hover:bg-slate-50 text-slate-700'
                    }`}
                  >
                    <div>
                      <div className="font-medium text-xs">{u.fullName}</div>
                      <div className="text-[10px] text-slate-400">{u.job} ({u.employeeCode})</div>
                    </div>
                    {currentUser?.userId === u.userId && <Check className="h-4 w-4 text-blue-600" />}
                  </button>
                ))}
              </div>
            </div>

            {/* 3. Trưởng Phòng */}
            <div>
              <div className="font-bold text-amber-700 uppercase tracking-wider text-[10px] mb-1.5">
                🏢 Trưởng Các Phòng Ban (Managers)
              </div>
              <div className="space-y-1">
                {managerUsers.map(u => (
                  <button
                    key={u.userId}
                    onClick={() => {
                      switchUser(u.userId);
                      setIsOpen(false);
                    }}
                    className={`w-full flex items-center justify-between p-2 rounded-lg text-left transition cursor-pointer ${
                      currentUser?.userId === u.userId
                        ? 'bg-amber-50 text-amber-900 font-semibold ring-1 ring-amber-300'
                        : 'hover:bg-slate-50 text-slate-700'
                    }`}
                  >
                    <div>
                      <div className="font-medium text-xs">{u.fullName}</div>
                      <div className="text-[10px] text-slate-400">{u.job} • {u.department}</div>
                    </div>
                    {currentUser?.userId === u.userId && <Check className="h-4 w-4 text-amber-600" />}
                  </button>
                ))}
              </div>
            </div>

            {/* 4. Nhân Viên Chuyên Viên */}
            <div>
              <div className="font-bold text-emerald-700 uppercase tracking-wider text-[10px] mb-1.5">
                🧑‍💻 Chuyên Viên / Nhân Viên (Staff)
              </div>
              <div className="space-y-1">
                {staffUsers.map(u => (
                  <button
                    key={u.userId}
                    onClick={() => {
                      switchUser(u.userId);
                      setIsOpen(false);
                    }}
                    className={`w-full flex items-center justify-between p-2 rounded-lg text-left transition cursor-pointer ${
                      currentUser?.userId === u.userId
                        ? 'bg-emerald-50 text-emerald-900 font-semibold ring-1 ring-emerald-300'
                        : 'hover:bg-slate-50 text-slate-700'
                    }`}
                  >
                    <div>
                      <div className="font-medium text-xs">{u.fullName}</div>
                      <div className="text-[10px] text-slate-400">{u.job} ({u.employeeCode})</div>
                    </div>
                    {currentUser?.userId === u.userId && <Check className="h-4 w-4 text-emerald-600" />}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Floating Toggle Pill */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 rounded-full bg-slate-900 hover:bg-slate-800 text-white px-4 py-2.5 shadow-xl ring-2 ring-white/20 transition-all duration-200 cursor-pointer text-xs font-semibold"
      >
        <Sparkles className="h-4 w-4 text-amber-400" />
        <span className="hidden sm:inline">Đổi vai trò:</span>
        <span className="max-w-[140px] truncate text-amber-200 font-bold">
          {currentUser ? currentUser.fullName : 'Chọn vai trò'}
        </span>
        {isOpen ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronUp className="h-3.5 w-3.5" />}
      </button>
    </div>
  );
}
