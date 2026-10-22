'use client';

import React, { useState } from 'react';
import AppShell from '@/components/layout/AppShell';
import { assetService } from '@/services/assetService';
import { AssetTimelineEvent } from '@/types';
import { useManageAssets, ManageGate, AssetCombobox, TimelineList } from '../../manageAssets';
import { History } from 'lucide-react';

export default function AssetLifeCyclePage() {
  const { canEnter, assets } = useManageAssets();
  const [selectedAsset, setSelectedAsset] = useState('');
  const [events, setEvents] = useState<AssetTimelineEvent[]>([]);

  const loadTimeline = async (assetId: string) => {
    setSelectedAsset(assetId);
    if (!assetId) return;
    try { setEvents(await assetService.timeline(assetId)); } catch { setEvents([]); }
  };

  return (
    <ManageGate canEnter={canEnter}>
      <AppShell>
        <div className="p-4 md:p-6 max-w-6xl mx-auto">
          <h1 className="text-xl font-bold text-slate-800 flex items-center gap-2 mb-4">
            <History className="h-5 w-5 text-teal-600" /> Vòng đời tài sản
          </h1>
          <div className="mb-4">
            <AssetCombobox assets={assets} value={selectedAsset} onPick={loadTimeline} placeholder="Gõ mã hoặc tên tài sản để xem vòng đời…" />
          </div>
          <TimelineList events={events} />
          {selectedAsset && events.length === 0 && <p className="text-xs text-slate-400 mt-2">Chưa có sự kiện nào.</p>}
        </div>
      </AppShell>
    </ManageGate>
  );
}
