'use client';

import React, { useState, useEffect, useRef } from 'react';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import {
  aiService,
  KnowledgeDocument
} from '@/services/aiService';
import {
  documentService,
  TemplateDocument,
  TemplateCategory,
  TEMPLATE_CATEGORY_LABELS
} from '@/services/documentService';
import { formatDateVN } from '@/utils/format';
import { DEPARTMENTS } from '@/constants/departments';
import {
  FileText,
  Upload,
  Download,
  Trash2,
  Pencil,
  Search,
  Filter,
  Sparkles,
  RefreshCw,
  FolderOpen,
  CheckCircle2,
  Clock,
  AlertTriangle,
  Building2,
  ChevronRight,
  X,
  FileCheck,
  FileSpreadsheet,
  FileCode,
  File,
  MessageSquare,
  ShieldCheck,
  Plus
} from 'lucide-react';

const formatFileSize = (bytes: number) => {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
};

function FileDropzone({
  inputRef,
  file,
  onPick,
  emptyTitle,
  emptyHint
}: {
  inputRef: React.RefObject<HTMLInputElement | null>;
  file: File | null;
  onPick: (f: File) => void;
  emptyTitle: string;
  emptyHint: string;
}) {
  const [isDragOver, setIsDragOver] = useState(false);

  const take = (files: FileList | null) => {
    const f = files?.[0];
    if (f) onPick(f);
  };

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={() => inputRef.current?.click()}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          inputRef.current?.click();
        }
      }}
      onDragOver={(e) => {
        e.preventDefault();
        setIsDragOver(true);
      }}
      onDragLeave={(e) => {
        e.preventDefault();
        if (e.currentTarget.contains(e.relatedTarget as Node)) return;
        setIsDragOver(false);
      }}
      onDrop={(e) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragOver(false);
        take(e.dataTransfer.files);
      }}
      className={`border-2 border-dashed rounded-2xl p-6 text-center cursor-pointer transition-colors ${
        isDragOver
          ? 'border-blue-500 bg-blue-50'
          : 'border-slate-300 hover:border-blue-500 bg-slate-50/50 hover:bg-blue-50/30'
      }`}
    >
      <input
        ref={inputRef}
        type="file"
        accept=".pdf,.docx,.doc,.xlsx,.xls"
        className="hidden"
        onClick={(e) => e.stopPropagation()}
        onChange={(e) => {
          take(e.target.files);
          e.target.value = '';
        }}
      />
      {file ? (
        <div className="flex items-center justify-center gap-2 text-sm font-bold text-blue-700">
          <FileCheck className="w-5 h-5 text-blue-600" />
          <span className="truncate max-w-xs">{file.name}</span>
          <span className="text-xs text-slate-500 font-normal">({formatFileSize(file.size)})</span>
        </div>
      ) : (
        <div className="space-y-1">
          <Upload className="w-8 h-8 text-slate-400 mx-auto" />
          <div className="text-sm font-semibold text-slate-700">{emptyTitle}</div>
          <div className="text-xs text-slate-400">{emptyHint}</div>
        </div>
      )}
    </div>
  );
}

