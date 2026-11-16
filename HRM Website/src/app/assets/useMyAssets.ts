'use client';

import { useState } from 'react';
import { assetService } from '@/services/assetService';
import { AssetCategory } from '@/types';
import { useAuth } from '@/context/AuthContext';

// ponytail: danh mục mở cho mọi NV (làm đơn) — cache trong hook, khỏi fetch mỗi trang
export function useMyAssetLookups() {
  const { currentUser } = useAuth();
  const [categories, setCategories] = useState<AssetCategory[]>([]);
  const loadLookups = async () => {
    if (!currentUser) return;
    try { setCategories(await assetService.listCategories()); } catch { /* giữ trống */ }
  };
  const catName = (id?: string) => categories.find((c) => c.categoryId === id)?.name ?? '—';
  return { categories, catName, loadLookups };
}
