'use client';

import React from 'react';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

// ponytail: % MoM tinh o client (goi API thang truoc them 1 lan) — khoi sua backend
export function momPct(cur: number, prev: number): number | null {
  if (prev === 0) return null;
  return Math.round(((cur - prev) / Math.abs(prev)) * 10000) / 100;
}

export default function MomLine({ cur, prev }: { cur?: number | null; prev?: number | null }) {
  if (cur == null) return <span className="text-[11px] text-slate-300">—</span>;
  if (prev == null || prev === 0) {
    if (cur === 0) return <span className="text-[11px] text-slate-400">Không thay đổi</span>;
    return <span className="text-[11px] font-semibold text-emerald-600">Mới trong kỳ</span>;
  }
  const p = momPct(cur, prev) ?? 0;
  if (p === 0) {
    return (
      <span className="flex items-center gap-1 text-[11px] font-semibold text-slate-400">
        <Minus className="h-3.5 w-3.5" /> Không thay đổi
      </span>
    );
  }
  const up = p > 0;
  return (
    <span className={`flex items-center gap-1 text-[11px] font-semibold ${up ? 'text-emerald-600' : 'text-rose-600'}`}>
      {up ? <TrendingUp className="h-3.5 w-3.5" /> : <TrendingDown className="h-3.5 w-3.5" />}
      {up ? '+' : ''}{p}% <span className="font-normal text-slate-400">So với tháng trước</span>
    </span>
  );
}
