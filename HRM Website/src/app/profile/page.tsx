'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';

export default function ProfileRedirectPage() {
  const router = useRouter();
  const { currentUser } = useAuth();

  useEffect(() => {
    if (currentUser) {
      router.replace(`/employees/${currentUser.userId}`);
    } else {
      router.replace('/login');
    }
  }, [currentUser, router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 text-xs text-slate-500">
      Đang tải hồ sơ của bạn...
    </div>
  );
}
