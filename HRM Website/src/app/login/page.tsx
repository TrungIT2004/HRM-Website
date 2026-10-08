'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { 
  Lock, 
  Mail, 
  ArrowRight, 
  ShieldCheck, 
  Sparkles, 
  AlertCircle, 
  Eye, 
  EyeOff, 
  Building2, 
  ScanFace, 
  Bot, 
  CheckCircle2 
} from 'lucide-react';

const QUICK_ACCOUNTS = [
  {
    name: 'Super Admin',
    email: 'superadmin@company.com',
    role: 'Quản trị viên Tối cao (IT)',
    dept: 'IT',
    badge: '⚡ SUPER ADMIN',
    badgeColor: 'bg-purple-50 text-purple-700 border-purple-200'
  },
  {
    name: 'Nguyễn Minh Đức',
    email: 'nguyenminhduc@company.com',
    role: 'Chủ tịch (Ban Giám Đốc)',
    dept: 'Executive Leadership',
    badge: '🔴 EXECUTIVE',
    badgeColor: 'bg-red-50 text-red-700 border-red-200'
  },
  {
    name: 'Phạm Thị Cúc',
    email: 'phamthicuc@company.com',
    role: 'Trưởng phòng Nhân sự',
    dept: 'Human Resources',
    badge: '🟠 HR HEAD',
    badgeColor: 'bg-amber-50 text-amber-700 border-amber-200'
  },
  {
    name: 'Nguyễn Văn Admin',
    email: 'sysadmin@company.com',
    role: 'Quản trị viên Hệ thống (IT)',
    dept: 'Information Technology',
    badge: '🛡️ ADMIN',
    badgeColor: 'bg-indigo-50 text-indigo-700 border-indigo-200'
  },
  {
    name: 'Đỗ Văn Hùng',
    email: 'dovanhung@company.com',
    role: 'Trưởng phòng IT',
    dept: 'Information Technology',
    badge: '🔵 MANAGER',
    badgeColor: 'bg-blue-50 text-blue-700 border-blue-200'
  },
  {
    name: 'Nguyễn Hoàng',
    email: 'it.employee@company.com',
    role: 'Kỹ sư phần mềm',
    dept: 'Information Technology',
    badge: '🟢 STAFF',
    badgeColor: 'bg-emerald-50 text-emerald-700 border-emerald-200'
  },
  {
    name: 'Lê Văn C',
    email: 'hr.employee@company.com',
    role: 'Chuyên viên Nhân sự',
    dept: 'Human Resources',
    badge: '🟢 HR STAFF',
    badgeColor: 'bg-emerald-50 text-emerald-700 border-emerald-200'
  },
  {
    name: 'Phạm Thị D',
    email: 'finance.employee@company.com',
    role: 'Kế toán viên',
    dept: 'Finance & Accounting',
    badge: '🟢 ACCOUNTANT',
    badgeColor: 'bg-emerald-50 text-emerald-700 border-emerald-200'
  },
  {
    name: 'Nguyễn Văn Dũng',
    email: 'nguyenvandung@company.com',
    role: 'Trưởng phòng Kế toán',
    dept: 'Finance & Accounting',
    badge: '🔵 FINANCE HEAD',
    badgeColor: 'bg-blue-50 text-blue-700 border-blue-200'
  }
];

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth();

  useEffect(() => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
    if (token) {
      router.replace('/home');
    }
  }, [router]);

  const [email, setEmail] = useState('superadmin@company.com');
  const [password, setPassword] = useState('test@123');
  const [showPassword, setShowPassword] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setErrorMsg('');

    try {
      const res = await login(email, password);
      if (res.success) {
        router.push('/home');
      } else {
        setErrorMsg(res.error || 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Đã có lỗi xảy ra trong quá trình đăng nhập.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSelectQuickAccount = (userEmail: string) => {
    setEmail(userEmail);
    setPassword('test@123');
    setErrorMsg('');
  };

  return (
    <div className="min-h-screen flex items-stretch bg-slate-50 font-sans selection:bg-blue-100 selection:text-blue-900">
      {/* Left Column: Brand & Value Proposition (Desktop) */}
      <div className="hidden lg:flex lg:w-5/12 bg-linear-to-br from-slate-900 via-blue-950 to-slate-900 p-12 flex-col justify-between relative overflow-hidden text-white border-r border-slate-800">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,_var(--tw-gradient-stops))] from-blue-500/10 via-transparent to-transparent pointer-events-none" />
        
        {/* Brand Header */}
        <div className="relative z-10">
          <Link href="/" className="inline-flex items-center gap-3 group">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-blue-600 font-extrabold text-lg text-white shadow-lg shadow-blue-500/30 group-hover:scale-105 transition-transform duration-200">
              ACT
            </div>
            <div>
              <span className="text-xl font-extrabold tracking-tight text-white block">ACT HRM</span>
              <span className="text-[11px] text-slate-400 font-medium tracking-wide uppercase">Enterprise Platform</span>
            </div>
          </Link>
        </div>

        {/* Hero Copy */}
        <div className="relative z-10 space-y-6 my-auto py-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-400/20 text-blue-300 text-xs font-semibold">
            <Sparkles className="h-3.5 w-3.5 text-blue-400" />
            <span>Thế hệ quản trị nhân sự số 4.0</span>
          </div>

          <h1 className="text-3xl font-extrabold tracking-tight text-white leading-tight">
            Quản trị nhân lực, chấm công sinh trắc học và trợ lý AI thông minh
          </h1>

          <p className="text-sm text-slate-300 leading-relaxed font-normal">
            Hệ thống tích hợp toàn diện từ chấm công nhận diện khuôn mặt Edge AI, quản lý hợp đồng, tự động hóa tính lương đến tra cứu quy chế nội bộ qua trợ lý ảo RAG.
          </p>

          <div className="pt-4 space-y-3">
            <div className="flex items-center gap-3 text-xs text-slate-200 font-medium">
              <div className="h-6 w-6 rounded-lg bg-blue-600/30 border border-blue-500/30 flex items-center justify-center text-blue-400">
                <ScanFace className="h-3.5 w-3.5" />
              </div>
              <span>Chấm công khuôn mặt AI với OpenCV & YuNet</span>
            </div>

            <div className="flex items-center gap-3 text-xs text-slate-200 font-medium">
              <div className="h-6 w-6 rounded-lg bg-blue-600/30 border border-blue-500/30 flex items-center justify-center text-blue-400">
                <Bot className="h-3.5 w-3.5" />
              </div>
              <span>Trợ lý RAG AI giải đáp chính sách theo phòng ban & chức danh</span>
            </div>

            <div className="flex items-center gap-3 text-xs text-slate-200 font-medium">
              <div className="h-6 w-6 rounded-lg bg-blue-600/30 border border-blue-500/30 flex items-center justify-center text-blue-400">
                <ShieldCheck className="h-3.5 w-3.5" />
              </div>
              <span>Bảo mật phân quyền đa cấp RBAC theo tiêu chuẩn Doanh nghiệp</span>
            </div>
          </div>
        </div>

        {/* Footer info */}
        <div className="relative z-10 text-xs text-slate-500 flex items-center justify-between border-t border-slate-800/80 pt-6">
          <span>© 2026 ACT Corporation</span>
          <span className="font-mono text-[11px] text-slate-400">v2.4-enterprise</span>
        </div>
      </div>

      {/* Right Column: Authentication Form */}
      <div className="flex-1 flex flex-col justify-center px-4 sm:px-8 md:px-12 lg:px-16 py-12 max-w-2xl mx-auto w-full">
        {/* Mobile Header */}
        <div className="lg:hidden text-center mb-8">
          <Link href="/" className="inline-flex items-center gap-2.5">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-blue-600 font-extrabold text-white text-lg shadow-md shadow-blue-500/25">
              ACT
            </div>
            <span className="text-2xl font-black tracking-tight text-slate-900">ACT HRM</span>
          </Link>
        </div>

        <div className="bg-white rounded-3xl p-8 sm:p-10 shadow-xl shadow-slate-200/50 border border-slate-200/90 relative">
          <div className="mb-6">
            <h2 className="text-2xl font-bold tracking-tight text-slate-900">
              Đăng nhập hệ thống
            </h2>
            <p className="mt-1 text-xs text-slate-500">
              Vui lòng nhập tài khoản công ty để truy cập bảng điều khiển và dịch vụ nhân sự.
            </p>
          </div>

          {errorMsg && (
            <div className="mb-6 flex items-start gap-2.5 rounded-xl bg-red-50 p-3.5 text-xs font-medium text-red-800 border border-red-200 animate-in fade-in duration-200">
              <AlertCircle className="h-4 w-4 shrink-0 text-red-600 mt-0.5" />
              <div className="flex-1">
                <span className="font-bold block">Đăng nhập không thành công</span>
                <span className="text-red-700">{errorMsg}</span>
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Email doanh nghiệp
              </label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5">
                  <Mail className="h-4 w-4 text-slate-400" />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  required
                  placeholder="ten.nhanvien@company.com"
                  className="block w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 pl-10 pr-3.5 text-xs text-slate-900 placeholder:text-slate-400 transition focus:bg-white focus:border-blue-600 focus:outline-hidden focus:ring-2 focus:ring-blue-600/20"
                />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="block text-xs font-semibold text-slate-700">
                  Mật khẩu
                </label>
                <span className="text-[11px] text-slate-400 font-mono">
                  Mặc định: <strong className="text-slate-600">test@123</strong>
                </span>
              </div>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5">
                  <Lock className="h-4 w-4 text-slate-400" />
                </div>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                  placeholder="••••••••"
                  className="block w-full rounded-xl border border-slate-200 bg-slate-50/50 py-2.5 pl-10 pr-10 text-xs text-slate-900 placeholder:text-slate-400 transition focus:bg-white focus:border-blue-600 focus:outline-hidden focus:ring-2 focus:ring-blue-600/20"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 flex items-center pr-3.5 text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full flex items-center justify-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 active:scale-[0.99] text-white py-3 text-xs font-bold shadow-lg shadow-blue-500/20 transition-all cursor-pointer disabled:opacity-50 mt-2"
            >
              <span>{isLoading ? 'Đang xác thực thông tin...' : 'Đăng nhập vào hệ thống'}</span>
              <ArrowRight className="h-4 w-4" />
            </button>
          </form>

          {/* Quick Account Selector for Testing Roles */}
          <div className="mt-8 pt-6 border-t border-slate-100">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-1.5 text-xs font-bold text-slate-700">
                <Sparkles className="h-3.5 w-3.5 text-amber-500" />
                <span>Tài khoản kiểm thử nhanh theo phân quyền:</span>
              </div>
              <span className="text-[10px] text-slate-400">Click để chọn</span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
              {QUICK_ACCOUNTS.map(acc => {
                const isSelected = email === acc.email;
                return (
                  <button
                    key={acc.email}
                    type="button"
                    onClick={() => handleSelectQuickAccount(acc.email)}
                    className={`flex flex-col items-start p-2.5 rounded-xl border text-left transition cursor-pointer ${
                      isSelected
                        ? 'border-blue-500 bg-blue-50/60 ring-2 ring-blue-500/20 shadow-xs'
                        : 'border-slate-200 hover:border-slate-300 bg-slate-50/40 hover:bg-slate-50'
                    }`}
                  >
                    <div className="flex items-center justify-between w-full mb-1">
                      <span className="font-bold text-slate-900 truncate">{acc.name}</span>
                      <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded-md border ${acc.badgeColor}`}>
                        {acc.badge}
                      </span>
                    </div>
                    <span className="text-[11px] text-slate-600 block truncate">{acc.role}</span>
                    <span className="text-[10px] text-slate-400 font-mono block mt-0.5">{acc.email}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        <div className="mt-6 text-center text-xs text-slate-500">
          <Link href="/" className="font-semibold text-blue-600 hover:text-blue-700 inline-flex items-center gap-1">
            <span>← Quay lại Cổng thông tin giới thiệu ACT HRM</span>
          </Link>
        </div>
      </div>
    </div>
  );
}
