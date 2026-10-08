'use client';

import React from 'react';

export default function LandingPage() {
  React.useEffect(() => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('act_hrm_access_token') : null;
    window.location.replace(token ? '/home' : '/login');
  }, []);

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4 font-sans">
      <div className="flex flex-col items-center gap-3 text-center">
        <div className="h-8 w-8 animate-spin rounded-full border-3 border-blue-600 border-t-transparent" />
        <p className="text-xs text-slate-500 font-medium">Đang chuyển hướng...</p>
      </div>
    </div>
  );
}
