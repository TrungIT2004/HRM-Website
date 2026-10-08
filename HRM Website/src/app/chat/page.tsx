'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import AppShell from '@/components/layout/AppShell';
import { useAuth } from '@/context/AuthContext';
import { DEPARTMENTS } from '@/constants/departments';
import { 
  aiService, 
  ChatMessage, 
  ConversationSummary, 
  Citation,
  KnowledgeDocument 
} from '@/services/aiService';
import {
  Sparkles,
  Plus,
  Trash2,
  Send,
  Bot,
  User,
  FileText,
  MessageSquare,
  Loader2,
  Clock,
  ShieldCheck,
  Menu,
  X,
  Upload,
  FolderOpen,
  Download,
  AlertCircle,
  CheckCircle2,
  ChevronRight,
  MoreVertical,
  Pin,
  PinOff,
  Pencil,
  Check
} from 'lucide-react';

/**
 * Render markdown cơ bản của LLM: **đậm**, gạch đầu dòng "- ", tiêu đề "### ",
 * và ngắt dòng đơn. Dựng thẳng React element, KHÔNG dangerouslySetInnerHTML
 * → không cần sanitize, không thêm dependency markdown.
 * ponytail: đủ dùng cho output hiện tại; nếu LLM bắt đầu xuất bảng/link/code block
 * thì thay bằng react-markdown + rehype-sanitize.
 */
