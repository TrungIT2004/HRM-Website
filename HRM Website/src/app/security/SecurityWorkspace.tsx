'use client';

import { useCallback, useEffect, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { authService } from '@/services/authService';
import { adminService, AdminSessionItem } from '@/services/adminService';
import ConfirmDialog from '@/components/ConfirmDialog';
import { formatDateVN } from '@/utils/format';
import {
  AlertCircle,
  CheckCircle2,
  KeyRound,
  LogOut,
  Monitor,
  RefreshCw,
  Settings as SettingsIcon
} from 'lucide-react';

// Cài đặt bảo mật của chính mình — section cố định theo route (/password, /sessions).
export default function SecurityWorkspace({ section }: { section: 'password' | 'sessions' }) {
  const { currentUser } = useAuth();
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [saving, setSaving] = useState(false);
  const [loadingSessions, setLoadingSessions] = useState(false);
  const [sessions, setSessions] = useState<AdminSessionItem[]>([]);
  const [toast, setToast] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Popup xác nhận thay confirm() native
  const [revokeTarget, setRevokeTarget] = useState<string | null>(null);
  const [revokeAllOpen, setRevokeAllOpen] = useState(false);
  const [revoking, setRevoking] = useState(false);

  const showToast = (text: string, type: 'success' | 'error') => {
    setToast({ text, type });
    setTimeout(() => setToast(null), 4000);
  };

  const loadSessions = useCallback(async () => {
    if (!currentUser) return;
    setLoadingSessions(true);
    try {
      setSessions(await adminService.getUserSessions(currentUser.userId));
    } catch (err: any) {
      showToast(err?.response?.data?.msg || 'Không tải được danh sách phiên', 'error');
    } finally {
      setLoadingSessions(false);
    }
  }, [currentUser]);

  useEffect(() => {
    if (section === 'sessions') loadSessions();
  }, [loadSessions, section]);

  if (!currentUser) return null;

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      showToast('Mật khẩu mới và xác nhận không khớp.', 'error');
      return;
    }
    if (newPassword.length < 6) {
      showToast('Mật khẩu mới phải có ít nhất 6 ký tự.', 'error');
      return;
    }
    setSaving(true);
    try {
      await authService.changePassword(oldPassword, newPassword, confirmPassword);
      showToast('Đổi mật khẩu thành công.', 'success');
      setOldPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (err: any) {
      showToast(err?.response?.data?.msg || err?.message || 'Đổi mật khẩu thất bại', 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleRevokeConfirm = async () => {
    if (!revokeTarget) return;
    setRevoking(true);
    try {
      await adminService.revokeSession(revokeTarget);
      showToast('Đã thu hồi phiên đăng nhập.', 'success');
      setRevokeTarget(null);
      await loadSessions();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || 'Thu hồi phiên thất bại', 'error');
    } finally {
      setRevoking(false);
    }
  };

  const handleRevokeAllConfirm = async () => {
    if (!currentUser) return;
    setRevoking(true);
    try {
      await adminService.revokeAllUserSessions(currentUser.userId);
      showToast('Đã đăng xuất khỏi tất cả thiết bị.', 'success');
      setRevokeAllOpen(false);
      await loadSessions();
    } catch (err: any) {
      showToast(err?.response?.data?.msg || 'Đăng xuất thất bại', 'error');
    } finally {
      setRevoking(false);
    }
  };

  const active = sessions.filter(s => !s.revoked);

  return (
    <AppShell>
      <div className="space-y-6">
        {toast && (
          <div
            role="status"
            className="fixed top-20 right-6 z-50 rounded-2xl bg-slate-900 text-white px-5 py-3 shadow-xl flex items-center gap-2.5 text-xs font-bold"
          >
            {toast.type === "success" ? (
              <CheckCircle2
                className="w-5 h-5 text-emerald-400 shrink-0"
                aria-hidden="true"
              />
            ) : (
              <AlertCircle
                className="w-5 h-5 text-rose-400 shrink-0"
                aria-hidden="true"
              />
            )}
            <span>{toast.text}</span>
          </div>
        )}

        <div>
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-slate-600 text-white flex items-center justify-center shadow-md">
              <SettingsIcon className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl sm:text-2xl font-black text-slate-900 tracking-tight">Cài Đặt</h1>
              <p className="text-xs text-slate-500 font-medium">Mật khẩu và các thiết bị đang đăng nhập.</p>
            </div>
          </div>
        </div>

        {/* ponytail: điều hướng 2 mục đã chuyển lên sidebar (/password, /sessions) */}

        <div className="space-y-6 max-w-3xl">
          {section === 'password' && (
          <section id="doi-mat-khau" className="rounded-2xl bg-white border border-slate-200 shadow-xs p-6 scroll-mt-20">
            <h2 className="text-sm font-black text-slate-900 uppercase tracking-wide flex items-center gap-2">
              <KeyRound className="w-4 h-4 text-blue-600" aria-hidden="true" />
              Đổi mật khẩu đăng nhập
            </h2>
            <p className="text-xs text-slate-500 mt-1 mb-5">
              Sau khi đổi,{" "}
              <span className="font-bold text-slate-700">
                tất cả phiên đăng nhập sẽ bị thu hồi
              </span>{" "}
              và bạn sẽ phải đăng nhập lại.
            </p>

            <form onSubmit={handleChangePassword} className="space-y-4 text-xs">
              <div>
                <label
                  htmlFor="old-pw"
                  className="block font-bold text-slate-700 mb-1"
                >
                  Mật khẩu hiện tại
                </label>
                <input
                  id="old-pw"
                  type="password"
                  required
                  value={oldPassword}
                  onChange={(e) => setOldPassword(e.target.value)}
                  className="w-full rounded-xl border border-slate-300 p-2.5 focus:border-blue-600 focus:outline-hidden"
                />
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label
                    htmlFor="new-pw"
                    className="block font-bold text-slate-700 mb-1"
                  >
                    Mật khẩu mới (tối thiểu 6 ký tự)
                  </label>
                  <input
                    id="new-pw"
                    type="password"
                    required
                    minLength={6}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className="w-full rounded-xl border border-slate-300 p-2.5 focus:border-blue-600 focus:outline-hidden"
                  />
                </div>
                <div>
                  <label
                    htmlFor="confirm-pw"
                    className="block font-bold text-slate-700 mb-1"
                  >
                    Xác nhận mật khẩu mới
                  </label>
                  <input
                    id="confirm-pw"
                    type="password"
                    required
                    minLength={6}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="w-full rounded-xl border border-slate-300 p-2.5 focus:border-blue-600 focus:outline-hidden"
                  />
                </div>
              </div>
              <button
                type="submit"
                disabled={saving}
                className="px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold shadow-sm transition disabled:opacity-50"
              >
                {saving ? "Đang lưu…" : "Lưu mật khẩu mới"}
              </button>
            </form>
          </section>
          )}

          {section === 'sessions' && (
          <section id="quan-ly-phien" className="rounded-2xl bg-white border border-slate-200 shadow-xs p-6 scroll-mt-20">
            <h2 className="text-sm font-black text-slate-900 uppercase tracking-wide flex items-center gap-2">
              <Monitor className="w-4 h-4 text-emerald-600" aria-hidden="true" />
              Quản lý phiên đăng nhập
            </h2>
            <p className="text-xs text-slate-500 mt-1 mb-4">
              {active.length} phiên đang hoạt động trên tài khoản này.
            </p>
            <button
              onClick={() => setRevokeAllOpen(true)}
              disabled={active.length === 0}
              className="flex items-center gap-1.5 px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold shadow-sm transition disabled:opacity-40 mb-4"
            >
              <LogOut className="w-4 h-4" aria-hidden="true" />
              Đăng xuất tất cả thiết bị
            </button>

            <ul className="divide-y divide-slate-100 border-t border-slate-100">
              {loadingSessions && (
                <li className="py-6 text-center text-slate-400">Đang tải…</li>
              )}
              {!loadingSessions && active.length === 0 && (
                <li className="py-6 text-center text-slate-400">
                  Không có thiết bị nào đang đăng nhập.
                </li>
              )}
              {active.map((s) => (
                <li
                  key={s.sessionId}
                  className="py-3 flex items-center justify-between gap-3"
                >
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-slate-800 truncate">
                      Hệ điều hành thiết bị: {s.deviceOS || "Thiết bị"}
                    </p>

                    <p className="text-xs font-bold text-slate-800 truncate">
                      Trang trình duyệt: {s.browser || "Không rõ"}
                    </p>
                    <p className="text-[11px] text-slate-500 font-mono truncate">
                      Địa chỉ IP: {s.ipAddr || "—"} ·{" "}
                      {s.createdAt ? formatDateVN(s.createdAt) : "—"}
                    </p>
                  </div>
                  <button
                    onClick={() => setRevokeTarget(s.sessionId)}
                    className="shrink-0 px-2.5 py-1.5 rounded-lg border border-rose-200 text-rose-700 hover:bg-rose-50 text-[11px] font-bold transition"
                  >
                    Xóa phiên
                  </button>
                </li>
              ))}
            </ul>

            <button
              onClick={loadSessions}
              className="mt-3 flex items-center gap-1.5 text-[11px] font-bold text-slate-500 hover:text-blue-600 transition"
            >
              <RefreshCw
                className={`w-3 h-3 ${loadingSessions ? "animate-spin" : ""}`}
                aria-hidden="true"
              />
              Làm mới
            </button>
          </section>
          )}
        </div>

        <ConfirmDialog
          open={revokeTarget !== null}
          title="Xóa phiên đăng nhập này?"
          body="Thiết bị đó sẽ bị đăng xuất và phải đăng nhập lại."
          confirmLabel="Xóa phiên"
          busy={revoking}
          onConfirm={handleRevokeConfirm}
          onClose={() => !revoking && setRevokeTarget(null)}
        />
        <ConfirmDialog
          open={revokeAllOpen}
          title="Đăng xuất tất cả thiết bị?"
          body="Kể cả thiết bị bạn đang dùng — bạn sẽ phải đăng nhập lại ngay."
          confirmLabel="Đăng xuất tất cả"
          busy={revoking}
          onConfirm={handleRevokeAllConfirm}
          onClose={() => !revoking && setRevokeAllOpen(false)}
        />
      </div>
    </AppShell>
  );
}
