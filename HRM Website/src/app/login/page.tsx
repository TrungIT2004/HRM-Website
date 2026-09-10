'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { Lock, Mail, ArrowRight, CheckCircle2, ShieldCheck, Sparkles, AlertCircle } from 'lucide-react';
import { MOCK_USERS } from '@/mock/users';

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth();

  const [email, setEmail] = useState('phamthicuc@company.com');
  const [password, setPassword] = useState('test@123');
  const [errorMsg, setErrorMsg] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setErrorMsg('');

    try {
      const res = await login(email, password);
      if (res.success) {
        router.push('/dashboard');
      } else {
        setErrorMsg(res.error || 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Đã có lỗi xảy ra trong quá trình đăng nhập.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuickLogin = async (userEmail: string) => {
    setEmail(userEmail);
    setPassword('test@123');
    setIsLoading(true);
    setErrorMsg('');
    try {
      const res = await login(userEmail, 'test@123');
      if (res.success) {
        router.push('/dashboard');
      } else {
        setErrorMsg(res.error || 'Đăng nhập nhanh không thành công');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Đã có lỗi xảy ra');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col justify-center bg-slate-50 py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md text-center">
        <Link href="/" className="inline-flex items-center gap-2.5">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-blue-600 font-black text-xl text-white shadow-lg shadow-blue-500/25">
            ACT
          </div>
          <span className="text-2xl font-black tracking-tight text-slate-900">ACT HRM</span>
        </Link>
        <h2 className="mt-4 text-2xl font-bold tracking-tight text-slate-900">
          Đăng nhập vào Hệ thống
        </h2>
        <p className="mt-1.5 text-xs text-slate-500">
          Cổng thông tin nhân sự và chấm công thông minh Công ty Cổ phần ACT
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md px-4">
        <div className="rounded-3xl bg-white p-8 shadow-xl border border-slate-200/80">
          {errorMsg && (
            <div className="mb-5 flex items-center gap-2 rounded-xl bg-red-50 p-3 text-xs font-semibold text-red-700 border border-red-200">
              <AlertCircle className="h-4 w-4 shrink-0 text-red-600" />
              <span>{errorMsg}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Email doanh nghiệp
              </label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                  <Mail className="h-4 w-4 text-slate-400" />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  required
                  placeholder="name@company.com"
                  className="block w-full rounded-xl border border-slate-300 py-2.5 pl-10 pr-3 text-xs text-slate-900 placeholder:text-slate-400 focus:border-blue-600 focus:outline-hidden focus:ring-1 focus:ring-blue-600"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Mật khẩu
              </label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                  <Lock className="h-4 w-4 text-slate-400" />
                </div>
                <input
                  type="password"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                  placeholder="••••••••"
                  className="block w-full rounded-xl border border-slate-300 py-2.5 pl-10 pr-3 text-xs text-slate-900 placeholder:text-slate-400 focus:border-blue-600 focus:outline-hidden focus:ring-1 focus:ring-blue-600"
                />
              </div>
              <p className="mt-1 text-[11px] text-slate-400">Mật khẩu mặc định trong DB: <code className="font-mono text-slate-600 font-semibold">test@123</code></p>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full flex items-center justify-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white py-3 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer disabled:opacity-50"
            >
              <span>{isLoading ? 'Đang xác thực...' : 'Đăng nhập'}</span>
              <ArrowRight className="h-4 w-4" />
            </button>
          </form>

          {/* One-Click Quick Logins */}
          <div className="mt-6 pt-6 border-t border-slate-100">
            <div className="flex items-center gap-1 text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-2.5">
              <Sparkles className="h-3.5 w-3.5 text-amber-500" />
              <span>Chọn nhanh tài khoản thử nghiệm (1-Click Login):</span>
            </div>

            <div className="space-y-1.5 text-xs">
              <button
                onClick={() => handleQuickLogin('nguyenminhduc@company.com')}
                className="w-full flex items-center justify-between p-2 rounded-lg bg-purple-50 hover:bg-purple-100/80 border border-purple-200 text-left transition cursor-pointer"
              >
                <div>
                  <span className="font-bold text-purple-900">Nguyễn Minh Đức</span>
                  <span className="text-[11px] text-purple-600 block">Chủ tịch (Ban Giám Đốc)</span>
                </div>
                <span className="text-[10px] font-mono bg-purple-200/70 text-purple-800 px-1.5 py-0.5 rounded">EXEC001</span>
              </button>

              <button
                onClick={() => handleQuickLogin('phamthicuc@company.com')}
                className="w-full flex items-center justify-between p-2 rounded-lg bg-blue-50 hover:bg-blue-100/80 border border-blue-200 text-left transition cursor-pointer"
              >
                <div>
                  <span className="font-bold text-blue-900">Phạm Thị Cúc</span>
                  <span className="text-[11px] text-blue-600 block">Trưởng phòng Nhân sự (HR Head)</span>
                </div>
                <span className="text-[10px] font-mono bg-blue-200/70 text-blue-800 px-1.5 py-0.5 rounded">HR001</span>
              </button>

              <button
                onClick={() => handleQuickLogin('dovanhung@company.com')}
                className="w-full flex items-center justify-between p-2 rounded-lg bg-amber-50 hover:bg-amber-100/80 border border-amber-200 text-left transition cursor-pointer"
              >
                <div>
                  <span className="font-bold text-amber-900">Đỗ Văn Hùng</span>
                  <span className="text-[11px] text-amber-600 block">Trưởng phòng IT (Manager)</span>
                </div>
                <span className="text-[10px] font-mono bg-amber-200/70 text-amber-800 px-1.5 py-0.5 rounded">IT001</span>
              </button>

              <button
                onClick={() => handleQuickLogin('it.employee@company.com')}
                className="w-full flex items-center justify-between p-2 rounded-lg bg-emerald-50 hover:bg-emerald-100/80 border border-emerald-200 text-left transition cursor-pointer"
              >
                <div>
                  <span className="font-bold text-emerald-900">Nguyễn Hoàng</span>
                  <span className="text-[11px] text-emerald-600 block">Kỹ sư phần mềm (Staff)</span>
                </div>
                <span className="text-[10px] font-mono bg-emerald-200/70 text-emerald-800 px-1.5 py-0.5 rounded">IT002</span>
              </button>
            </div>
          </div>
        </div>

        <div className="mt-6 text-center text-xs text-slate-500">
          <Link href="/" className="font-semibold text-blue-600 hover:text-blue-700">
            ← Quay lại Trang Chủ ACT HRM
          </Link>
        </div>
      </div>
    </div>
  );
}