export default function DocumentsPage() {
  const { currentUser, isHR, isExecutive, isManager, isAdmin, can } = useAuth();
  const canUpload = isHR || isExecutive || isManager || isAdmin || can('DOCUMENT_UPLOAD');
  const canManage = canUpload;
  // ponytail: chỉ người đăng gốc (khớp uploaded_by) mới sửa/xóa; admin/executive chỉ cứu hộ tài liệu mồ côi
  const mine = (doc: KnowledgeDocument) =>
    !!currentUser?.fullName && !!doc.uploaded_by &&
    doc.uploaded_by.trim().toLowerCase() === currentUser.fullName.trim().toLowerCase();
  const canDelete = (doc: KnowledgeDocument) => isAdmin || mine(doc);

  const [documents, setDocuments] = useState<KnowledgeDocument[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [deptFilter, setDeptFilter] = useState<string>('ALL');
  // ponytail: lọc client-side trên list đã tải, khỏi API mới
  const [showMineOnly, setShowMineOnly] = useState(false);

  // Tab Mẫu đơn & Biểu mẫu (bảng documents — public toàn công ty, gate write bằng DOCUMENT_UPLOAD)
  const [activeTab, setActiveTab] = useState<'policy' | 'templates'>('policy');
  const [templates, setTemplates] = useState<TemplateDocument[]>([]);
  const [isTplLoading, setIsTplLoading] = useState(false);
  const [tplCategory, setTplCategory] = useState<string>('ALL');

  // Upload Modal State
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [uploadFile, setUploadFile] = useState<File | null>(null);
  // ponytail: mảng multi-scope, 'ALL' nghĩa là toàn công ty (backend join chuỗi phẩy)
  const [uploadDepts, setUploadDepts] = useState<string[]>(['ALL']);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Delete Confirm Modal State (thay confirm() native — đồng bộ design system của trang)
  const [deleteDoc, setDeleteDoc] = useState<KnowledgeDocument | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  // Update Modal State (thay file tại chỗ, giữ nguyên phạm vi phân quyền cũ)
  const [isUpdateModalOpen, setIsUpdateModalOpen] = useState(false);
  const [updateDoc, setUpdateDoc] = useState<KnowledgeDocument | null>(null);
  const [updateFile, setUpdateFile] = useState<File | null>(null);
  const [isUpdating, setIsUpdating] = useState(false);
  const updateFileInputRef = useRef<HTMLInputElement>(null);

  // Template modals (mẫu đơn): metadata nhập tay vì title/summary do người đăng đặt
  const [isTplUploadOpen, setIsTplUploadOpen] = useState(false);
  const [tplFile, setTplFile] = useState<File | null>(null);
  const [tplTitle, setTplTitle] = useState('');
  const [tplCat, setTplCat] = useState<TemplateCategory>('LEAVE');
  const [tplSummary, setTplSummary] = useState('');
  const [isTplSaving, setIsTplSaving] = useState(false);
  const tplInputRef = useRef<HTMLInputElement>(null);
  const [tplEdit, setTplEdit] = useState<TemplateDocument | null>(null);
  const [tplDelete, setTplDelete] = useState<TemplateDocument | null>(null);
  const [isTplDeleting, setIsTplDeleting] = useState(false);

  const handleTplSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const isEdit = !!tplEdit;
    if (!isEdit && !tplFile) {
      showToast('Vui lòng chọn file mẫu đơn (.pdf, .docx, .doc, .xlsx)', 'error');
      return;
    }
    if (!tplTitle.trim()) {
      showToast('Vui lòng nhập tiêu đề hiển thị', 'error');
      return;
    }
    const formData = new FormData();
    if (tplFile) formData.append('file', tplFile);
    formData.append('documentTitle', tplTitle.trim());
    formData.append('category', tplCat);
    formData.append('summary', tplSummary.trim());

    setIsTplSaving(true);
    try {
      if (isEdit && tplEdit) {
        await documentService.update(tplEdit.documentId, formData);
        showToast(`Đã cập nhật "${tplTitle.trim()}"!`, 'success');
      } else {
        await documentService.upload(formData);
        showToast(`Đã đăng mẫu đơn "${tplTitle.trim()}"!`, 'success');
      }
      setIsTplUploadOpen(false);
      setTplEdit(null);
      setTplFile(null);
      await fetchTemplates();
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi lưu mẫu đơn', 'error');
    } finally {
      setIsTplSaving(false);
    }
  };

  const openTplCreate = () => {
    setTplEdit(null);
    setTplFile(null);
    setTplTitle('');
    setTplCat('LEAVE');
    setTplSummary('');
    setIsTplUploadOpen(true);
  };

  const openTplEdit = (doc: TemplateDocument) => {
    setTplEdit(doc);
    setTplFile(null);
    setTplTitle(doc.documentTitle);
    setTplCat(doc.category);
    setTplSummary(doc.summary || '');
    setIsTplUploadOpen(true);
  };

  const handleTplConfirmDelete = async () => {
    if (!tplDelete) return;
    setIsTplDeleting(true);
    try {
      await documentService.delete(tplDelete.documentId);
      showToast(`Đã xóa mẫu đơn "${tplDelete.documentTitle}"!`, 'success');
      setTemplates((prev) => prev.filter((d) => d.documentId !== tplDelete.documentId));
      setTplDelete(null);
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi xóa mẫu đơn', 'error');
    } finally {
      setIsTplDeleting(false);
    }
  };

  // Toast Notification
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchDocuments = async () => {
    setIsLoading(true);
    try {
      const res = await aiService.getDocuments(deptFilter === 'ALL' ? undefined : deptFilter);
      if (res?.documents) {
        setDocuments(res.documents);
      } else {
        setDocuments([]);
      }
    } catch (err: any) {
      showToast(err.message || 'Không thể tải danh sách tài liệu', 'error');
      setDocuments([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDocuments();
  }, [deptFilter]);

  // ─── Mẫu đơn & Biểu mẫu ───
  const fetchTemplates = async () => {
    setIsTplLoading(true);
    try {
      const list = await documentService.list(tplCategory === 'ALL' ? undefined : tplCategory);
      setTemplates(Array.isArray(list) ? list : []);
    } catch (err: any) {
      showToast(err.message || 'Không thể tải danh sách mẫu đơn', 'error');
      setTemplates([]);
    } finally {
      setIsTplLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'templates') fetchTemplates();
  }, [activeTab, tplCategory]);

  const handleTplDownload = async (doc: TemplateDocument) => {
    try {
      showToast(`Đang chuẩn bị tải xuống "${doc.documentTitle}"...`, 'info');
      await documentService.download(doc);
      showToast(`Đã tải xuống "${doc.documentName}" thành công!`, 'success');
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi tải xuống file', 'error');
    }
  };

  const filteredTemplates = templates.filter((doc) => {
    const q = searchTerm.toLowerCase();
    return !q
      || doc.documentTitle.toLowerCase().includes(q)
      || (doc.summary && doc.summary.toLowerCase().includes(q))
      || (doc.uploaderName && doc.uploaderName.toLowerCase().includes(q));
  });

  // Handle Download
  const handleDownload = async (doc: KnowledgeDocument) => {
    try {
      showToast(`Đang chuẩn bị tải xuống "${doc.file_name}"...`, 'info');
      await aiService.downloadDocument(doc.id, doc.file_name);
      showToast(`Đã tải xuống "${doc.file_name}" thành công!`, 'success');
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi tải xuống file', 'error');
    }
  };

  // Handle Delete (2 bước: bấm thùng rác mở modal xác nhận → bấm "Xóa vĩnh viễn" mới xóa thật)
  const handleDelete = (doc: KnowledgeDocument) => {
    setDeleteDoc(doc);
  };

  const handleConfirmDelete = async () => {
    if (!deleteDoc) return;
    setIsDeleting(true);
    try {
      await aiService.deleteDocument(deleteDoc.id);
      showToast(`Đã xóa tài liệu "${deleteDoc.file_name}"!`, 'success');
      setDocuments((prev) => prev.filter((d) => d.id !== deleteDoc.id));
      setDeleteDoc(null);
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi xóa tài liệu', 'error');
    } finally {
      setIsDeleting(false);
    }
  };

  // Handle Update (thay file tại chỗ — không gửi allowedDepartments để backend giữ phạm vi cũ)
  const openUpdateModal = (doc: KnowledgeDocument) => {
    setUpdateDoc(doc);
    setUpdateFile(null);
    setIsUpdateModalOpen(true);
  };

  const handleUpdateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!updateDoc || !updateFile) {
      showToast('Vui lòng chọn file thay thế (.pdf, .docx, .doc, .xlsx)', 'error');
      return;
    }
    const formData = new FormData();
    formData.append('file', updateFile);

    setIsUpdating(true);
    try {
      await aiService.updateDocument(updateDoc.id, formData);
      showToast(`Đã cập nhật "${updateFile.name}"! AI đang xử lý lại nội dung.`, 'success');
      setIsUpdateModalOpen(false);
      setUpdateDoc(null);
      setUpdateFile(null);
      await fetchDocuments();
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi cập nhật tài liệu', 'error');
    } finally {
      setIsUpdating(false);
    }
  };

  // Handle Upload
  const handleUploadSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!uploadFile) {
      showToast('Vui lòng chọn file văn bản (.pdf, .docx, .doc, .xlsx)', 'error');
      return;
    }

    const formData = new FormData();
    formData.append('file', uploadFile);
    formData.append('allowedDepartments', uploadDepts.length > 0 ? uploadDepts.join(',') : 'ALL');

    setIsUploading(true);
    try {
      await aiService.uploadDocument(formData);
      showToast(`Đã tải lên "${uploadFile.name}" thành công! AI đang đọc và xử lý nội dung.`, 'success');
      setIsUploadModalOpen(false);
      setUploadFile(null);
      await fetchDocuments();
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi tải lên tài liệu', 'error');
    } finally {
      setIsUploading(false);
    }
  };

  // Filtered documents
  const filteredDocuments = documents.filter((doc) => {
    if (showMineOnly && !mine(doc)) return false;
    const matchesSearch = doc.file_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (doc.uploaded_by && doc.uploaded_by.toLowerCase().includes(searchTerm.toLowerCase()));
    return matchesSearch;
  });

  const getFileIcon = (fileType: string) => {
    const type = fileType?.toLowerCase() || '';
    if (type.includes('pdf')) {
      return <FileText className="w-6 h-6 text-rose-600" />;
    }
    if (type.includes('doc') || type.includes('word')) {
      return <FileCheck className="w-6 h-6 text-blue-600" />;
    }
    if (type.includes('xls') || type.includes('sheet') || type.includes('csv')) {
      return <FileSpreadsheet className="w-6 h-6 text-emerald-600" />;
    }
    return <File className="w-6 h-6 text-indigo-600" />;
  };

  // ponytail: trang đơn nội dung — bỏ sidemenu 1 mục thừa, full-width
  return (
    <AppShell noSidebar>
      <div
        className="space-y-6 pb-12"
        onDragOver={(e) => e.preventDefault()}
        onDrop={(e) => e.preventDefault()}
      >
        {/* Toast Notification */}
        {toast && (
          <div className="fixed bottom-6 right-6 z-50 animate-in fade-in slide-in-from-bottom-5 duration-300">
            <div className={`flex items-center gap-3 px-4 py-3 rounded-xl shadow-xl border text-sm font-medium ${
              toast.type === 'success' 
                ? 'bg-emerald-50 text-emerald-900 border-emerald-200' 
                : toast.type === 'error'
                ? 'bg-rose-50 text-rose-900 border-rose-200'
                : 'bg-blue-50 text-blue-900 border-blue-200'
            }`}>
              {toast.type === 'success' && <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />}
              {toast.type === 'error' && <AlertTriangle className="w-5 h-5 text-rose-600 shrink-0" />}
              {toast.type === 'info' && <Sparkles className="w-5 h-5 text-blue-600 shrink-0" />}
              <span>{toast.message}</span>
            </div>
          </div>
        )}

        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h1 className="text-2xl font-black tracking-tight text-slate-900">
              {activeTab === 'policy' ? 'Tài liệu & Quy chế' : 'Mẫu đơn & Biểu mẫu'}
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              {activeTab === 'policy'
                ? 'Tra cứu chính sách nội bộ, quy chế lao động và tài liệu hướng dẫn.'
                : 'Tải biểu mẫu đơn xin nghỉ, nghỉ việc, hợp đồng và biên bản dùng chung toàn công ty.'}
            </p>
          </div>
          {canManage && (
            <button
              onClick={() => (activeTab === 'policy' ? setIsUploadModalOpen(true) : openTplCreate())}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-md transition-all cursor-pointer shrink-0"
            >
              <Plus className="w-4 h-4" />
              <span>{activeTab === 'policy' ? 'Nạp tài liệu mới' : 'Đăng mẫu đơn mới'}</span>
            </button>
          )}
        </div>

        {/* Tabs: Quy chế (RAG) | Mẫu đơn (bảng documents) */}
        <div className="flex items-center gap-1 p-1 rounded-xl bg-slate-100 border border-slate-200/80 w-fit">
          {([
            { key: 'policy', label: 'Tài liệu & Quy chế' },
            { key: 'templates', label: `Mẫu đơn & Biểu mẫu${templates.length ? ` (${templates.length})` : ''}` },
          ] as const).map((t) => (
            <button
              key={t.key}
              onClick={() => setActiveTab(t.key)}
              aria-pressed={activeTab === t.key}
              className={`px-4 py-2 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                activeTab === t.key
                  ? 'bg-white text-blue-700 shadow-sm border border-slate-200/80'
                  : 'text-slate-500 hover:text-slate-700'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        {/* Filter and Search Bar */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-4 shadow-xs space-y-3">
          <div className="flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between">
            {/* Search Input */}
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder={activeTab === 'policy' ? 'Tìm kiếm theo tên tài liệu, người tải lên...' : 'Tìm kiếm theo tiêu đề, nội dung tóm tắt, người đăng...'}
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-800 placeholder-slate-400"
              />
              {searchTerm && (
                <button
                  onClick={() => setSearchTerm('')}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 text-xs px-1.5 py-0.5 rounded-full"
                >
                  ✕
                </button>
              )}
            </div>

            {/* Department Filter (backend là nguồn chân lý cho phạm vi) */}
            <div className="flex items-center gap-2">
              {activeTab === 'policy' ? (
                <>
                  {canUpload && (
                    <button
                      onClick={() => setShowMineOnly(v => !v)}
                      title="Chỉ hiện tài liệu do chính bạn đăng"
                      aria-pressed={showMineOnly}
                      className={`px-3 py-2.5 rounded-xl border text-xs sm:text-sm font-bold transition-all cursor-pointer shrink-0 ${
                        showMineOnly
                          ? 'bg-blue-600 border-blue-600 text-white shadow-md'
                          : 'border-slate-200 text-slate-600 hover:text-blue-600 hover:bg-slate-50'
                      }`}
                    >
                      Của tôi
                    </button>
                  )}
                  <span className="text-xs font-semibold text-slate-500 shrink-0 hidden sm:inline">Phòng ban:</span>
                  <select
                    value={deptFilter}
                    onChange={(e) => setDeptFilter(e.target.value)}
                    className="px-3 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm font-medium text-slate-700 bg-white focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all cursor-pointer"
                  >
                    <option value="ALL">Toàn công ty (Tất cả)</option>
                    {DEPARTMENTS.map(d => (
                      <option key={d.value} value={d.value}>{d.label}</option>
                    ))}
                  </select>

                  <button
                    onClick={fetchDocuments}
                    title="Làm mới danh sách"
                    className="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:text-blue-600 hover:bg-slate-50 transition-colors cursor-pointer shrink-0"
                  >
                    <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin text-blue-600' : ''}`} />
                  </button>
                </>
              ) : (
                <>
                  <span className="text-xs font-semibold text-slate-500 shrink-0 hidden sm:inline">Nhóm đơn:</span>
                  <select
                    value={tplCategory}
                    onChange={(e) => setTplCategory(e.target.value)}
                    className="px-3 py-2.5 rounded-xl border border-slate-200 text-xs sm:text-sm font-medium text-slate-700 bg-white focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all cursor-pointer"
                  >
                    <option value="ALL">Tất cả nhóm đơn</option>
                    {(Object.keys(TEMPLATE_CATEGORY_LABELS) as TemplateCategory[]).map((c) => (
                      <option key={c} value={c}>{TEMPLATE_CATEGORY_LABELS[c]}</option>
                    ))}
                  </select>

                  <button
                    onClick={fetchTemplates}
                    title="Làm mới danh sách"
                    className="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:text-blue-600 hover:bg-slate-50 transition-colors cursor-pointer shrink-0"
                  >
                    <RefreshCw className={`w-4 h-4 ${isTplLoading ? 'animate-spin text-blue-600' : ''}`} />
                  </button>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Documents Grid */}
        {activeTab === 'policy' && (
        <>
        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="bg-white rounded-2xl border border-slate-200/80 p-5 space-y-4 animate-pulse">
                <div className="flex items-center justify-between">
                  <div className="w-12 h-12 bg-slate-100 rounded-xl" />
                  <div className="w-24 h-6 bg-slate-100 rounded-full" />
                </div>
                <div className="space-y-2">
                  <div className="h-4 bg-slate-100 rounded-md w-3/4" />
                  <div className="h-3 bg-slate-100 rounded-md w-1/2" />
                </div>
                <div className="pt-3 border-t border-slate-100 flex justify-between">
                  <div className="h-8 bg-slate-100 rounded-lg w-24" />
                  <div className="h-8 bg-slate-100 rounded-lg w-20" />
                </div>
              </div>
            ))}
          </div>
        ) : filteredDocuments.length === 0 ? (
          <div className="bg-white rounded-2xl border border-slate-200/80 p-12 text-center space-y-4">
            <div className="w-16 h-16 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mx-auto">
              <FolderOpen className="w-8 h-8" />
            </div>
            <div className="max-w-md mx-auto space-y-1">
              <h3 className="text-base font-bold text-slate-900">Không tìm thấy tài liệu phù hợp</h3>
              <p className="text-sm text-slate-500">
                {showMineOnly
                  ? 'Bạn chưa đăng tài liệu nào trong phạm vi này. Bấm "Nạp tài liệu mới" để đăng tài liệu đầu tiên.'
                  : searchTerm
                  ? 'Thử thay đổi từ khóa tìm kiếm để xem thêm tài liệu.'
                  : 'Chưa có tài liệu nào được nạp vào cơ sở tri thức cho phạm vi phòng ban này.'}
              </p>
            </div>
            {canManage && (
              <button
                onClick={() => setIsUploadModalOpen(true)}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold transition-all cursor-pointer shadow-sm"
              >
                <Plus className="w-4 h-4" />
                <span>Tải lên tài liệu đầu tiên</span>
              </button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {filteredDocuments.map((doc) => {
              const depts = doc.allowed_departments && doc.allowed_departments.length > 0 
                ? doc.allowed_departments 
                : ['ALL'];
              const isAllDepts = depts.includes('ALL');

              return (
                <div
                  key={doc.id}
                  className="bg-white rounded-2xl border border-slate-200/80 hover:border-blue-300 hover:shadow-md transition-all p-5 flex flex-col justify-between group"
                >
                  <div className="space-y-3">
                    {/* File Name */}
                    <div className="flex items-start gap-3">
                      <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 shrink-0 group-hover:scale-105 transition-transform">
                        {getFileIcon(doc.file_type)}
                      </div>
                      <h3
                        className="font-bold text-slate-900 text-sm leading-snug line-clamp-2 pt-1"
                        title={doc.file_name}
                      >
                        {doc.file_name}
                      </h3>
                    </div>
                    {doc.error_message && doc.status === 'FAILED' && (
                      <div className="text-[11px] text-rose-600">{doc.error_message}</div>
                    )}

                    {/* Meta details */}
                    <div className="text-xs text-slate-500 space-y-1 pt-1">
                      <div className="flex items-center justify-between">
                        <span>Người tải lên:</span>
                        <span className="font-semibold text-slate-700 truncate max-w-[140px]">{doc.uploaded_by || 'Hệ thống'}</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Ngày nạp:</span>
                        <span className="font-medium text-slate-600">
                          {doc.created_at ? formatDateVN(doc.created_at) : 'Mới'}
                        </span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Phạm vi:</span>
                        <span className="font-semibold text-slate-700">{isAllDepts ? 'Toàn công ty' : depts.join(', ')}</span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span>Dung lượng:</span>
                        <span className="font-semibold text-slate-700">{formatFileSize(doc.file_size)}</span>
                      </div>
                    </div>
                  </div>

                  {/* Actions Footer */}
                  <div className="pt-4 mt-4 border-t border-slate-100 flex items-center justify-between gap-2">
                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => handleDownload(doc)}
                        title="Tải xuống tài liệu gốc"
                        className="p-2 rounded-xl text-slate-600 hover:text-blue-600 hover:bg-blue-50 transition-colors cursor-pointer border border-slate-200/80"
                      >
                        <Download className="w-4 h-4" />
                      </button>
                    </div>

                    <div className="flex items-center gap-1.5">
                      {canDelete(doc) && (
                        <>
                          <button
                            onClick={() => openUpdateModal(doc)}
                            title={mine(doc) ? "Cập nhật file mới cho tài liệu này" : "Cập nhật hộ (quyền quản trị — tài liệu mồ côi)"}
                            className="p-2 rounded-xl text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-colors cursor-pointer"
                          >
                            <Pencil className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(doc)}
                            title={mine(doc) ? "Xóa tài liệu khỏi tri thức AI" : "Xóa hộ (quyền quản trị — tài liệu mồ côi)"}
                            className="p-2 rounded-xl text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
        </>
        )}

        {/* Template Grid: hiện tiêu đề + tóm tắt, ẩn tên file (chỉ dùng lúc tải xuống) */}
        {activeTab === 'templates' && (
        <>
        {isTplLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="bg-white rounded-2xl border border-slate-200/80 p-5 space-y-4 animate-pulse">
                <div className="h-4 bg-slate-100 rounded-md w-3/4" />
                <div className="h-3 bg-slate-100 rounded-md w-full" />
                <div className="h-3 bg-slate-100 rounded-md w-1/2" />
              </div>
            ))}
          </div>
        ) : filteredTemplates.length === 0 ? (
          <div className="bg-white rounded-2xl border border-slate-200/80 p-12 text-center space-y-4">
            <div className="w-16 h-16 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center mx-auto">
              <FolderOpen className="w-8 h-8" />
            </div>
            <div className="max-w-md mx-auto space-y-1">
              <h3 className="text-base font-bold text-slate-900">Không tìm thấy mẫu đơn phù hợp</h3>
              <p className="text-sm text-slate-500">
                {searchTerm
                  ? 'Thử thay đổi từ khóa tìm kiếm để xem thêm mẫu đơn.'
                  : 'Chưa có mẫu đơn nào trong nhóm này.'}
              </p>
            </div>
            {canManage && (
              <button
                onClick={openTplCreate}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold transition-all cursor-pointer shadow-sm"
              >
                <Plus className="w-4 h-4" />
                <span>Đăng mẫu đơn đầu tiên</span>
              </button>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {filteredTemplates.map((doc) => (
              <div
                key={doc.documentId}
                className="bg-white rounded-2xl border border-slate-200/80 hover:border-blue-300 hover:shadow-md transition-all p-5 flex flex-col justify-between group"
              >
                <div className="space-y-3">
                  <div className="flex items-start gap-3">
                    <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 shrink-0 group-hover:scale-105 transition-transform">
                      {getFileIcon(doc.fileType)}
                    </div>
                    <div className="min-w-0 pt-0.5">
                      <h3
                        className="font-bold text-slate-900 text-sm leading-snug line-clamp-2"
                        title={doc.documentTitle}
                      >
                        {doc.documentTitle}
                      </h3>
                      <span className="inline-block mt-1.5 px-2 py-0.5 rounded-full bg-blue-50 text-blue-700 text-[11px] font-bold">
                        {doc.categoryLabel || TEMPLATE_CATEGORY_LABELS[doc.category]} • {doc.fileType}
                      </span>
                    </div>
                  </div>
                  {doc.summary && (
                    <p className="text-xs text-slate-500 leading-relaxed line-clamp-3" title={doc.summary}>
                      {doc.summary}
                    </p>
                  )}

                  <div className="text-xs text-slate-500 space-y-1 pt-1">
                    <div className="flex items-center justify-between">
                      <span>Người đăng:</span>
                      <span className="font-semibold text-slate-700 truncate max-w-[140px]">{doc.uploaderName || 'Hệ thống'}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span>Ngày đăng:</span>
                      <span className="font-medium text-slate-600">
                        {doc.createdAt ? formatDateVN(doc.createdAt) : 'Mới'}
                      </span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span>Dung lượng:</span>
                      <span className="font-semibold text-slate-700">{formatFileSize(doc.fileSize)}</span>
                    </div>
                  </div>
                </div>

                <div className="pt-4 mt-4 border-t border-slate-100 flex items-center justify-between gap-2">
                  <button
                    onClick={() => handleTplDownload(doc)}
                    title={`Tải xuống ${doc.documentName}`}
                    className="p-2 rounded-xl text-slate-600 hover:text-blue-600 hover:bg-blue-50 transition-colors cursor-pointer border border-slate-200/80"
                  >
                    <Download className="w-4 h-4" />
                  </button>

                  {canManage && (
                    <div className="flex items-center gap-1.5">
                      <button
                        onClick={() => openTplEdit(doc)}
                        title="Sửa tiêu đề, nhóm hoặc thay file"
                        className="p-2 rounded-xl text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-colors cursor-pointer"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => setTplDelete(doc)}
                        title="Xóa mẫu đơn"
                        className="p-2 rounded-xl text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
        </>
        )}

        {/* Modal: Tải lên tài liệu mới */}
        {isUploadModalOpen && (
          <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
              <div className="flex items-center justify-between pb-4 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-orange-50 text-orange-600">
                    <Upload className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-lg font-extrabold text-slate-900">Nạp tài liệu mới</h3>
                    <p className="text-xs text-slate-500">Hệ thống tự động đọc nội dung để phục vụ tra cứu</p>
                  </div>
                </div>
                <button
                  onClick={() => setIsUploadModalOpen(false)}
                  className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleUploadSubmit} className="space-y-4 pt-4">
                {/* File picker */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                    Tệp đính kèm (.PDF, .DOCX, .DOC, .XLSX)
                  </label>
                  <FileDropzone
                    inputRef={fileInputRef}
                    file={uploadFile}
                    onPick={setUploadFile}
                    emptyTitle="Nhấp để duyệt file hoặc kéo thả vào đây"
                    emptyHint="Dung lượng tối đa khuyến nghị: 25MB"
                  />
                </div>

                {/* Scope Selection: đa chọn, backend đã hỗ trợ chuỗi phẩy */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                    Phạm vi phân quyền truy cập
                  </label>
                  <div className="rounded-xl border border-slate-200 p-3 space-y-1.5 max-h-48 overflow-y-auto">
                    <label className="flex items-center gap-2.5 text-sm font-semibold text-slate-800 cursor-pointer hover:bg-slate-50 rounded-lg px-2 py-1.5">
                      <input
                        type="checkbox"
                        checked={uploadDepts.includes('ALL')}
                        onChange={() => setUploadDepts(['ALL'])}
                        className="h-4 w-4 rounded accent-blue-600 cursor-pointer"
                      />
                      <span>Toàn công ty (Tất cả nhân viên đều xem được)</span>
                    </label>
                    {DEPARTMENTS.filter(d =>
                      (isExecutive || isAdmin || isHR) ||
                      ((isManager || can('DOCUMENT_UPLOAD')) && currentUser?.department && (d.value === currentUser.department || d.dbName === currentUser.department))
                    ).map(d => (
                      <label key={d.value} className="flex items-center gap-2.5 text-sm text-slate-700 cursor-pointer hover:bg-slate-50 rounded-lg px-2 py-1.5">
                        <input
                          type="checkbox"
                          checked={uploadDepts.includes(d.value)}
                          onChange={() => setUploadDepts(prev => {
                            const withoutAll = prev.filter(v => v !== 'ALL');
                            return withoutAll.includes(d.value)
                              ? withoutAll.filter(v => v !== d.value)
                              : [...withoutAll, d.value];
                          })}
                          className="h-4 w-4 rounded accent-blue-600 cursor-pointer"
                        />
                        <span>{d.label}</span>
                      </label>
                    ))}
                  </div>
                  <p className="text-[11px] text-slate-500 mt-1">
                    * Nhân viên thuộc phòng ban ngoài phạm vi này sẽ không thể tra cứu hoặc truy xuất nội dung tài liệu.
                  </p>
                </div>

                {/* Notice Box */}
                <div className="p-3 rounded-xl bg-blue-50 border border-blue-100 text-xs text-blue-800 space-y-1">
                  <div className="flex items-center gap-1.5 font-bold">
                    <ShieldCheck className="w-4 h-4 text-blue-600" />
                    <span>Quy trình xử lý tự động:</span>
                  </div>
                    <ul className="list-disc list-inside space-y-0.5 text-blue-700 text-[11px]">
                      <li>Tự động đọc toàn bộ nội dung và bảng biểu</li>
                      <li>Tóm tắt nội dung để trả lời câu hỏi nhanh</li>
                    </ul>
                </div>

                {/* Actions */}
                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => {
                      setIsUploadModalOpen(false);
                      setUploadFile(null);
                    }}
                    className="px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-semibold text-slate-600 hover:bg-slate-50 transition-colors cursor-pointer"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={isUploading || !uploadFile}
                    className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white text-sm font-bold shadow-md shadow-blue-500/20 transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isUploading ? (
                      <>
                        <RefreshCw className="w-4 h-4 animate-spin" />
                        <span>Đang xử lý...</span>
                      </>
                    ) : (
                      <>
                        <Upload className="w-4 h-4" />
                        <span>Bắt đầu nạp tài liệu</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Modal: Xác nhận xóa tài liệu (hành động hủy diệt — nêu tên file + hậu quả + nút đỏ) */}
        {deleteDoc && (
          <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
              <div className="flex items-start gap-3">
                <div className="p-2.5 rounded-xl bg-rose-50 text-rose-600 shrink-0">
                  <AlertTriangle className="w-5 h-5" />
                </div>
                <div className="min-w-0">
                  <h3 className="text-base font-extrabold text-slate-900">Xóa tài liệu này?</h3>
                  <p className="text-sm font-semibold text-slate-700 truncate mt-0.5" title={deleteDoc.file_name}>
                    {deleteDoc.file_name}
                  </p>
                </div>
              </div>
              <p className="text-xs text-slate-500 mt-3 leading-relaxed">
                Hành động này sẽ xóa vĩnh viễn tài liệu cùng toàn bộ{' '}
                <span className="font-bold text-slate-700">{deleteDoc.chunk_count} đoạn nội dung</span>{' '}
                liên quan trong cơ sở tri thức AI. Không thể khôi phục.
              </p>
              <div className="flex items-center justify-end gap-3 pt-4 mt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => !isDeleting && setDeleteDoc(null)}
                  disabled={isDeleting}
                  className="px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-semibold text-slate-600 hover:bg-slate-50 transition-colors cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Hủy
                </button>
                <button
                  type="button"
                  onClick={handleConfirmDelete}
                  disabled={isDeleting}
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 active:bg-rose-800 text-white text-sm font-bold shadow-md shadow-rose-500/20 transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isDeleting ? (
                    <>
                      <RefreshCw className="w-4 h-4 animate-spin" />
                      <span>Đang xóa...</span>
                    </>
                  ) : (
                    <>
                      <Trash2 className="w-4 h-4" />
                      <span>Xóa vĩnh viễn</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal: Cập nhật file tài liệu (giữ nguyên phạm vi phân quyền cũ) */}
        {isUpdateModalOpen && updateDoc && (
          <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
              <div className="flex items-center justify-between pb-4 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-blue-50 text-blue-600">
                    <Pencil className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-lg font-extrabold text-slate-900">Cập nhật tài liệu</h3>
                    <p className="text-xs text-slate-500 truncate max-w-xs">{updateDoc.file_name}</p>
                  </div>
                </div>
                <button
                  onClick={() => { setIsUpdateModalOpen(false); setUpdateDoc(null); setUpdateFile(null); }}
                  className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleUpdateSubmit} className="space-y-4 pt-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                    File thay thế (.PDF, .DOCX, .DOC, .XLSX)
                  </label>
                  <FileDropzone
                    inputRef={updateFileInputRef}
                    file={updateFile}
                    onPick={setUpdateFile}
                    emptyTitle="Nhấp để chọn file thay thế"
                    emptyHint="Phạm vi phân quyền cũ được giữ nguyên"
                  />
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => { setIsUpdateModalOpen(false); setUpdateDoc(null); setUpdateFile(null); }}
                    className="px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-semibold text-slate-600 hover:bg-slate-50 transition-colors cursor-pointer"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={isUpdating || !updateFile}
                    className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white text-sm font-bold shadow-md shadow-blue-500/20 transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isUpdating ? (
                      <>
                        <RefreshCw className="w-4 h-4 animate-spin" />
                        <span>Đang cập nhật...</span>
                      </>
                    ) : (
                      <>
                        <Pencil className="w-4 h-4" />
                        <span>Xác nhận cập nhật</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Modal: Đăng / Sửa mẫu đơn (tiêu đề + nhóm + tóm tắt do người đăng đặt) */}
        {isTplUploadOpen && (
          <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
              <div className="flex items-center justify-between pb-4 border-b border-slate-100">
                <div className="flex items-center gap-3">
                  <div className="p-2.5 rounded-xl bg-orange-50 text-orange-600">
                    <Upload className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="text-lg font-extrabold text-slate-900">
                      {tplEdit ? 'Sửa mẫu đơn' : 'Đăng mẫu đơn mới'}
                    </h3>
                    <p className="text-xs text-slate-500">Hiển thị cho toàn công ty</p>
                  </div>
                </div>
                <button
                  onClick={() => { setIsTplUploadOpen(false); setTplEdit(null); setTplFile(null); }}
                  className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleTplSubmit} className="space-y-4 pt-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                    Tệp mẫu đơn (.PDF, .DOCX, .DOC, .XLSX){tplEdit && ' — để trống nếu giữ file cũ'}
                  </label>
                  <FileDropzone
                    inputRef={tplInputRef}
                    file={tplFile}
                    onPick={setTplFile}
                    emptyTitle="Nhấp để duyệt file hoặc kéo thả vào đây"
                    emptyHint="Dung lượng tối đa: 10MB"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                    Tiêu đề hiển thị
                  </label>
                  <input
                    type="text"
                    value={tplTitle}
                    onChange={(e) => setTplTitle(e.target.value)}
                    placeholder="VD: Đơn xin nghỉ phép năm"
                    maxLength={255}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-800 placeholder-slate-400"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                    Nhóm đơn
                  </label>
                  <select
                    value={tplCat}
                    onChange={(e) => setTplCat(e.target.value as TemplateCategory)}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-medium text-slate-700 bg-white focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all cursor-pointer"
                  >
                    {(Object.keys(TEMPLATE_CATEGORY_LABELS) as TemplateCategory[]).map((c) => (
                      <option key={c} value={c}>{TEMPLATE_CATEGORY_LABELS[c]}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                    Tóm tắt nội dung
                  </label>
                  <textarea
                    value={tplSummary}
                    onChange={(e) => setTplSummary(e.target.value)}
                    placeholder="Mô tả ngắn gọn để nhân viên tìm đúng mẫu đơn..."
                    rows={3}
                    maxLength={2000}
                    className="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-slate-800 placeholder-slate-400 resize-none"
                  />
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => { setIsTplUploadOpen(false); setTplEdit(null); setTplFile(null); }}
                    className="px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-semibold text-slate-600 hover:bg-slate-50 transition-colors cursor-pointer"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={isTplSaving || (!tplEdit && !tplFile)}
                    className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 active:bg-blue-800 text-white text-sm font-bold shadow-md shadow-blue-500/20 transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isTplSaving ? (
                      <>
                        <RefreshCw className="w-4 h-4 animate-spin" />
                        <span>Đang lưu...</span>
                      </>
                    ) : (
                      <>
                        <Upload className="w-4 h-4" />
                        <span>{tplEdit ? 'Xác nhận sửa' : 'Đăng mẫu đơn'}</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Modal: Xác nhận xóa mẫu đơn */}
        {tplDelete && (
          <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-200">
              <div className="flex items-start gap-3">
                <div className="p-2.5 rounded-xl bg-rose-50 text-rose-600 shrink-0">
                  <AlertTriangle className="w-5 h-5" />
                </div>
                <div className="min-w-0">
                  <h3 className="text-base font-extrabold text-slate-900">Xóa mẫu đơn này?</h3>
                  <p className="text-sm font-semibold text-slate-700 truncate mt-0.5" title={tplDelete.documentTitle}>
                    {tplDelete.documentTitle}
                  </p>
                </div>
              </div>
              <p className="text-xs text-slate-500 mt-3 leading-relaxed">
                Mẫu đơn sẽ bị ẩn khỏi trang. File gốc vẫn giữ trên máy chủ.
              </p>
              <div className="flex items-center justify-end gap-3 pt-4 mt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => !isTplDeleting && setTplDelete(null)}
                  disabled={isTplDeleting}
                  className="px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-semibold text-slate-600 hover:bg-slate-50 transition-colors cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Hủy
                </button>
                <button
                  type="button"
                  onClick={handleTplConfirmDelete}
                  disabled={isTplDeleting}
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-700 active:bg-rose-800 text-white text-sm font-bold shadow-md shadow-rose-500/20 transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isTplDeleting ? (
                    <>
                      <RefreshCw className="w-4 h-4 animate-spin" />
                      <span>Đang xóa...</span>
                    </>
                  ) : (
                    <>
                      <Trash2 className="w-4 h-4" />
                      <span>Xóa mẫu đơn</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}

      </div>
    </AppShell>
  );
}
