import { useEffect, useState } from 'react';

/**
 * Đọc `?tab=` từ URL để mở thẳng tab (vd /leave?tab=approvals).
 *
 * ponytail: đọc trong useEffect chứ không đọc trong useState initializer —
 * ở App Router, khi điều hướng bằng <Link> (client-side) thì state initializer
 * chạy TRƯỚC khi router commit URL, nên window.location.search còn là URL cũ
 * → deep-link rơi về tab mặc định. Effect chạy sau commit thì URL chắc chắn
 * đã đúng. Đổi lại: fetch 2 lần thay vì 1 (giải pháp useSearchHooks phải bọc
 * <Suspense> ở từng trang, tốn hơn).
 *
 * Giá trị ngoài `allowed` thì bỏ qua, giữ nguyên `fallback`.
 */
export function useTabFromUrl<T extends string>(allowed: readonly T[], fallback: T) {
  const [tab, setTab] = useState<T>(fallback);

  useEffect(() => {
    const t = new URLSearchParams(window.location.search).get('tab');
    if (allowed.includes(t as T)) setTab(t as T);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return [tab, setTab] as const;
}
