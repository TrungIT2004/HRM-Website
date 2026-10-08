'use client';

import React, { useState, useEffect } from 'react';
import { workShiftService, WorkShiftResponse } from '@/services/workShiftService';
import {
  Calendar,
  Clock,
  AlertCircle,
  Coffee,
  Sun
} from 'lucide-react';

const DAYS_OF_WEEK = [
  { day: 1, name: 'Thứ 2' },
  { day: 2, name: 'Thứ 3' },
  { day: 3, name: 'Thứ 4' },
  { day: 4, name: 'Thứ 5' },
  { day: 5, name: 'Thứ 6' },
  { day: 6, name: 'Thứ 7' },
  { day: 7, name: 'Chủ nhật' }
];

// ponytail: trang này chỉ hiện ca của chính mình (GET /my-shift).
// Quản trị ca toàn công ty nằm ở /organization/manage (tab Ca làm việc).
export default function WorkShiftTab() {
  const [shift, setShift] = useState<WorkShiftResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');

  useEffect(() => {
    workShiftService
      .getMyShift()
      .then(setShift)
      .catch((err: any) => {
        setErrorMsg(
          err?.status === 404
            ? 'Tài khoản chưa được phân ca làm việc. Vui lòng liên hệ phòng Nhân sự.'
            : err?.response?.data?.msg || err?.message || 'Không thể tải ca làm việc của bạn'
        );
      })
      .finally(() => setIsLoading(false));
  }, []);

  if (isLoading) {
    return (
      <div className="py-12 text-center text-xs text-slate-400">
        <div className="inline-block h-6 w-6 rounded-full border-2 border-orange-500 border-t-transparent animate-spin mb-2" />
        <p>Đang tải ca làm việc của bạn...</p>
      </div>
    );
  }

  if (errorMsg || !shift) {
    return (
      <div className="bg-white rounded-2xl p-12 text-center border border-slate-200 shadow-xs">
        <Calendar className="h-10 w-10 text-slate-300 mx-auto mb-3" />
        <p className="text-sm font-bold text-slate-700">Chưa có ca làm việc</p>
        <p className="text-xs text-slate-400 mt-1 flex items-center justify-center gap-1.5">
          <AlertCircle className="h-3.5 w-3.5" />
          <span>{errorMsg}</span>
        </p>
      </div>
    );
  }

  const workingDaysCount = shift.schedules?.filter(s => s.isWorking ?? s.working).length || 0;
  const sampleSchedule = shift.schedules?.find(s => s.isWorking ?? s.working);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-base font-bold text-slate-900">Ca làm việc của tôi</h2>
        <p className="text-xs text-slate-500">
          Khung giờ vào/ra ca, nghỉ giữa ca và các ngày làm việc trong tuần của bạn.
        </p>
      </div>

      <div className="bg-white rounded-2xl p-5 border border-slate-200/90 shadow-xs max-w-2xl">
        <div className="flex items-center gap-2.5">
          <div className="h-9 w-9 rounded-xl bg-orange-50 flex items-center justify-center text-orange-600 border border-orange-100">
            <Clock className="h-4 w-4" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-slate-900">{shift.name}</h3>
            <span className="text-[11px] font-semibold text-slate-500">
              {workingDaysCount} ngày làm việc / tuần
            </span>
          </div>
        </div>

        {sampleSchedule && (
          <div className="mt-4 grid grid-cols-2 gap-2 text-xs">
            <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center gap-2">
              <Sun className="h-4 w-4 text-amber-500 shrink-0" />
              <div>
                <p className="text-[10px] text-slate-400 font-medium">Khung giờ làm việc</p>
                <p className="font-bold text-slate-800 font-mono">
                  {sampleSchedule.startTime?.substring(0, 5)} - {sampleSchedule.endTime?.substring(0, 5)}
                </p>
              </div>
            </div>

            <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center gap-2">
              <Coffee className="h-4 w-4 text-orange-500 shrink-0" />
              <div>
                <p className="text-[10px] text-slate-400 font-medium">Nghỉ giữa ca</p>
                <p className="font-bold text-slate-800 font-mono">
                  {sampleSchedule.restStartTime?.substring(0, 5) || '--:--'} - {sampleSchedule.restEndTime?.substring(0, 5) || '--:--'}
                </p>
              </div>
            </div>
          </div>
        )}

        <div className="mt-4 border border-slate-100 rounded-xl overflow-hidden">
          <table className="w-full text-left text-[11px]">
            <thead className="bg-slate-50 text-slate-500 border-b border-slate-100">
              <tr>
                <th className="py-2 px-3 font-semibold">Thứ</th>
                <th className="py-2 px-3 font-semibold">Trạng thái</th>
                <th className="py-2 px-3 font-semibold text-right">Giờ làm việc</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {DAYS_OF_WEEK.map(d => {
                const sched = shift.schedules?.find(s => s.dayOfWeek === d.day);
                const isWorking = sched?.isWorking ?? sched?.working;
                return (
                  <tr key={d.day} className="hover:bg-slate-50/50">
                    <td className="py-1.5 px-3 font-medium text-slate-700">{d.name}</td>
                    <td className="py-1.5 px-3">
                      {isWorking ? (
                        <span className="inline-block px-2 py-0.5 rounded-full text-[9px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                          Làm việc
                        </span>
                      ) : (
                        <span className="inline-block px-2 py-0.5 rounded-full text-[9px] font-medium bg-slate-100 text-slate-500">
                          Nghỉ ca
                        </span>
                      )}
                    </td>
                    <td className="py-1.5 px-3 text-right font-mono text-slate-600">
                      {isWorking ? `${sched?.startTime?.substring(0, 5)} - ${sched?.endTime?.substring(0, 5)}` : '—'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
