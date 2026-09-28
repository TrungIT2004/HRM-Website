'use client';

import React from 'react';
import Link from 'next/link';
import { 
  Camera, 
  ShieldCheck, 
  Clock, 
  CalendarDays, 
  CreditCard, 
  Users, 
  ArrowRight, 
  CheckCircle2, 
  Sparkles, 
  ChevronRight,
  TrendingUp,
  Cpu,
  Layers,
  Lock,
  Building2,
  Play
} from 'lucide-react';
import { useAuth } from '@/context/AuthContext';

export default function LandingPage() {
  const { currentUser } = useAuth();
  const [isRedirecting, setIsRedirecting] = React.useState(true);

  React.useEffect(() => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
    if (!token) {
      window.location.replace('/login');
    } else {
      window.location.replace('/dashboard');
    }
  }, []);

  if (isRedirecting) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4 font-sans">
        <div className="flex flex-col items-center gap-3 text-center">
          <div className="h-8 w-8 animate-spin rounded-full border-3 border-blue-600 border-t-transparent" />
          <p className="text-xs text-slate-500 font-medium">Đang chuyển hướng...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 selection:bg-blue-600 selection:text-white">
      {/* Header / Navbar */}
      <header className="sticky top-0 z-40 glass-nav border-b border-slate-200">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-600 font-extrabold text-white shadow-lg shadow-blue-500/25">
              ACT
            </div>
            <div>
              <span className="text-lg font-black tracking-tight text-slate-900">ACT HRM</span>
              <span className="ml-2 rounded-full bg-blue-100 px-2 py-0.5 text-[10px] font-bold text-blue-700 uppercase">
                Enterprise SaaS
              </span>
            </div>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-600">
            <a href="#features" className="hover:text-blue-600 transition">Tính năng</a>
            <a href="#modules" className="hover:text-blue-600 transition">Các phân hệ</a>
            <a href="#pricing" className="hover:text-blue-600 transition">Bảng giá</a>
          </nav>

          <div className="flex items-center gap-3">
            <Link
              href="/login"
              className="text-sm font-semibold text-slate-700 hover:text-blue-600 px-3 py-2 transition"
            >
              Đăng nhập
            </Link>
            <Link
              href="/dashboard"
              className="inline-flex items-center gap-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white px-4 py-2 text-sm font-bold shadow-md shadow-orange-500/20 transition cursor-pointer"
            >
              <span>Vào Bảng Điều Khiển</span>
              <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative overflow-hidden pt-12 pb-20 lg:pt-20 lg:pb-28">
        <div className="absolute inset-0 -z-10 bg-[radial-gradient(45rem_50rem_at_top,theme(colors.blue.100),transparent)]" />
        
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 text-center">
          <div className="inline-flex items-center gap-2 rounded-full bg-blue-50 px-3.5 py-1.5 text-xs font-semibold text-blue-700 border border-blue-200 mb-6 shadow-xs">
            <Sparkles className="h-3.5 w-3.5 text-blue-600" />
            <span>Thế hệ phần mềm quản trị nhân sự 4.0 chuẩn Enterprise</span>
          </div>

          <h1 className="mx-auto max-w-4xl text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-slate-900 leading-[1.15]">
            Nền Tảng Quản Trị Nhân Sự & <br className="hidden sm:inline" />
            <span className="bg-gradient-to-r from-blue-600 via-indigo-600 to-orange-600 bg-clip-text text-transparent">
              Chấm Công Doanh Nghiệp Tự Động
            </span>
          </h1>

          <p className="mx-auto mt-6 max-w-2xl text-base sm:text-lg text-slate-600 leading-relaxed">
            Hệ sinh thái ACT HRM số hóa toàn diện: Đồng bộ dữ liệu chấm công thời gian thực, tự động duyệt phép, quản lý ca kíp, tính làm thêm giờ OT và kết xuất bảng lương tự động cho doanh nghiệp.
          </p>

          {/* CTA Buttons */}
          <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/dashboard"
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white px-7 py-3.5 text-base font-bold shadow-lg shadow-orange-500/25 transition cursor-pointer"
            >
              <span>Trải nghiệm trực tiếp</span>
              <ArrowRight className="h-4 w-4" />
            </Link>
            <Link
              href="/login"
              className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl bg-white hover:bg-slate-50 text-slate-800 px-6 py-3.5 text-base font-semibold border border-slate-300 shadow-xs transition"
            >
              <Users className="h-4 w-4 text-blue-600" />
              <span>Đăng nhập 15 nhân sự mẫu</span>
            </Link>
          </div>

          {/* Social Proof / Stats */}
          <div className="mt-14 grid grid-cols-2 gap-4 md:grid-cols-4 max-w-4xl mx-auto">
            <div className="rounded-2xl bg-white p-4 shadow-sm border border-slate-200/80 text-center">
              <div className="text-2xl sm:text-3xl font-black text-blue-600">100%</div>
              <div className="mt-1 text-xs font-medium text-slate-500">Đồng bộ tự động thời gian thực</div>
            </div>
            <div className="rounded-2xl bg-white p-4 shadow-sm border border-slate-200/80 text-center">
              <div className="text-2xl sm:text-3xl font-black text-indigo-600">24/7</div>
              <div className="mt-1 text-xs font-medium text-slate-500">Hệ thống sẵn sàng vận hành</div>
            </div>
            <div className="rounded-2xl bg-white p-4 shadow-sm border border-slate-200/80 text-center">
              <div className="text-2xl sm:text-3xl font-black text-emerald-600">100%</div>
              <div className="mt-1 text-xs font-medium text-slate-500">Tự động tính lương & OT</div>
            </div>
            <div className="rounded-2xl bg-white p-4 shadow-sm border border-slate-200/80 text-center">
              <div className="text-2xl sm:text-3xl font-black text-orange-600">15+</div>
              <div className="mt-1 text-xs font-medium text-slate-500">Nhân sự thực tế đã kết nối</div>
            </div>
          </div>
        </div>
      </section>

      {/* Feature Showcase Grid */}
      <section id="features" className="py-20 bg-white border-y border-slate-200">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-xs font-bold uppercase tracking-wider text-blue-600">Giải pháp toàn diện</h2>
            <p className="mt-2 text-3xl font-black tracking-tight text-slate-900 sm:text-4xl">
              Được thiết kế chuẩn mực cho Doanh nghiệp hiện đại
            </p>
            <p className="mt-4 text-sm sm:text-base text-slate-600">
              Tất cả các nghiệp vụ quản lý nhân sự cốt lõi được đồng bộ hoá thời gian thực.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Feature 1 */}
            <div className="relative rounded-2xl bg-slate-50 p-6 border border-slate-200/80 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-600 text-white shadow-md shadow-blue-500/20 group-hover:scale-105 transition">
                <Clock className="h-6 w-6" />
              </div>
              <h3 className="mt-4 text-lg font-bold text-slate-900">Chấm công & Giờ làm Tự động</h3>
              <p className="mt-2 text-xs text-slate-600 leading-relaxed">
                Tích hợp trực tiếp với thiết bị chấm công phần cứng qua API Spring Boot, đồng bộ thời gian thực giờ vào/ra, tự động cảnh báo đi muộn về sớm.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="relative rounded-2xl bg-slate-50 p-6 border border-slate-200/80 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-md shadow-indigo-500/20 group-hover:scale-105 transition">
                <CalendarDays className="h-6 w-6" />
              </div>
              <h3 className="mt-4 text-lg font-bold text-slate-900">Quản lý Nghỉ phép Thông minh</h3>
              <p className="mt-2 text-xs text-slate-600 leading-relaxed">
                Thuật toán Live Preview tự động loại trừ thứ Bảy, Chủ Nhật và toàn bộ ngày Lễ Quốc gia, tự động kiểm tra quỹ phép năm còn lại trước khi nộp đơn.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="relative rounded-2xl bg-slate-50 p-6 border border-slate-200/80 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-orange-600 text-white shadow-md shadow-orange-500/20 group-hover:scale-105 transition">
                <Clock className="h-6 w-6" />
              </div>
              <h3 className="mt-4 text-lg font-bold text-slate-900">Làm thêm giờ (OT) & Ca đêm</h3>
              <p className="mt-2 text-xs text-slate-600 leading-relaxed">
                Hệ số lương đa tầng: 1.5x ngày thường, 2.0x ngày nghỉ cuối tuần, 3.0x ngày lễ và phụ cấp ca đêm. Quy trình phê duyệt 2 cấp bảo đảm tuân thủ luật lao động.
              </p>
            </div>

            {/* Feature 4 */}
            <div className="relative rounded-2xl bg-slate-50 p-6 border border-slate-200/80 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-600 text-white shadow-md shadow-emerald-500/20 group-hover:scale-105 transition">
                <CreditCard className="h-6 w-6" />
              </div>
              <h3 className="mt-4 text-lg font-bold text-slate-900">Bảng tính lương Tự động</h3>
              <p className="mt-2 text-xs text-slate-600 leading-relaxed">
                Tự động tính lương NET từ dữ liệu giờ làm việc thực tế, cộng tiền làm thêm giờ OT, cộng phụ cấp và tự động trừ bảo hiểm xã hội, đi muộn.
              </p>
            </div>

            {/* Feature 5 */}
            <div className="relative rounded-2xl bg-slate-50 p-6 border border-slate-200/80 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-purple-600 text-white shadow-md shadow-purple-500/20 group-hover:scale-105 transition">
                <Users className="h-6 w-6" />
              </div>
              <h3 className="mt-4 text-lg font-bold text-slate-900">Hồ sơ Nhân sự 5 Phân Lớp</h3>
              <p className="mt-2 text-xs text-slate-600 leading-relaxed">
                Quản lý chi tiết: Thông tin cơ bản, Hồ sơ pháp lý CCCD / Thuế / BHXH, Hợp đồng lao động tái ký, Lương & Ngân hàng, Phân công ca làm việc.
              </p>
            </div>

            {/* Feature 6 */}
            <div className="relative rounded-2xl bg-slate-50 p-6 border border-slate-200/80 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-pink-600 text-white shadow-md shadow-pink-500/20 group-hover:scale-105 transition">
                <ShieldCheck className="h-6 w-6" />
              </div>
              <h3 className="mt-4 text-lg font-bold text-slate-900">Phân quyền 4 Cấp bậc (RBAC)</h3>
              <p className="mt-2 text-xs text-slate-600 leading-relaxed">
                Phân quyền chuyên sâu: Ban Giám Đốc (Executive), Quản trị Nhân sự (HR), Trưởng phòng (Manager), Nhân viên (Staff) bảo mật dữ liệu tuyệt đối.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 bg-slate-50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-xs font-bold uppercase tracking-wider text-blue-600">Bảng giá linh hoạt</h2>
            <p className="mt-2 text-3xl font-black tracking-tight text-slate-900 sm:text-4xl">
              Phù hợp cho mọi quy mô doanh nghiệp
            </p>
            <p className="mt-4 text-sm text-slate-600">
              Tiết kiệm 80% chi phí quản trị nhân sự và xóa bỏ hoàn toàn máy chấm công vân tay lỗi thời.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 max-w-6xl mx-auto items-stretch">
            {/* Plan 1 */}
            <div className="rounded-3xl bg-white p-8 border border-slate-200 shadow-sm flex flex-col justify-between">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Gói Khởi Nghiệp</h3>
                <p className="text-xs text-slate-500 mt-1">Dành cho công ty dưới 30 nhân sự</p>
                <div className="mt-6 flex items-baseline gap-1">
                  <span className="text-3xl sm:text-4xl font-black text-slate-900">499.000₫</span>
                  <span className="text-xs text-slate-500">/tháng</span>
                </div>
                <ul className="mt-6 space-y-3 text-xs text-slate-600">
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Đồng bộ chấm công tự động từ thiết bị</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Quản lý đơn nghỉ phép & phê duyệt</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Hồ sơ nhân viên cơ bản</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Xuất file báo cáo công Excel</li>
                </ul>
              </div>
              <Link
                href="/login"
                className="mt-8 block w-full rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-center py-3 text-xs font-bold transition"
              >
                Dùng thử miễn phí
              </Link>
            </div>

            {/* Plan 2 - Featured */}
            <div className="relative rounded-3xl bg-white p-8 border-2 border-blue-600 shadow-xl flex flex-col justify-between">
              <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 rounded-full bg-blue-600 px-3 py-0.5 text-[11px] font-bold text-white uppercase tracking-wide">
                Phổ biến nhất
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-900">Gói Doanh Nghiệp</h3>
                <p className="text-xs text-slate-500 mt-1">Dành cho quy mô từ 30 - 200 nhân sự</p>
                <div className="mt-6 flex items-baseline gap-1">
                  <span className="text-3xl sm:text-4xl font-black text-blue-600">1.490.000₫</span>
                  <span className="text-xs text-slate-500">/tháng</span>
                </div>
                <ul className="mt-6 space-y-3 text-xs text-slate-600">
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> <strong>Mọi tính năng Gói Khởi Nghiệp</strong></li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Kết nối không giới hạn thiết bị điểm danh</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Phân hệ Làm thêm giờ (OT) đa hệ số</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Tính lương tự động NET & Bảo hiểm</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Quản lý hợp đồng & điều chuyển công tác</li>
                </ul>
              </div>
              <Link
                href="/dashboard"
                className="mt-8 block w-full rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-center py-3 text-xs font-bold shadow-lg shadow-blue-500/25 transition cursor-pointer"
              >
                Trải nghiệm ngay
              </Link>
            </div>

            {/* Plan 3 */}
            <div className="rounded-3xl bg-white p-8 border border-slate-200 shadow-sm flex flex-col justify-between">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Gói Tập Đoàn</h3>
                <p className="text-xs text-slate-500 mt-1">Dành cho doanh nghiệp 200+ nhân sự</p>
                <div className="mt-6 flex items-baseline gap-1">
                  <span className="text-3xl sm:text-4xl font-black text-slate-900">Liên hệ</span>
                </div>
                <ul className="mt-6 space-y-3 text-xs text-slate-600">
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Triển khai On-Premise hoặc Dedicated Cloud</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Tùy biến công thức tính lương theo yêu cầu</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Tích hợp ERP (SAP, Oracle) & API tùy biến</li>
                  <li className="flex items-center gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-500 shrink-0" /> Hỗ trợ kỹ thuật 24/7 với SLA 99.9%</li>
                </ul>
              </div>
              <Link
                href="/login"
                className="mt-8 block w-full rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-center py-3 text-xs font-bold transition"
              >
                Tư vấn chuyên sâu
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-900 text-slate-400 py-12 border-t border-slate-800">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-600 font-bold text-white">
              ACT
            </div>
            <div>
              <span className="text-base font-bold text-white">Công ty Cổ phần ACT</span>
              <p className="text-xs text-slate-400">Hệ thống Quản trị Nhân sự & Chấm công Thông minh</p>
            </div>
          </div>

          <div className="flex items-center gap-6 text-xs">
            <Link href="/dashboard" className="hover:text-white transition">Bảng Điều Khiển</Link>
            <Link href="/employees" className="hover:text-white transition">Danh bạ Nhân sự</Link>
            <Link href="/attendance" className="hover:text-white transition">Chấm công & Giờ làm</Link>
            <Link href="/login" className="hover:text-white transition">Đăng nhập</Link>
          </div>

          <div className="text-xs text-slate-500">
            © 2026 ACT Corporation. Bản quyền thuộc về ACT HRM.
          </div>
        </div>
      </footer>
    </div>
  );
}
