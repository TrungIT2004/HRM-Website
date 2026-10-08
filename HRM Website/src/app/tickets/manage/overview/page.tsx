'use client';

import React, { useEffect, useMemo, useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { ticketService } from '@/services/ticketService';
import { ItTicket, ItTicketOverview } from '@/types';
import { itCategoryColor, itCategoryLabel } from '../../labels';
import { TicketDetailModal } from '../../TicketDetail';
import { useTicketDirectory } from '../../useTicketDirectory';
import { AlertTriangle, CheckCircle2, Clock, Inbox, Medal, PieChart, TrendingDown, TrendingUp, UserCheck } from 'lucide-react';

// ponytail: % so với tháng trước tính ở client từ 2 cụm backend trả cùng 1 call — khỏi thêm API
function delta(curr: number, prev: number): { text: string; up: boolean | null } {
  if (prev === 0) return curr === 0 ? { text: '—', up: null } : { text: 'mới', up: true };
  const pct = Math.round(((curr - prev) / prev) * 100);
  if (pct === 0) return { text: '±0%', up: null };
  return { text: `${pct > 0 ? '+' : ''}${pct}%`, up: pct > 0 };
}

export default function TicketOverviewPage() {
  const { currentUser, can } = useAuth();
  const canHandle = can('IT_TICKET_HANDLE');
  const { nameOf } = useTicketDirectory();
  const now = new Date();
  // ponytail: mặc định tháng trước (tháng hiện tại chưa chốt số, xem dễ hiểu lầm) — user đổi tay khi cần
  const d0 = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const [year, setYear] = useState(d0.getFullYear());
  const [month, setMonth] = useState(d0.getMonth() + 1);
  const [data, setData] = useState<ItTicketOverview | null>(null);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<ItTicket | null>(null);

  const load = async () => {
    setLoading(true);
    try { setData(await ticketService.overview(year, month)); } catch { /* giữ trống */ } finally { setLoading(false); }
  };

  useEffect(() => { if (currentUser && canHandle) load(); }, [currentUser?.userId, year, month]);

  const stats = useMemo(() => {
    if (!data) return null;
    const cats = Object.entries(data.byCategory).sort((a, b) => b[1] - a[1]);
    let acc = 0;
    const stops = cats.map(([cat, count]) => {
      const from = (acc / data.total) * 100;
      acc += count;
      const to = (acc / data.total) * 100;
      return `${itCategoryColor(cat)} ${from}% ${to}%`;
    });
    const ageDays = (iso: string) => Math.max(0, Math.floor((Date.now() - new Date(iso).getTime()) / 86400000));
    return { cats, donut: stops.length ? `conic-gradient(${stops.join(', ')})` : '#f1f5f9', ageDays };
  }, [data]);

  if (currentUser && !canHandle) {
    return (
      <AppShell>
        <p className="p-6 text-sm text-slate-500">Bạn cần quyền xử lý IT ticket (IT_TICKET_HANDLE) để vào trang này.</p>
      </AppShell>
    );
  }

  return (
    <AppShell>
      <div className="p-4 md:p-6 max-w-5xl mx-auto">
        <div className="flex flex-wrap items-center justify-between gap-3 mb-4">
          <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2">
            <PieChart className="h-5 w-5 text-teal-600" /> Tổng quan tháng {month}/{year}
          </h1>
          <div className="flex gap-2">
            <select value={month} onChange={(e) => setMonth(Number(e.target.value))}
              className="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-white" aria-label="Tháng">
              {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
                <option key={m} value={m}>Tháng {m}</option>
              ))}
            </select>
            <select value={year} onChange={(e) => setYear(Number(e.target.value))}
              className="text-sm border border-slate-200 rounded-xl px-3 py-2 bg-white" aria-label="Năm">
              {[2025, 2026, 2027].map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
          </div>
        </div>
        {loading ? <p className="text-sm text-slate-400">Đang tải…</p> : !data || !stats ? <p className="text-sm text-slate-400">Không tải được số liệu.</p> : (
          <div className="space-y-4">
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
              <StatCard icon={<Inbox className="h-4 w-4" />} label="Ticket nhân viên gửi" value={data.total}
                tone="bg-slate-100 text-slate-600" strong="text-slate-800" d={delta(data.total, data.prev.total)} />
              <StatCard icon={<CheckCircle2 className="h-4 w-4" />} label="Đã hoàn thành" value={data.byStatus?.DONE ?? 0}
                tone="bg-emerald-100 text-emerald-700" strong="text-emerald-700" d={delta(data.byStatus?.DONE ?? 0, data.prev.done)} />
              <StatCard icon={<UserCheck className="h-4 w-4" />} label="Mình hoàn thành" value={data.mineDone}
                tone="bg-teal-100 text-teal-700" strong="text-teal-700" d={delta(data.mineDone, data.prev.mineDone)} />
              <StatCard icon={<Clock className="h-4 w-4" />} label="Chưa hoàn thành" value={data.open}
                tone="bg-amber-100 text-amber-700" strong="text-amber-700" d={delta(data.open, data.prev.open)} invert />
            </div>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-3">
              <div className="bg-white border border-slate-200 rounded-2xl p-5">
                <p className="text-sm font-semibold text-slate-700 mb-4">Tỉ trọng loại sự cố</p>
                {data.total === 0 ? <p className="text-xs text-slate-400">Chưa có ticket nào trong tháng.</p> : (
                  <div className="flex items-center gap-5">
                    <div className="relative h-32 w-32 shrink-0 rounded-full" style={{ background: stats.donut }} role="img" aria-label="Biểu đồ tỉ trọng loại sự cố">
                      <div className="absolute inset-4 rounded-full bg-white flex flex-col items-center justify-center">
                        <span className="text-xl font-bold text-slate-800">{data.total}</span>
                        <span className="text-[11px] text-slate-400">ticket</span>
                      </div>
                    </div>
                    <div className="flex-1 space-y-1.5 min-w-0">
                      {stats.cats.map(([cat, count]) => (
                        <div key={cat} className="flex items-center gap-2 text-xs">
                          <span className="h-2.5 w-2.5 rounded-full shrink-0" style={{ background: itCategoryColor(cat) }} />
                          <span className="text-slate-600 truncate flex-1">{itCategoryLabel(cat)}</span>
                          <span className="font-semibold text-slate-800">{count} · {Math.round((count / data.total) * 100)}%</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
              <div className="bg-white border border-slate-200 rounded-2xl p-5">
                <p className="text-sm font-semibold text-slate-700 mb-4 flex items-center gap-1.5">
                  <Medal className="h-4 w-4 text-amber-500" /> Top người xử lý
                </p>
                {data.topHandlers.length === 0 ? <p className="text-xs text-slate-400">Chưa có.</p> : (
                  <div className="space-y-3">
                    {data.topHandlers.map((h, i) => (
                      <div key={h.assigneeId}>
                        <div className="flex justify-between text-xs mb-1">
                          <span className="text-slate-700 font-medium">#{i + 1} · {nameOf(h.assigneeId)}</span>
                          <span className="font-semibold text-slate-800">{h.count} ticket</span>
                        </div>
                        <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                          <div className="h-full rounded-full bg-gradient-to-r from-teal-500 to-emerald-400"
                            style={{ width: `${Math.round((h.count / data.topHandlers[0].count) * 100)}%` }} />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
            {data.attention.length > 0 && (
              <div className="bg-white border border-slate-200 rounded-2xl p-5">
                <p className="text-sm font-semibold text-slate-700 mb-1 flex items-center gap-1.5">
                  <AlertTriangle className="h-4 w-4 text-rose-500" /> Cần chú ý — tồn đọng lâu nhất
                </p>
                <p className="text-xs text-slate-400 mb-3">Đơn chưa xong, xếp theo ngày gửi cũ nhất.</p>
                <div className="divide-y divide-slate-100">
                  {data.attention.map((t) => (
                    <button key={t.ticketId} onClick={() => setSelected(t)}
                      className="w-full flex items-center gap-3 py-2.5 text-left cursor-pointer group">
                      {t.priority === 'HIGH'
                        ? <span className="text-[11px] font-bold text-white bg-rose-600 px-2 py-0.5 rounded-lg shrink-0">GẤP</span>
                        : <span className="w-2 shrink-0" />}
                      <span className="flex-1 min-w-0">
                        <span className="block text-sm font-medium text-slate-800 truncate group-hover:text-teal-700">{t.deviceInfo}</span>
                        <span className="block text-xs text-slate-500 truncate">{itCategoryLabel(t.category)} · Gửi bởi {nameOf(t.reporterId)}</span>
                      </span>
                      <span className="text-xs text-slate-400 shrink-0">{stats.ageDays(t.createdAt)} ngày</span>
                    </button>
                  ))}
                </div>
              </div>
            )}
            {data.trend.length > 1 && (
              <div className="bg-white border border-slate-200 rounded-2xl p-5">
                <p className="text-sm font-semibold text-slate-700 mb-1">Xu hướng 6 tháng</p>
                <p className="text-xs text-slate-400 mb-4"><span className="inline-block h-2 w-2 rounded-full bg-emerald-500 mr-1" />Hoàn thành<span className="inline-block h-2 w-2 rounded-full bg-slate-200 ml-3 mr-1" />Chưa xong</p>
                <div className="flex items-end gap-3 h-36">
                  {data.trend.map((p) => {
                    const max = Math.max(...data.trend.map((x) => x.total), 1);
                    return (
                      <div key={p.ym} className="flex-1 flex flex-col items-center gap-1.5 min-w-0">
                        <span className="text-[11px] font-semibold text-slate-700">{p.total}</span>
                        <div className="w-full max-w-10 h-24 rounded-lg bg-slate-100 overflow-hidden flex flex-col justify-end">
                          <div className="w-full bg-emerald-500 rounded-lg" style={{ height: `${Math.round((p.done / max) * 100)}%` }} />
                        </div>
                        <span className="text-[11px] text-slate-400">T{p.ym % 100}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </div>
        )}
        {selected && <TicketDetailModal ticket={selected} onClose={() => setSelected(null)} />}
      </div>
    </AppShell>
  );
}

function StatCard({ icon, label, value, tone, strong, d, invert }: {
  icon: React.ReactNode; label: string; value: number; tone: string; strong: string;
  d: { text: string; up: boolean | null }; invert?: boolean;
}) {
  const good = d.up === null ? null : (invert ? !d.up : d.up);
  return (
    <div className="bg-white border border-slate-200 rounded-2xl p-4">
      <p className={`inline-flex items-center gap-1.5 text-xs font-medium px-2 py-1 rounded-lg ${tone}`}>{icon}{label}</p>
      <p className={`text-2xl font-bold mt-2 ${strong}`}>{value}</p>
      <p className={`inline-flex items-center gap-1 text-xs font-semibold mt-1 ${
        good === null ? 'text-slate-400' : good ? 'text-emerald-600' : 'text-rose-600'}`}>
        {d.up === true ? <TrendingUp className="h-3.5 w-3.5" /> : d.up === false ? <TrendingDown className="h-3.5 w-3.5" /> : null}
        {d.text === '—' ? '—' : <>{d.text} <span className="font-normal text-slate-400">So với tháng trước</span></>}
      </p>
    </div>
  );
}
