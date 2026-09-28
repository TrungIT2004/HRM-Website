'use client';

import React, { useState, useEffect } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { 
  resignationService, 
  ResignationResponse, 
  CreateResignationPayload 
} from '@/services/resignationService';
import { formatDateVN } from '@/utils/format';
import { useTabFromUrl } from '@/utils/useTabFromUrl';
import {
  UserMinus,
  Calendar,
  Clock,
  CheckCircle2,
  AlertCircle,
  XCircle,
  FileText,
  Send,
  Plus,
  X,
  Building2,
  Briefcase,
  AlertTriangle,
  ChevronRight,
  ShieldCheck,
  RefreshCw
} from 'lucide-react';

export default function ResignationsPage() {
  const { currentUser, isHR, isManager, isExecutive, can } = useAuth();

  const [activeTab, setActiveTab] = useTabFromUrl(['my', 'approvals', 'company'] as const, 'my');
  const [myRequests, setMyRequests] = useState<ResignationResponse[]>([]);
  const [approvals, setApprovals] = useState<ResignationResponse[]>([]);
  const [companyRequests, setCompanyRequests] = useState<ResignationResponse[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [toastMsg, setToastMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Modals state
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [createForm, setCreateForm] = useState<CreateResignationPayload>({
    lastWorkingDate: '',
    reason: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Review modal state
  const [reviewModal, setReviewModal] = useState<{
    open: boolean;
    item?: ResignationResponse;
    role: 'manager' | 'executive';
    status: string;
    comment: string;
  }>({
    open: false,
    role: 'manager',
    status: '',
    comment: ''
  });

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMsg({ text, type });
    setTimeout(() => setToastMsg(null), 4000);
  };

  const loadData = async () => {
    setIsLoading(true);
    try {
      const myRes = await resignationService.getMyRequests({ size: 20 });
      if (myRes && myRes.content) {
        setMyRequests(myRes.content);
      }

      if (isManager || isHR || isExecutive || can('RESIGN_APPROVE')) {
        const appRes = await resignationService.getApprovals({ size: 20 });
        if (appRes && appRes.content) {
          setApprovals(appRes.content);
        }
      }

      if (isHR || isExecutive || can('RESIGN_VIEW_ALL')) {
        const compRes = await resignationService.getCompanyRequests({ size: 50 });
        if (compRes && compRes.content) {
          setCompanyRequests(compRes.content);
        }
      }
    } catch (err: any) {
      // ignore
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [currentUser, isManager, isHR, isExecutive, can]);

  // Handle Submit Resignation
  const handleSubmitResignation = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!createForm.lastWorkingDate || !createForm.reason.trim()) {
      showToast('Vui lòng điền đầy đủ ngày làm việc cuối cùng và lý do thôi việc.', 'error');
      return;
    }

    setIsSubmitting(true);
    try {
      await resignationService.submitResignation(createForm);
      showToast('Nộp đơn xin thôi việc thành công! Yêu cầu đang được gửi tới Quản lý trực tiếp.', 'success');
      setIsCreateModalOpen(false);
      setCreateForm({ lastWorkingDate: '', reason: '' });
      await loadData();
    } catch (err: any) {
      showToast(err.message || 'Lỗi gửi đơn thôi việc', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle Cancel My Resignation
  const handleCancel = async (resignationId: string) => {
    if (!confirm('Bạn có chắc chắn muốn hủy đơn xin thôi việc này không?')) return;
    try {
      await resignationService.cancelResignation(resignationId);
      showToast('Đã hủy đơn xin thôi việc thành công!', 'success');
      await loadData();
    } catch (err: any) {
      showToast(err.message || 'Lỗi hủy đơn', 'error');
    }
  };

  // Handle Manager / Executive Review
  const handleReviewSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reviewModal.item) return;

    setIsSubmitting(true);
    try {
      if (reviewModal.role === 'manager') {
        await resignationService.transferResignation({
          resignationId: reviewModal.item.resignationId,
          status: reviewModal.status as any,
          managerComment: reviewModal.comment
        });
        showToast('Trưởng phòng đã cập nhật ý kiến bàn giao thành công!', 'success');
      } else {
        await resignationService.approveResignation({
          resignationId: reviewModal.item.resignationId,
          status: reviewModal.status as any,
          executiveComment: reviewModal.comment
        });
        showToast('Ban Giám Đốc / Nhân sự đã phê duyệt quyết định thôi việc thành công!', 'success');
      }
      setReviewModal({ open: false, role: 'manager', status: '', comment: '' });
      await loadData();
    } catch (err: any) {
      showToast(err.message || 'Lỗi xử lý duyệt đơn', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'PENDING':
        return <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-bold text-amber-700 border border-amber-200"><Clock className="h-3 w-3" /> Chờ Trưởng phòng duyệt</span>;
      case 'MANAGER_APPROVED':
        return <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-bold text-blue-700 border border-blue-200"><CheckCircle2 className="h-3 w-3" /> TP đã duyệt (Chờ BGĐ/HR)</span>;
      case 'MANAGER_REJECTED':
        return <span className="inline-flex items-center gap-1 rounded-full bg-red-50 px-2.5 py-0.5 text-xs font-bold text-red-700 border border-red-200"><XCircle className="h-3 w-3" /> Trưởng phòng từ chối</span>;
      case 'APPROVED':
        return <span className="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-bold text-emerald-700 border border-emerald-200"><CheckCircle2 className="h-3 w-3" /> Đã duyệt thôi việc</span>;
      case 'REJECTED':
        return <span className="inline-flex items-center gap-1 rounded-full bg-rose-50 px-2.5 py-0.5 text-xs font-bold text-rose-700 border border-rose-200"><XCircle className="h-3 w-3" /> BGĐ/HR Từ chối</span>;
      case 'CANCELLED':
        return <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-600 border border-slate-200">Đã hủy</span>;
      case 'COMPLETED':
        return <span className="inline-flex items-center gap-1 rounded-full bg-slate-900 px-2.5 py-0.5 text-xs font-bold text-white">Đã hoàn tất thôi việc</span>;
      default:
        return <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-600">{status}</span>;
    }
  };

  const renderCardList = (list: ResignationResponse[], isApprovalView = false) => {
    if (list.length === 0) {
      return (
        <div className="rounded-3xl bg-white p-8 text-center border border-slate-200/80 shadow-xs">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-slate-400 mx-auto mb-3">
            <CheckCircle2 className="h-6 w-6" />
          </div>
          <p className="text-sm font-bold text-slate-800">Không có đơn xin thôi việc nào trong danh sách</p>
          <p className="text-xs text-slate-500 mt-1">Mọi yêu cầu đã được xử lý hoặc bạn chưa nộp đơn nào.</p>
        </div>
      );
    }

    return (
      <div className="space-y-3.5">
        {list.map(item => (
          <div 
            key={item.resignationId} 
            className="rounded-2xl sm:rounded-3xl bg-white p-4 sm:p-5 border border-slate-200/80 hover:border-blue-200 transition shadow-xs flex flex-col sm:flex-row justify-between gap-4"
          >
            <div className="space-y-2 flex-1">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span className="font-bold text-slate-900 text-sm">{item.fullName}</span>
                  <span className="font-mono text-[11px] text-slate-400 font-semibold">{item.employeeCode}</span>
                </div>
                {getStatusBadge(item.status)}
              </div>

              <div className="flex flex-wrap items-center gap-y-1 gap-x-4 text-xs text-slate-600">
                <span className="flex items-center gap-1.5"><Building2 className="h-3.5 w-3.5 text-slate-400" /> {item.departmentName}</span>
                <span className="flex items-center gap-1.5"><Briefcase className="h-3.5 w-3.5 text-slate-400" /> {item.jobTitle}</span>
                <span className="flex items-center gap-1.5 font-medium text-slate-700"><Calendar className="h-3.5 w-3.5 text-blue-600" /> Ngày làm cuối: <strong>{formatDateVN(item.lastWorkingDate)}</strong></span>
              </div>

              <div className="rounded-xl bg-slate-50 p-2.5 text-xs text-slate-700 border border-slate-100">
                <span className="font-semibold text-slate-500 mr-1.5">Lý do:</span>
                {item.reason}
              </div>

              {item.managerComment && (
                <div className="rounded-xl bg-blue-50/60 p-2.5 text-xs text-blue-800 border border-blue-100">
                  <span className="font-semibold text-blue-600 mr-1.5">Ý kiến Trưởng phòng:</span>
                  {item.managerComment}
                </div>
              )}

              {item.executiveComment && (
                <div className="rounded-xl bg-purple-50/60 p-2.5 text-xs text-purple-800 border border-purple-100">
                  <span className="font-semibold text-purple-600 mr-1.5">Ý kiến BGĐ:</span>
                  {item.executiveComment}
                </div>
              )}
            </div>

            {/* Actions */}
            <div className="flex sm:flex-col justify-end items-end gap-2 border-t sm:border-t-0 pt-3 sm:pt-0 border-slate-100 shrink-0">
              {/* If viewing own pending request -> can Cancel */}
              {!isApprovalView && item.status === 'PENDING' && (
                <button
                  onClick={() => handleCancel(item.resignationId)}
                  className="w-full sm:w-auto px-3.5 py-1.5 rounded-xl border border-red-200 text-red-600 hover:bg-red-50 text-xs font-bold transition"
                >
                  Hủy đơn
                </button>
              )}

              {/* If Manager Approval view (kể cả người được cấp quyền) */}
              {isApprovalView && item.status === 'PENDING' && (isManager || can('RESIGN_APPROVE')) && (
                <button
                  onClick={() => setReviewModal({
                    open: true,
                    item,
                    role: 'manager',
                    status: 'MANAGER_APPROVED',
                    comment: ''
                  })}
                  className="w-full sm:w-auto px-3.5 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold transition shadow-xs"
                >
                  Duyệt bàn giao
                </button>
              )}

              {/* If Executive / HR Approval view (kể cả người được cấp quyền) */}
              {isApprovalView && (item.status === 'MANAGER_APPROVED' || (item.status === 'PENDING' && (isExecutive || can('RESIGN_APPROVE')))) && (isHR || isExecutive || can('RESIGN_APPROVE')) && (
                <button
                  onClick={() => setReviewModal({
                    open: true,
                    item,
                    role: 'executive',
                    status: 'APPROVED',
                    comment: ''
                  })}
                  className="w-full sm:w-auto px-3.5 py-1.5 rounded-xl bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold transition shadow-xs"
                >
                  Quyết định thôi việc
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    );
  };

  return (
    <AppShell>
      <div className="space-y-6">
        {/* Toast Notification */}
        {toastMsg && (
          <div className={`p-4 rounded-2xl text-xs font-bold flex items-center justify-between border shadow-lg ${
            toastMsg.type === 'success' 
              ? 'bg-emerald-50 text-emerald-800 border-emerald-200' 
              : 'bg-red-50 text-red-800 border-red-200'
          }`}>
            <span>{toastMsg.text}</span>
            <button onClick={() => setToastMsg(null)} className="p-1 hover:opacity-75"><X className="h-4 w-4" /></button>
          </div>
        )}

        {/* Page Header */}
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-700 mb-1.5 border border-slate-200">
              <UserMinus className="h-3.5 w-3.5 text-red-500" />
              <span>Quy trình thôi việc & Bàn giao nhân sự</span>
            </div>
            <h1 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight">
              Quản Lý Thôi Việc
            </h1>
            <p className="text-xs sm:text-sm text-slate-500 mt-0.5">
              Theo dõi chu trình thôi việc chuẩn 3 bước: Nhân viên nộp đơn → Trưởng phòng duyệt bàn giao → BGĐ/HR phê duyệt chính thức.
            </p>
          </div>

          <div className="flex items-center gap-2 w-full sm:w-auto">
            <button
              onClick={() => setIsCreateModalOpen(true)}
              className="flex-1 sm:flex-none inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs sm:text-sm font-bold shadow-xs transition active:scale-95 cursor-pointer"
            >
              <Plus className="h-4 w-4" />
              <span>Nộp đơn thôi việc</span>
            </button>
            <button
              onClick={loadData}
              disabled={isLoading}
              className="p-2.5 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 transition"
              title="Tải lại"
            >
              <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin text-blue-600' : ''}`} />
            </button>
          </div>
        </div>

        {/* Tabs Selection */}
        <div className="flex items-center gap-2 border-b border-slate-200/80 pb-px overflow-x-auto text-xs font-bold scrollbar-none">
          <button
            onClick={() => setActiveTab('my')}
            className={`py-2.5 px-4 rounded-xl transition whitespace-nowrap cursor-pointer ${
              activeTab === 'my'
                ? 'bg-blue-600 text-white shadow-xs'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
            }`}
          >
            Đơn của tôi ({myRequests.length})
          </button>

          {(isManager || isHR || isExecutive || can('RESIGN_APPROVE')) && (
            <button
              onClick={() => setActiveTab('approvals')}
              className={`py-2.5 px-4 rounded-xl transition whitespace-nowrap cursor-pointer flex items-center gap-1.5 ${
                activeTab === 'approvals'
                  ? 'bg-blue-600 text-white shadow-xs'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <span>Chờ xét duyệt</span>
              {approvals.length > 0 && (
                <span className="rounded-full bg-amber-400 text-slate-950 px-1.5 py-0.2 text-[10px] font-extrabold">
                  {approvals.length}
                </span>
              )}
            </button>
          )}

          {(isHR || isExecutive || can('RESIGN_VIEW_ALL')) && (
            <button
              onClick={() => setActiveTab('company')}
              className={`py-2.5 px-4 rounded-xl transition whitespace-nowrap cursor-pointer ${
                activeTab === 'company'
                  ? 'bg-blue-600 text-white shadow-xs'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              Toàn công ty ({companyRequests.length})
            </button>
          )}
        </div>

        {/* Tab Content */}
        {activeTab === 'my' && renderCardList(myRequests, false)}
        {activeTab === 'approvals' && renderCardList(approvals, true)}
        {activeTab === 'company' && renderCardList(companyRequests, false)}

        {/* MODAL 1: NỘP ĐƠN THÔI VIỆC */}
        {isCreateModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in">
            <div className="relative w-full max-w-lg rounded-3xl bg-white p-6 shadow-2xl border border-slate-100">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3 mb-4">
                <div className="flex items-center gap-2">
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-red-100 text-red-600 font-bold">
                    <UserMinus className="h-5 w-5" />
                  </div>
                  <h3 className="text-base font-extrabold text-slate-900">Nộp Đơn Xin Thôi Việc</h3>
                </div>
                <button onClick={() => setIsCreateModalOpen(false)} className="p-1 text-slate-400 hover:text-slate-600 rounded-lg">
                  <X className="h-5 w-5" />
                </button>
              </div>

              {/* Notice Period Regulation Box */}
              <div className="rounded-2xl bg-amber-50 p-3.5 border border-amber-200/80 mb-4 text-xs text-amber-800 flex items-start gap-2.5">
                <AlertTriangle className="h-4 w-4 text-amber-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="block font-bold">Quy định thời hạn báo trước (Bộ luật Lao động):</strong>
                  <ul className="list-disc list-inside mt-1 space-y-0.5 text-[11px] text-amber-700">
                    <li>Hợp đồng không xác định thời hạn: Báo trước tối thiểu <strong>45 ngày</strong></li>
                    <li>Hợp đồng xác định thời hạn: Báo trước tối thiểu <strong>30 ngày</strong></li>
                    <li>Hợp đồng thử việc: Báo trước tối thiểu <strong>3 ngày làm việc</strong></li>
                  </ul>
                </div>
              </div>

              <form onSubmit={handleSubmitResignation} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">
                    Ngày làm việc cuối cùng dự kiến <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="date"
                    required
                    min={new Date().toISOString().split('T')[0]}
                    value={createForm.lastWorkingDate}
                    onChange={e => setCreateForm({ ...createForm, lastWorkingDate: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-xs text-slate-800 focus:border-blue-600 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">
                    Lý do xin thôi việc <span className="text-red-500">*</span>
                  </label>
                  <textarea
                    required
                    rows={4}
                    maxLength={500}
                    placeholder="Vui lòng nêu rõ lý do thôi việc và kế hoạch bàn giao công việc..."
                    value={createForm.reason}
                    onChange={e => setCreateForm({ ...createForm, reason: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 p-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-none resize-none"
                  />
                  <span className="text-[10px] text-slate-400 block text-right mt-1">{createForm.reason.length}/500 ký tự</span>
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => setIsCreateModalOpen(false)}
                    className="px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-600 hover:bg-slate-50 transition"
                  >
                    Hủy bỏ
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-xs transition"
                  >
                    {isSubmitting ? 'Đang gửi...' : 'Xác nhận nộp đơn'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* MODAL 2: DUYỆT ĐƠN BÀN GIAO / PHÊ DUYỆT */}
        {reviewModal.open && reviewModal.item && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in">
            <div className="relative w-full max-w-lg rounded-3xl bg-white p-6 shadow-2xl border border-slate-100">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3 mb-4">
                <div>
                  <h3 className="text-base font-extrabold text-slate-900">
                    {reviewModal.role === 'manager' ? 'Duyệt Bàn Giao (Trưởng Phòng)' : 'Quyết Định Thôi Việc (BGĐ / HR)'}
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Nhân sự: <strong>{reviewModal.item.fullName}</strong> ({reviewModal.item.employeeCode})
                  </p>
                </div>
                <button onClick={() => setReviewModal({ ...reviewModal, open: false })} className="p-1 text-slate-400 hover:text-slate-600 rounded-lg">
                  <X className="h-5 w-5" />
                </button>
              </div>

              <form onSubmit={handleReviewSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">Quyết định xử lý <span className="text-red-500">*</span></label>
                  <select
                    value={reviewModal.status}
                    onChange={e => setReviewModal({ ...reviewModal, status: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-xs text-slate-800 focus:border-blue-600 focus:outline-none font-bold"
                  >
                    {reviewModal.role === 'manager' ? (
                      <>
                        <option value="MANAGER_APPROVED">✅ Đồng ý bàn giao (Chuyển lên BGĐ/HR)</option>
                        <option value="MANAGER_REJECTED">❌ Từ chối đơn bàn giao</option>
                      </>
                    ) : (
                      <>
                        <option value="APPROVED">✅ Phê duyệt thôi việc chính thức</option>
                        <option value="REJECTED">❌ Từ chối thôi việc</option>
                      </>
                    )}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 mb-1.5">Ý kiến nhận xét / Ghi chú</label>
                  <textarea
                    rows={3}
                    maxLength={500}
                    placeholder="Nhập ý kiến chỉ đạo, xác nhận bàn giao tài sản hoặc yêu cầu bổ sung..."
                    value={reviewModal.comment}
                    onChange={e => setReviewModal({ ...reviewModal, comment: e.target.value })}
                    className="w-full rounded-xl border border-slate-200 p-3 text-xs text-slate-800 focus:border-blue-600 focus:outline-none resize-none"
                  />
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => setReviewModal({ ...reviewModal, open: false })}
                    className="px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-600 hover:bg-slate-50 transition"
                  >
                    Đóng
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-xs transition"
                  >
                    {isSubmitting ? 'Đang cập nhật...' : 'Xác nhận xử lý'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
