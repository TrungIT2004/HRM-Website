'use client';

import { useAuth } from '@/context/AuthContext';

// ponytail: 1 helper tên user dùng chung cho queues/done/overview — tra allUsers sẵn có, fallback 8 ký tự đầu
export function useTicketDirectory() {
  const { allUsers } = useAuth();
  const nameOf = (id?: string | null) =>
    allUsers.find((u) => u.userId === id)?.fullName ?? (id ? id.slice(0, 8) : '—');
  return { nameOf };
}