function MarkdownLite({ text }: { text: string }) {
  const blocks: React.ReactNode[] = [];
  let bullets: string[] = [];

  const flushBullets = () => {
    if (!bullets.length) return;
    blocks.push(
      <ul key={`ul-${blocks.length}`} className="my-1.5 list-disc pl-4 space-y-0.5">
        {bullets.map((b, i) => (
          <li key={i}><Inline text={b} /></li>
        ))}
      </ul>
    );
    bullets = [];
  };

  text.split('\n').forEach((raw, i) => {
    const line = raw.trimEnd();
    if (/^\s*[-*]\s+/.test(line)) {
      bullets.push(line.replace(/^\s*[-*]\s+/, ''));
      return;
    }
    flushBullets();
    if (!line.trim()) return;
    if (/^#{1,6}\s+/.test(line)) {
      const level = line.match(/^#+/)![0].length;
      blocks.push(
        <p key={i} className={`mt-2 mb-1 font-bold ${level <= 2 ? 'text-sm' : ''}`}>
          <Inline text={line.replace(/^#{1,6}\s+/, '')} />
        </p>
      );
      return;
    }
    blocks.push(
      <p key={i} className="whitespace-pre-wrap my-1">
        <Inline text={line} />
      </p>
    );
  });
  flushBullets();

  return <div>{blocks}</div>;
}

/** Chỉ xử lý **đậm** và `code` — thứ LLM hay dùng nhất trong câu trả lời. */
function Inline({ text }: { text: string }) {
  const parts = text.split(/(\*\*[^*]+\*\*|`[^`]+`)/g);
  return (
    <>
      {parts.map((p, i) => {
        if (p.startsWith('**') && p.endsWith('**') && p.length > 4) {
          return <strong key={i} className="font-bold">{p.slice(2, -2)}</strong>;
        }
        if (p.startsWith('`') && p.endsWith('`') && p.length > 2) {
          return <code key={i} className="rounded bg-slate-200/70 px-1 py-0.5 font-mono text-[0.9em]">{p.slice(1, -1)}</code>;
        }
        return <span key={i}>{p}</span>;
      })}
    </>
  );
}

export default function ChatPage() {
  const { currentUser, isHR, isExecutive, isManager } = useAuth();

  const [conversations, setConversations] = useState<ConversationSummary[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isFetchingHistory, setIsFetchingHistory] = useState(false);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Document Management Modal for HR / Manager / Executive
  const [isDocModalOpen, setIsDocModalOpen] = useState(false);
  const [documents, setDocuments] = useState<KnowledgeDocument[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadDept, setUploadDept] = useState<string>('ALL');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [toastMsg, setToastMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMsg({ text, type });
    setTimeout(() => setToastMsg(null), 4000);
  };

  const fetchConversations = async () => {
    try {
      const res = await aiService.getConversations();
      if (res?.conversations) {
        const sorted = [...res.conversations].sort((a, b) => (b.is_pinned ? 1 : 0) - (a.is_pinned ? 1 : 0));
        setConversations(sorted);
      }
    } catch {
      // Backend might still be warming up
    }
  };

  useEffect(() => {
    fetchConversations();
  }, []);

  const loadConversation = async (id: string) => {
    setActiveId(id);
    setIsFetchingHistory(true);
    setIsHistoryOpen(false);
    try {
      const res = await aiService.getConversationMessages(id);
      if (res?.messages) {
        setMessages(
          res.messages.map((m: any) => ({
            id: m.id || String(Math.random()),
            sender_role: m.sender_role === 'USER' || m.sender_role === 'user' ? 'user' : 'assistant',
            content: m.content,
            citations: m.citations || [],
            confidence: m.confidence || 'HIGH'
          }))
        );
      }
    } catch {
      setMessages([
        {
          id: 'err',
          sender_role: 'assistant',
          content: 'Không thể tải lịch sử cuộc trò chuyện này.',
        },
      ]);
    } finally {
      setIsFetchingHistory(false);
    }
  };

  const startNewChat = () => {
    setActiveId(null);
    setMessages([]);
    setInput('');
    setIsHistoryOpen(false);
  };

  const [openMenuId, setOpenMenuId] = useState<string | null>(null);
  const [editingConvId, setEditingConvId] = useState<string | null>(null);
  const [editingTitle, setEditingTitle] = useState('');

  // Close 3-dots action menu when clicking outside
  useEffect(() => {
    const handleClickOutside = () => setOpenMenuId(null);
    window.addEventListener('click', handleClickOutside);
    return () => window.removeEventListener('click', handleClickOutside);
  }, []);

  const deleteConv = async (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    try {
      await aiService.deleteConversation(id);
      setConversations((prev) => prev.filter((c) => c.id !== id));
      if (activeId === id) startNewChat();
      showToast('Đã xóa cuộc trò chuyện!', 'success');
    } catch {
      showToast('Lỗi khi xóa cuộc trò chuyện', 'error');
    }
  };

  const handleTogglePin = async (id: string, currentPinned: boolean) => {
    try {
      setOpenMenuId(null);
      const newPinned = !currentPinned;
      await aiService.pinConversation(id, newPinned);
      setConversations((prev) =>
        prev
          .map((c) => (c.id === id ? { ...c, is_pinned: newPinned } : c))
          .sort((a, b) => (b.is_pinned ? 1 : 0) - (a.is_pinned ? 1 : 0))
      );
      showToast(newPinned ? 'Đã ghim cuộc trò chuyện lên đầu!' : 'Đã bỏ ghim cuộc trò chuyện!', 'success');
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi ghim cuộc trò chuyện', 'error');
    }
  };

  const handleSaveRename = async (id: string) => {
    const title = editingTitle.trim();
    if (!title) return;
    try {
      await aiService.updateConversationTitle(id, title);
      setConversations((prev) =>
        prev.map((c) => (c.id === id ? { ...c, title } : c))
      );
      setEditingConvId(null);
      showToast('Đã đổi tên cuộc trò chuyện thành công!', 'success');
    } catch (err: any) {
      showToast(err.message || 'Lỗi khi đổi tên cuộc trò chuyện', 'error');
    }
  };

  // Streaming SSE Chat Integration
  const handleSend = async (customPrompt?: string) => {
    const q = (customPrompt || input).trim();
    if (!q || isLoading) return;

    const userMsg: ChatMessage = {
      id: `u-${Date.now()}`,
      sender_role: 'user',
      content: q,
    };

    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setIsLoading(true);

    const botMessageId = `b-${Date.now()}`;
    const initialBotMsg: ChatMessage = {
      id: botMessageId,
      sender_role: 'assistant',
      content: '',
      citations: [],
      confidence: 'HIGH'
    };

    setMessages((prev) => [...prev, initialBotMsg]);

    try {
      await aiService.streamChat(
        {
          question: q,
          conversationId: activeId || undefined,
          topK: 4
        },
        {
          onStart: (data) => {
            if (!activeId && data.conversation_id) {
              setActiveId(data.conversation_id);
              fetchConversations();
            }
          },
          onToken: (token) => {
            setMessages((prev) =>
              prev.map((msg) =>
                msg.id === botMessageId
                  ? { ...msg, content: msg.content + token }
                  : msg
              )
            );
          },
          onCitations: (data) => {
            setMessages((prev) =>
              prev.map((msg) =>
                msg.id === botMessageId
                  ? {
                      ...msg,
                      citations: data.citations || [],
                      confidence: data.confidence || 'HIGH',
                      rewritten_query: data.rewritten_query
                    }
                  : msg
              )
            );
          },
          onDone: () => {
            setIsLoading(false);
            fetchConversations();
          },
          onError: (err) => {
            setIsLoading(false);
            setMessages((prev) =>
              prev.map((msg) =>
                msg.id === botMessageId
                  ? {
                      ...msg,
                      content:
                        msg.content ||
                        `⚠️ Lỗi xử lý: ${err.message || 'Không thể kết nối đến Trợ lý AI. Vui lòng kiểm tra lại dịch vụ AI.'}`
                    }
                  : msg
              )
            );
          }
        }
      );
    } catch (err: any) {
      setIsLoading(false);
      setMessages((prev) =>
        prev.map((msg) =>
          msg.id === botMessageId
            ? {
                ...msg,
                content:
                  msg.content ||
                  `⚠️ Không thể kết nối đến AI Service: ${err.message || 'Lỗi mạng'}`
              }
            : msg
        )
      );
    }
  };

  const loadDocuments = async () => {
    try {
      const res = await aiService.getDocuments();
      if (res?.documents) {
        setDocuments(res.documents);
      }
    } catch {
      // ignore
    }
  };

  const handleUploadFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);
    formData.append('allowed_departments', uploadDept);
    formData.append('allowedDepartments', uploadDept);

    setIsUploading(true);
    try {
      await aiService.uploadDocument(formData);
      showToast(`Đã tải lên tài liệu "${file.name}" thành công! Hệ thống đang phân tích vector embeddings.`, 'success');
      await loadDocuments();
    } catch (err: any) {
      showToast(err.message || 'Lỗi tải lên tài liệu', 'error');
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleDeleteDoc = async (docId: string) => {
    if (!confirm('Bạn có chắc chắn muốn xóa tài liệu này khỏi cơ sở tri thức AI?')) return;
    try {
      await aiService.deleteDocument(docId);
      showToast('Đã xóa tài liệu khỏi tri thức AI!', 'success');
      await loadDocuments();
    } catch (err: any) {
      showToast(err.message || 'Lỗi xóa tài liệu', 'error');
    }
  };

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  // ponytail: bỏ sidemenu chung 1 mục — lịch sử chat (aside nội trang) giữ nguyên
  return (
    <AppShell noSidebar fullWidth>
      {/* ponytail: full-bleed kiểu ChatGPT — messages/input đã tự max-w-3xl ở trong */}
      <div className="flex flex-1 min-h-0 bg-white overflow-hidden relative">
        {/* Mobile History Backdrop */}
        {isHistoryOpen && (
          <div 
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs z-40 md:hidden"
            onClick={() => setIsHistoryOpen(false)}
          />
        )}

        {/* Left Sidebar - Chat History (Responsive Slide-Over on Mobile, Persistent on Desktop) */}
        <aside
          className={`fixed inset-y-0 left-0 z-50 w-72 bg-slate-50 border-r border-slate-200 flex flex-col shrink-0 transition-transform duration-200 ease-in-out md:static md:w-64 md:translate-x-0 ${
            isHistoryOpen ? 'translate-x-0' : '-translate-x-full'
          }`}
        >
          <div className="p-3 border-b border-slate-200 flex items-center justify-between gap-2">
            <button
              onClick={startNewChat}
              className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-xl text-xs font-bold transition shadow-xs cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              Đoạn chat mới
            </button>
            <button
              onClick={() => setIsHistoryOpen(false)}
              className="md:hidden p-2 text-slate-400 hover:text-slate-700 rounded-lg"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-2 space-y-1">
            <div className="px-2 py-1 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              Lịch sử hội thoại
            </div>

            {conversations.length === 0 ? (
              <div className="text-center py-8 text-xs text-slate-400 px-4">
                Chưa có cuộc trò chuyện nào. Bắt đầu hỏi để lưu lịch sử!
              </div>
            ) : (
              conversations.map((c) => {
                const isActive = activeId === c.id;
                const isMenuOpen = openMenuId === c.id;
                const isEditing = editingConvId === c.id;

                return (
                  <div
                    key={c.id}
                    onClick={() => {
                      if (!isEditing) loadConversation(c.id);
                    }}
                    className={`group relative flex items-center justify-between px-3 py-2 rounded-xl text-xs cursor-pointer transition-all ${
                      isActive
                        ? 'bg-blue-50 text-blue-700 font-bold'
                        : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900 font-medium'
                    }`}
                  >
                    {isEditing ? (
                      <div className="flex items-center gap-1.5 flex-1 pr-1" onClick={(e) => e.stopPropagation()}>
                        <input
                          type="text"
                          value={editingTitle}
                          onChange={(e) => setEditingTitle(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') handleSaveRename(c.id);
                            if (e.key === 'Escape') setEditingConvId(null);
                          }}
                          autoFocus
                          className="w-full px-2 py-0.5 text-xs border border-blue-400 rounded-lg focus:outline-hidden focus:ring-1 focus:ring-blue-500 bg-white text-slate-900 font-normal"
                        />
                        <button
                          onClick={() => handleSaveRename(c.id)}
                          className="p-1 text-emerald-600 hover:bg-emerald-50 rounded"
                          title="Lưu tên"
                        >
                          <Check className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => setEditingConvId(null)}
                          className="p-1 text-slate-400 hover:bg-slate-100 rounded"
                          title="Hủy"
                        >
                          <X className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    ) : (
                      <>
                        <div className="flex items-center gap-2 truncate pr-1 flex-1">
                          {c.is_pinned ? (
                            <Pin className="w-3.5 h-3.5 shrink-0 text-amber-500 fill-amber-500/20" />
                          ) : (
                            <MessageSquare className={`w-3.5 h-3.5 shrink-0 ${isActive ? 'text-blue-600' : 'text-slate-400'}`} />
                          )}
                          <span className="truncate">{c.title || 'Hội thoại mới'}</span>
                        </div>

                        {/* 3-dots Button */}
                        <div className="relative shrink-0">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setOpenMenuId(isMenuOpen ? null : c.id);
                            }}
                            className={`p-1 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-200/60 transition ${
                              isMenuOpen || isActive ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'
                            }`}
                            title="Tùy chọn hội thoại"
                          >
                            <MoreVertical className="w-3.5 h-3.5" />
                          </button>

                          {/* 3 Options Dropdown Menu */}
                          {isMenuOpen && (
                            <div
                              onClick={(e) => e.stopPropagation()}
                              className="absolute right-0 top-full mt-1 w-44 bg-white rounded-xl shadow-xl border border-slate-200 py-1 z-50 animate-in fade-in zoom-in-95 duration-150"
                            >
                              {/* 1. Pin / Unpin */}
                              <button
                                onClick={() => handleTogglePin(c.id, !!c.is_pinned)}
                                className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition text-left cursor-pointer"
                              >
                                {c.is_pinned ? (
                                  <>
                                    <PinOff className="w-3.5 h-3.5 text-amber-600" />
                                    <span>Bỏ ghim</span>
                                  </>
                                ) : (
                                  <>
                                    <Pin className="w-3.5 h-3.5 text-blue-600" />
                                    <span>Ghim hội thoại</span>
                                  </>
                                )}
                              </button>

                              {/* 2. Rename */}
                              <button
                                onClick={() => {
                                  setOpenMenuId(null);
                                  setEditingConvId(c.id);
                                  setEditingTitle(c.title || '');
                                }}
                                className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition text-left cursor-pointer"
                              >
                                <Pencil className="w-3.5 h-3.5 text-slate-500" />
                                <span>Đổi tên</span>
                              </button>

                              <div className="my-1 border-t border-slate-100" />

                              {/* 3. Delete */}
                              <button
                                onClick={(e) => {
                                  setOpenMenuId(null);
                                  deleteConv(e, c.id);
                                }}
                                className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-semibold text-rose-600 hover:bg-rose-50 transition text-left cursor-pointer"
                              >
                                <Trash2 className="w-3.5 h-3.5 text-rose-500" />
                                <span>Xóa hội thoại</span>
                              </button>
                            </div>
                          )}
                        </div>
                      </>
                    )}
                  </div>
                );
              })
            )}
          </div>

        </aside>

        {/* Main Chat Area */}
        <section className="flex-1 flex flex-col bg-white overflow-hidden">
          {/* Header */}
          <div className="px-4 sm:px-6 py-3 border-b border-slate-100 flex items-center justify-between bg-white/90 backdrop-blur-xs">
            <div className="flex items-center gap-2.5">
              {/* Mobile History Toggle */}
              <button
                onClick={() => setIsHistoryOpen(true)}
                className="md:hidden p-1.5 text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer"
                aria-label="Lịch sử chat"
              >
                <Menu className="w-5 h-5" />
              </button>

              <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center text-white shadow-xs">
                <Sparkles className="w-4 h-4" />
              </div>
              <div>
                <h1 className="text-xs sm:text-sm font-bold text-slate-900">
                  Trợ lý AI Quy chế
                </h1>
                <p className="text-[10px] sm:text-[11px] text-slate-400">Tra cứu nội quy lao động, chính sách phúc lợi & thủ tục công ty</p>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Link
                href="/documents"
                className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-700 transition"
              >
                <FolderOpen className="w-3.5 h-3.5 text-blue-600" />
                <span>Kho tài liệu</span>
              </Link>

              {(isHR || isExecutive) && (
                <button
                  onClick={() => {
                    loadDocuments();
                    setIsDocModalOpen(true);
                  }}
                  className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-orange-600 hover:bg-orange-500 text-white text-xs font-bold shadow-xs transition cursor-pointer"
                >
                  <Upload className="w-3.5 h-3.5" />
                  <span>Nạp tài liệu</span>
                </button>
              )}
            </div>
          </div>

          {/* Toast */}
          {toastMsg && (
            <div className={`px-4 py-2 text-xs font-bold flex items-center justify-between ${
              toastMsg.type === 'success' ? 'bg-emerald-50 text-emerald-800' : 'bg-red-50 text-red-800'
            }`}>
              <span>{toastMsg.text}</span>
              <button onClick={() => setToastMsg(null)}><X className="w-3.5 h-3.5" /></button>
            </div>
          )}

          {/* Messages Stream */}
          <div className="flex-1 overflow-y-auto p-3.5 sm:p-6 space-y-4">
            {messages.length === 0 && !isFetchingHistory ? (
              <div className="h-full flex flex-col items-center justify-center max-w-2xl mx-auto text-center px-4 py-6">
                <div className="w-14 h-14 rounded-2xl bg-blue-50 border border-blue-100 flex items-center justify-center text-blue-600 mb-3 shadow-xs">
                  <Bot className="w-7 h-7" />
                </div>
                <h2 className="text-base sm:text-xl font-extrabold text-slate-900 mb-1.5">
                  Tôi có thể hỗ trợ gì cho bạn hôm nay?
                </h2>
                <p className="text-xs text-slate-500 max-w-md">
                  Đặt câu hỏi về ngày phép, giờ giấc làm việc, hệ số tăng ca OT, bảo hiểm xã hội hoặc quy trình bàn giao thôi việc.
                </p>
              </div>
            ) : isFetchingHistory ? (
              <div className="h-full flex items-center justify-center text-slate-400 text-xs gap-2">
                <Loader2 className="w-4 h-4 animate-spin text-blue-600" />
                Đang tải đoạn chat...
              </div>
            ) : (
              messages.map((m) => (
                <div
                  key={m.id}
                  className={`flex gap-2.5 max-w-3xl mx-auto ${
                    m.sender_role === 'user' ? 'justify-end' : 'justify-start'
                  }`}
                >
                  {m.sender_role === 'assistant' && (
                    <div className="w-7 h-7 rounded-xl bg-blue-600 text-white flex items-center justify-center shrink-0 mt-0.5 shadow-xs text-xs">
                      <Bot className="w-3.5 h-3.5" />
                    </div>
                  )}

                  <div className={`space-y-2 max-w-[90%] sm:max-w-[85%] ${m.sender_role === 'user' ? 'items-end' : 'items-start'}`}>
                    <div
                      className={`rounded-2xl px-4 py-2.5 text-xs sm:text-sm leading-relaxed ${
                        m.sender_role === 'user'
                          ? 'bg-blue-600 text-white rounded-tr-xs shadow-xs'
                          : 'bg-slate-50 text-slate-800 border border-slate-200/80 rounded-tl-xs'
                      }`}
                    >
                      {m.sender_role === 'user' ? (
                        <p className="whitespace-pre-wrap">{m.content}</p>
                      ) : m.content ? (
                        <MarkdownLite text={m.content} />
                      ) : (
                        // Chờ token đầu tiên: 3 chấm nhảy, nhãn trực quan cho
                        // người dùng biết đã gửi và đang xử lý (chờ route + retrieval + LLM).
                        <span className="flex items-center gap-1 py-0.5" role="status" aria-label="Đang trả lời">
                          {[0, 1, 2].map(i => (
                            <span
                              key={i}
                              className="w-1.5 h-1.5 rounded-full bg-slate-400 animate-bounce"
                              style={{ animationDelay: `${i * 160}ms` }}
                            />
                          ))}
                        </span>
                      )}
                    </div>

                    {/* ponytail: đã bỏ block citations + confidence (theo yêu cầu). Backend vẫn
                        trả và lưu vào DB, chỉ không render ra UI nữa. */}
                  </div>
                </div>
              ))
            )}
            <div ref={messagesEndRef} />
          </div>

          {/* Chat Input Area */}
          <div className="p-3 sm:p-4 border-t border-slate-100 bg-white">
            <form
              onSubmit={(e) => {
                e.preventDefault();
                handleSend();
              }}
              className="flex items-center gap-2 max-w-3xl mx-auto"
            >
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Nhập câu hỏi quy chế (VD: Nghỉ ốm cần nộp giấy tờ gì?)..."
                disabled={isLoading}
                className="flex-1 rounded-2xl border border-slate-200 px-4 py-2.5 text-xs sm:text-sm text-slate-800 focus:border-blue-600 focus:outline-none transition shadow-2xs"
              />
              <button
                type="submit"
                disabled={!input.trim() || isLoading}
                className="flex h-10 w-10 sm:h-11 sm:w-11 items-center justify-center rounded-2xl bg-blue-600 hover:bg-blue-700 text-white disabled:opacity-40 transition shadow-xs cursor-pointer shrink-0"
                aria-label="Gửi câu hỏi"
              >
                {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
              </button>
            </form>
          </div>
        </section>

        {/* MODAL: QUẢN LÝ TRI THỨC VÀ TẢI TÀI LIỆU */}
        {isDocModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in">
            <div className="relative w-full max-w-2xl max-h-[85vh] flex flex-col rounded-3xl bg-white p-6 shadow-2xl border border-slate-100">
              <div className="flex items-center justify-between border-b border-slate-100 pb-3 mb-4">
                <div className="flex items-center gap-2">
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-blue-100 text-blue-600 font-bold">
                    <FolderOpen className="h-5 w-5" />
                  </div>
                  <div>
                    <h3 className="text-base font-extrabold text-slate-900">Cơ Sở Tri Thức & Quy Chế Nội Bộ</h3>
                      <p className="text-xs text-slate-400">Phân quyền tài liệu theo phòng ban</p>
                  </div>
                </div>
                <button onClick={() => setIsDocModalOpen(false)} className="p-1 text-slate-400 hover:text-slate-600 rounded-lg">
                  <X className="h-5 w-5" />
                </button>
              </div>

              {/* Upload Box (Only HR & Executive or Manager) */}
              {(isHR || isExecutive || isManager) && (
                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/80 mb-4 space-y-3">
                  <div className="text-xs font-bold text-slate-800 flex items-center gap-2">
                    <Upload className="h-4 w-4 text-blue-600" />
                    <span>Tải lên văn bản quy chế mới (.pdf, .docx, .xlsx)</span>
                  </div>

                  <div className="flex flex-col sm:flex-row items-center gap-3">
                    <div className="w-full sm:w-1/2">
                      <label className="block text-[11px] font-semibold text-slate-500 mb-1">Phạm vi áp dụng:</label>
                      <select
                        value={uploadDept}
                        onChange={(e) => setUploadDept(e.target.value)}
                        className="w-full rounded-xl border border-slate-200 px-3 py-1.5 text-xs text-slate-800 bg-white font-medium"
                      >
                        <option value="ALL">Toàn công ty (ALL)</option>
                        {DEPARTMENTS.map(d => (
                          <option key={d.value} value={d.value}>{d.label}</option>
                        ))}
                      </select>
                    </div>

                    <div className="w-full sm:w-1/2 flex items-end">
                      <input
                        type="file"
                        ref={fileInputRef}
                        onChange={handleUploadFile}
                        accept=".pdf,.docx,.xlsx"
                        className="hidden"
                        id="rag-doc-upload"
                      />
                      <label
                        htmlFor="rag-doc-upload"
                        className={`w-full flex items-center justify-center gap-2 px-4 py-2 rounded-xl text-xs font-bold text-white transition cursor-pointer ${
                          isUploading ? 'bg-slate-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-700 shadow-xs'
                        }`}
                      >
                        {isUploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Upload className="w-4 h-4" />}
                        <span>{isUploading ? 'Đang phân tích...' : 'Chọn file tài liệu'}</span>
                      </label>
                    </div>
                  </div>
                </div>
              )}

              {/* Document List */}
              <div className="flex-1 overflow-y-auto space-y-2">
                <div className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">
                  Danh sách tài liệu đã index ({documents.length})
                </div>

                {documents.length === 0 ? (
                  <div className="p-8 text-center text-xs text-slate-400">
                    Chưa có tài liệu nào trong cơ sở tri thức hoặc đang cập nhật.
                  </div>
                ) : (
                  documents.map((doc) => (
                    <div
                      key={doc.id}
                      className="p-3 rounded-2xl bg-white border border-slate-200/80 hover:border-blue-200 transition flex items-center justify-between gap-3 text-xs"
                    >
                      <div className="flex items-center gap-2.5 truncate">
                        <FileText className="h-5 w-5 text-blue-600 shrink-0" />
                        <div className="truncate">
                          <div className="font-bold text-slate-900 truncate">{doc.file_name}</div>
                          <div className="text-[11px] text-slate-400 flex items-center gap-2 mt-0.5">
                            <span>Phòng ban: <strong>{doc.allowed_departments?.join(', ') || 'ALL'}</strong></span>
                            <span>•</span>
                            <span>{doc.chunk_count} chunks</span>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-1.5 shrink-0">
                        <a
                          href={doc.file_url || `/api/ai/documents/${doc.id}/download`}
                          target="_blank"
                          rel="noreferrer"
                          className="p-2 rounded-xl text-slate-600 hover:text-blue-600 hover:bg-slate-50 transition"
                          title="Tải về"
                        >
                          <Download className="w-4 h-4" />
                        </a>

                        {(isHR || isExecutive) && (
                          <button
                            onClick={() => handleDeleteDoc(doc.id)}
                            className="p-2 rounded-xl text-slate-400 hover:text-red-600 hover:bg-red-50 transition"
                            title="Xóa tài liệu"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </AppShell>
  );
}
