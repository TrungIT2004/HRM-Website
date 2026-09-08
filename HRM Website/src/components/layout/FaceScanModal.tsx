'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useHRMData } from '@/context/HRMDataContext';
import { Camera, CheckCircle, AlertCircle, Scan, Sparkles, X, UserCheck } from 'lucide-react';

interface FaceScanModalProps {
  onClose: () => void;
}

export default function FaceScanModal({ onClose }: { onClose: () => void }) {
  const { currentUser } = useAuth();
  const { clockInAttendance, clockOutAttendance } = useHRMData();

  const [scanStep, setScanStep] = useState<'scanning' | 'matched' | 'completed' | 'error'>('scanning');
  const [resultMessage, setResultMessage] = useState<string>('');
  const [confidence, setConfidence] = useState<number>(98.8);

  useEffect(() => {
    // Simulate AI Camera Face Match after 1.2s
    const timer = setTimeout(() => {
      if (currentUser) {
        setScanStep('matched');
        setConfidence(Number((98.5 + Math.random() * 1.3).toFixed(1)));
      } else {
        setScanStep('error');
        setResultMessage('Không phát hiện khuôn mặt đăng ký trong cơ sở dữ liệu.');
      }
    }, 1200);

    return () => clearTimeout(timer);
  }, [currentUser]);

  const handlePunch = (type: 'IN' | 'OUT') => {
    if (type === 'IN') {
      const res = clockInAttendance('FACE_SCAN');
      setResultMessage(res.message);
      setScanStep('completed');
    } else {
      const res = clockOutAttendance('FACE_SCAN');
      setResultMessage(res.message);
      setScanStep('completed');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
      <div className="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl border border-slate-200 text-center">
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute right-4 top-4 rounded-full p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition"
        >
          <X className="h-5 w-5" />
        </button>

        {/* Header */}
        <div className="flex items-center justify-center gap-2 text-blue-600 mb-1">
          <Camera className="h-5 w-5" />
          <h3 className="text-base font-bold tracking-tight text-slate-900">
            Máy Quét Khuôn Mặt Điểm Danh (ACT FaceCam)
          </h3>
        </div>
        <p className="text-xs text-slate-500 mb-4">
          Mô phỏng thiết bị nhận diện khuôn mặt kết nối API Spring Boot <code className="bg-slate-100 px-1 py-0.5 rounded font-mono text-[11px]">/api/attendances</code>
        </p>

        {/* Camera HUD Area */}
        <div className="relative mx-auto my-2 flex h-60 w-full items-center justify-center overflow-hidden rounded-xl bg-slate-950 shadow-inner border-2 border-slate-800">
          {/* Animated Scanning Line */}
          {scanStep === 'scanning' && (
            <div className="absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-cyan-400 via-blue-500 to-indigo-500 shadow-lg shadow-cyan-400 animate-pulse animate-[bounce_2s_infinite]" />
          )}

          {/* Camera Frame Targets */}
          <div className="absolute inset-8 rounded-2xl border-2 border-dashed border-cyan-400/50 pointer-events-none flex flex-col justify-between p-2">
            <div className="flex justify-between">
              <span className="h-4 w-4 border-t-2 border-l-2 border-cyan-400" />
              <span className="h-4 w-4 border-t-2 border-r-2 border-cyan-400" />
            </div>
            <div className="flex justify-between">
              <span className="h-4 w-4 border-b-2 border-l-2 border-cyan-400" />
              <span className="h-4 w-4 border-b-2 border-r-2 border-cyan-400" />
            </div>
          </div>

          {/* User Face Placeholder or Recognition Card */}
          {currentUser && (
            <div className="relative z-10 flex flex-col items-center">
              <div className={`flex h-20 w-20 items-center justify-center rounded-full text-2xl font-bold transition-all duration-300 ${
                scanStep === 'matched' || scanStep === 'completed'
                  ? 'bg-emerald-500/20 text-emerald-400 ring-4 ring-emerald-500/50'
                  : 'bg-blue-500/20 text-cyan-300 ring-4 ring-cyan-500/30 animate-pulse'
              }`}>
                {currentUser.lastName?.[0] || currentUser.fullName?.[0]}
              </div>

              {scanStep === 'scanning' && (
                <div className="mt-3 flex items-center gap-1.5 text-xs text-cyan-300 font-medium">
                  <Scan className="h-4 w-4 animate-spin" />
                  <span>Đang căn chỉnh và nhận diện khuôn mặt...</span>
                </div>
              )}

              {scanStep === 'matched' && (
                <div className="mt-3 text-center">
                  <div className="inline-flex items-center gap-1.5 rounded-full bg-emerald-950/80 px-3 py-1 text-xs font-semibold text-emerald-400 border border-emerald-700/50">
                    <CheckCircle className="h-3.5 w-3.5" />
                    <span>Độ khớp: {confidence}%</span>
                  </div>
                  <p className="mt-1 text-sm font-bold text-white">{currentUser.fullName}</p>
                  <p className="text-[11px] text-slate-400">{currentUser.employeeCode} • {currentUser.department}</p>
                </div>
              )}

              {scanStep === 'completed' && (
                <div className="mt-3 text-center">
                  <div className="inline-flex items-center gap-1.5 rounded-full bg-blue-900/80 px-3 py-1 text-xs font-bold text-blue-300 border border-blue-500/50">
                    <Sparkles className="h-3.5 w-3.5" />
                    <span>Ghi nhận thành công</span>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Action Controls */}
        <div className="mt-4">
          {scanStep === 'scanning' && (
            <p className="text-xs text-slate-500 italic">Vui lòng giữ khuôn mặt trước camera...</p>
          )}

          {scanStep === 'matched' && (
            <div className="space-y-2">
              <p className="text-xs text-slate-600">Chọn hành động điểm danh bằng khuôn mặt:</p>
              <div className="grid grid-cols-2 gap-3">
                <button
                  onClick={() => handlePunch('IN')}
                  className="flex items-center justify-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white py-2.5 px-4 text-xs font-bold shadow-md shadow-emerald-500/20 transition cursor-pointer"
                >
                  <CheckCircle className="h-4 w-4" />
                  Chấm Vào Ca
                </button>
                <button
                  onClick={() => handlePunch('OUT')}
                  className="flex items-center justify-center gap-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white py-2.5 px-4 text-xs font-bold shadow-md shadow-blue-500/20 transition cursor-pointer"
                >
                  <CheckCircle className="h-4 w-4" />
                  Chấm Ra Ca
                </button>
              </div>
            </div>
          )}

          {scanStep === 'completed' && (
            <div className="space-y-3">
              <div className="rounded-xl bg-emerald-50 p-3 border border-emerald-200 text-xs text-emerald-800 font-medium">
                {resultMessage}
              </div>
              <button
                onClick={onClose}
                className="w-full rounded-xl bg-slate-900 hover:bg-slate-800 text-white py-2.5 text-xs font-bold transition cursor-pointer"
              >
                Đóng cửa sổ
              </button>
            </div>
          )}

          {scanStep === 'error' && (
            <div className="space-y-3">
              <div className="rounded-xl bg-red-50 p-3 border border-red-200 text-xs text-red-700 font-medium">
                {resultMessage}
              </div>
              <button
                onClick={onClose}
                className="w-full rounded-xl bg-slate-200 text-slate-700 py-2.5 text-xs font-bold transition"
              >
                Đóng
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
