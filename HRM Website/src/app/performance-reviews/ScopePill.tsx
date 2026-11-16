'use client';

import React from 'react';

interface Props {
  scope: 'dept' | 'company';
  onChange: (s: 'dept' | 'company') => void;
  deptName?: string;
  canCompany: boolean;
  canDept: boolean;
}

// ponytail: 1 pill dung chung overview + records — tab nao hien theo dung quyen do
// (cha phai chon scope mac dinh + chan truy cap truoc khi render pill)
// ponytail: chi 1 pham vi xem duoc thi an han pill (khong co gi de chuyen)
export default function ScopePill({ scope, onChange, deptName, canCompany, canDept }: Props) {
  if (!canCompany || !canDept) return null;
  return (
    <div className="inline-flex items-center gap-1 rounded-full bg-white border border-slate-200 p-1 shadow-xs mb-3">
      {canCompany && (
        <button onClick={() => onChange('company')}
          className={`px-4 py-1.5 rounded-full text-sm font-semibold transition cursor-pointer ${scope === 'company' ? 'bg-amber-500 text-white shadow' : 'text-slate-500 hover:text-slate-800'}`}>
          Cả công ty
        </button>
      )}
      {canDept && (
        <button onClick={() => onChange('dept')}
          className={`px-4 py-1.5 rounded-full text-sm font-semibold transition cursor-pointer ${scope === 'dept' ? 'bg-amber-500 text-white shadow' : 'text-slate-500 hover:text-slate-800'}`}>
          Phòng ban{deptName ? `: ${deptName}` : ''}
        </button>
      )}
    </div>
  );
}
