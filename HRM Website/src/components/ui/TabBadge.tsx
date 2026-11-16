'use client';

import React, { useEffect } from 'react';
import { useNotifications } from '@/context/NotificationContext';

export default function TabBadge() {
  const { unreadCount } = useNotifications();

  useEffect(() => {
    if (typeof document === 'undefined') return;

    const originalTitle = 'ACT HRM';
    const originalFavicon = document.querySelector<HTMLLinkElement>("link[rel*='icon']")?.href;

    if (unreadCount > 0) {
      // Update document title
      document.title = `(${unreadCount}) ${originalTitle}`;

      // Update favicon with badge using canvas
      updateFaviconBadge(unreadCount);
    } else {
      // Restore original title and favicon
      document.title = originalTitle;
      if (originalFavicon) {
        const link = document.querySelector<HTMLLinkElement>("link[rel*='icon']");
        if (link) link.href = originalFavicon;
      }
    }
  }, [unreadCount]);

  const updateFaviconBadge = (count: number) => {
    try {
      const canvas = document.createElement('canvas');
      canvas.width = 32;
      canvas.height = 32;
      const ctx = canvas.getContext('2d');
      if (!ctx) return;

      // Draw original favicon if available
      const originalFavicon = document.querySelector<HTMLLinkElement>("link[rel*='icon']");
      if (originalFavicon) {
        const img = new Image();
        img.src = originalFavicon.href;
        img.onload = () => {
          ctx.drawImage(img, 0, 0, 32, 32);
          drawBadge(ctx, count);
          applyFavicon(canvas.toDataURL());
        };
        img.onerror = () => {
          drawDefaultFavicon(ctx);
          drawBadge(ctx, count);
          applyFavicon(canvas.toDataURL());
        };
      } else {
        drawDefaultFavicon(ctx);
        drawBadge(ctx, count);
        applyFavicon(canvas.toDataURL());
      }
    } catch (error) {
      console.warn('Failed to update favicon badge:', error);
    }
  };

  const drawDefaultFavicon = (ctx: CanvasRenderingContext2D) => {
    // Draw a simple blue square with "ACT" text
    ctx.fillStyle = '#2563eb';
    ctx.fillRect(0, 0, 32, 32);
    ctx.fillStyle = 'white';
    ctx.font = 'bold 12px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('ACT', 16, 18);
  };

  const drawBadge = (ctx: CanvasRenderingContext2D, count: number) => {
    const radius = 10;
    const x = 22;
    const y = 10;

    // Draw badge background
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, 2 * Math.PI);
    ctx.fillStyle = '#ef4444';
    ctx.fill();

    // Draw count text
    ctx.fillStyle = 'white';
    ctx.font = 'bold 10px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const text = count > 99 ? '99+' : String(count);
    ctx.fillText(text, x, y);
  };

  const applyFavicon = (dataUrl: string) => {
    let link = document.querySelector<HTMLLinkElement>("link[rel*='icon']");
    if (!link) {
      link = document.createElement('link');
      link.rel = 'icon';
      document.head.appendChild(link);
    }
    link.href = dataUrl;
  };

  return null; // This component doesn't render anything visible
}