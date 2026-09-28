'use client';

import React from 'react';
import { AlertTriangle } from 'lucide-react';

type ConfirmDialogProps = {
  open: boolean;
  title: string;
  /** Nêu rõ hậu quả (không chỉ lặp lại tên nút) — guideline "Confirmation Dialogs". */
  body: string;
  confirmLabel?: string;
  busy?: boolean;
  onConfirm: () => void;
  onClose: () => void;
};

/** Popup xác nhận hành động không hoàn tác (chốt sổ công, phê duyệt lương). */
export default function ConfirmDialog({
  open, title, body, confirmLabel = 'Xác nhận', busy = false, onConfirm, onClose
}: ConfirmDialogProps) {
  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4"
      onClick={onClose}
    >
      <div
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="confirm-dialog-title"
        onClick={e => e.stopPropagation()}
        className="w-full max-w-md rounded-3xl bg-white p-6 shadow-2xl border border-slate-200"
      >
        <div className="flex items-start gap-3">
          <span className="shrink-0 inline-flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-600">
            <AlertTriangle className="h-5 w-5" aria-hidden="true" />
          </span>
          <div>
            <h2 id="confirm-dialog-title" className="text-base font-black text-slate-900">{title}</h2>
            <p className="mt-1.5 text-xs text-slate-600">{body}</p>
          </div>
        </div>

        <div className="mt-6 flex items-center justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            disabled={busy}
            className="rounded-xl border border-slate-300 px-4 py-2.5 text-xs font-bold text-slate-700 hover:bg-slate-50 transition cursor-pointer disabled:opacity-50"
          >
            Hủy
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={busy}
            className="rounded-xl bg-amber-600 hover:bg-amber-700 disabled:opacity-50 text-white px-5 py-2.5 text-xs font-bold shadow-sm transition cursor-pointer"
          >
            {busy ? 'Đang xử lý…' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
