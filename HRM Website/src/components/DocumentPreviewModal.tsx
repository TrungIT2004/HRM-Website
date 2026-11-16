'use client';

import React, { useState, useEffect, useRef } from 'react';
import { X, Download, FileText, AlertCircle, RefreshCw, Table2, ExternalLink } from 'lucide-react';

export interface PreviewDocumentTarget {
  id: string;
  name: string;
  type?: string;
  url?: string;
  isTemplate?: boolean;
}

interface DocumentPreviewModalProps {
  target: PreviewDocumentTarget | null;
  onClose: () => void;
  onDownload?: (target: PreviewDocumentTarget) => void;
  fetchBlob: (target: PreviewDocumentTarget) => Promise<Blob>;
}

export function DocumentPreviewModal({
  target,
  onClose,
  onDownload,
  fetchBlob,
}: DocumentPreviewModalProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [blob, setBlob] = useState<Blob | null>(null);
  const [blobUrl, setBlobUrl] = useState<string | null>(null);
  const [sheets, setSheets] = useState<{ name: string; html: string }[]>([]);
  const [activeSheet, setActiveSheet] = useState(0);

  const docxContainerRef = useRef<HTMLDivElement>(null);

  // Determine file kind
  const ext = target ? target.name.split('.').pop()?.toLowerCase() || '' : '';
  const isPdf = ext === 'pdf' || (target?.type || '').toLowerCase().includes('pdf');
  const isDocx = ext === 'docx' || (target?.type || '').toLowerCase().includes('wordprocessingml');
  const isExcel = ['xlsx', 'xls', 'csv'].includes(ext) || (target?.type || '').toLowerCase().includes('spreadsheet') || (target?.type || '').toLowerCase().includes('excel');
  const isUnsupported = !isPdf && !isDocx && !isExcel;

  useEffect(() => {
    if (!target) {
      setBlob(null);
      setBlobUrl(null);
      setSheets([]);
      setError(null);
      return;
    }

    let isMounted = true;
    setLoading(true);
    setError(null);
    setSheets([]);
    setBlob(null);

    // Revoke previous blob URL
    if (blobUrl) {
      URL.revokeObjectURL(blobUrl);
      setBlobUrl(null);
    }

    fetchBlob(target)
      .then(async (b) => {
        if (!isMounted) return;
        setBlob(b);

        if (isPdf) {
          // Bắt buộc ép MIME type 'application/pdf' để trình duyệt render PDF viewer thay vì kích hoạt tải file octet-stream
          const arrayBuffer = await b.arrayBuffer();
          const pdfBlob = new Blob([arrayBuffer], { type: 'application/pdf' });
          const url = URL.createObjectURL(pdfBlob);
          if (isMounted) setBlobUrl(url);
        } else if (isExcel) {
          try {
            const XLSX = await import('xlsx');
            const arrayBuffer = await b.arrayBuffer();
            const workbook = XLSX.read(arrayBuffer, { type: 'array' });
            const parsedSheets = workbook.SheetNames.map((sheetName) => ({
              name: sheetName,
              html: XLSX.utils.sheet_to_html(workbook.Sheets[sheetName]),
            }));
            if (isMounted) {
              setSheets(parsedSheets);
              setActiveSheet(0);
            }
          } catch (excelErr: any) {
            console.error('Lỗi phân tích Excel:', excelErr);
            if (isMounted) setError('Không thể phân tích định dạng bảng tính này');
          }
        }
      })
      .catch((fetchErr: any) => {
        if (isMounted) {
          console.error('Lỗi tải tệp:', fetchErr);
          setError(fetchErr?.message || 'Không thể tải nội dung xem trước');
        }
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [target]);

  // Render DOCX once blob is available
  useEffect(() => {
    if (!target || !blob || !isDocx || !docxContainerRef.current) return;

    let isMounted = true;
    docxContainerRef.current.innerHTML = '';

    import('docx-preview')
      .then(({ renderAsync }) => {
        if (!isMounted || !docxContainerRef.current) return;
        renderAsync(blob, docxContainerRef.current, undefined, {
          className: 'docx-rendered-page',
          inWrapper: true,
          ignoreWidth: false,
          ignoreHeight: false,
        }).catch((renderErr) => {
          console.error('Lỗi render DOCX:', renderErr);
          if (isMounted) setError('Không thể kết xuất xem trước tệp Word này');
        });
      })
      .catch((err) => {
        console.error('Lỗi tải thư viện docx-preview:', err);
        if (isMounted) setError('Không thể khởi tạo bộ xem Word');
      });

    return () => {
      isMounted = false;
    };
  }, [blob, target, isDocx]);

  // Cleanup blob URL on unmount
  useEffect(() => {
    return () => {
      if (blobUrl) URL.revokeObjectURL(blobUrl);
    };
  }, [blobUrl]);

  if (!target) return null;

  return (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-3 md:p-6 animate-in fade-in duration-200"
    >
      <div className="bg-white rounded-3xl w-full max-w-6xl h-[90vh] flex flex-col shadow-2xl overflow-hidden border border-slate-200">
        {/* Header */}
        <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between gap-3 bg-white shrink-0">
          <div className="flex items-center gap-3 min-w-0">
            <div className="p-2.5 rounded-xl bg-blue-50 text-blue-600 shrink-0">
              {isExcel ? <Table2 className="w-5 h-5" /> : <FileText className="w-5 h-5" />}
            </div>
            <div className="min-w-0">
              <h3 className="text-base font-extrabold text-slate-900 truncate" title={target.name}>
                {target.name}
              </h3>
              <p className="text-xs font-semibold text-slate-400">
                {isPdf && 'Tài liệu PDF (Xem trực tiếp)'}
                {isDocx && 'Tài liệu Microsoft Word (.docx)'}
                {isExcel && 'Bảng tính Excel (.xlsx / .xls)'}
                {isUnsupported && `Tệp đính kèm (.${ext.toUpperCase()})`}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            {isPdf && blobUrl && (
              <a
                href={blobUrl}
                target="_blank"
                rel="noreferrer"
                title="Mở PDF toàn màn hình trong tab mới"
                className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl border border-slate-200 text-xs font-bold text-slate-700 hover:bg-slate-50 transition-colors cursor-pointer"
              >
                <ExternalLink className="w-4 h-4" />
                <span className="hidden sm:inline">Mở tab mới</span>
              </a>
            )}
            {onDownload && (
              <button
                type="button"
                onClick={() => onDownload(target)}
                title="Tải tệp về máy"
                className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl border border-slate-200 text-xs font-bold text-slate-700 hover:bg-slate-50 transition-colors cursor-pointer"
              >
                <Download className="w-4 h-4" />
                <span className="hidden sm:inline">Tải về</span>
              </button>
            )}
            <button
              type="button"
              onClick={onClose}
              title="Đóng (Esc)"
              className="p-2 rounded-xl text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Content Body */}
        <div className="flex-1 min-h-0 bg-slate-50 relative flex flex-col overflow-hidden">
          {loading && (
            <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-white/80 backdrop-blur-xs">
              <RefreshCw className="w-8 h-8 text-blue-600 animate-spin mb-3" />
              <p className="text-sm font-bold text-slate-700">Đang chuẩn bị nội dung xem trước...</p>
              <p className="text-xs text-slate-400 mt-1">Đang tải và hiển thị trực tiếp tại trình duyệt</p>
            </div>
          )}

          {error && (
            <div className="flex-1 flex flex-col items-center justify-center text-center p-6">
              <div className="p-3 rounded-2xl bg-rose-50 text-rose-600 mb-3">
                <AlertCircle className="w-8 h-8" />
              </div>
              <h4 className="text-base font-bold text-slate-800">Không thể xem trực tiếp tệp này</h4>
              <p className="text-xs text-slate-500 max-w-md mt-1 mb-5">{error}</p>
              {onDownload && (
                <button
                  type="button"
                  onClick={() => onDownload(target)}
                  className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-md shadow-blue-500/20 cursor-pointer"
                >
                  <Download className="w-4 h-4" /> Tải về máy để xem
                </button>
              )}
            </div>
          )}

          {!loading && !error && isPdf && blobUrl && (
            <div className="w-full h-full relative bg-slate-100 flex flex-col">
              <object
                data={`${blobUrl}#toolbar=1&navpanes=0`}
                type="application/pdf"
                className="w-full h-full border-0 bg-white"
              >
                <iframe
                  src={`${blobUrl}#toolbar=1`}
                  className="w-full h-full border-0 bg-white"
                  title={target.name}
                >
                  <div className="flex flex-col items-center justify-center h-full p-6 text-center">
                    <p className="text-sm font-semibold text-slate-700 mb-3">
                      Trình duyệt không hỗ trợ nhúng khung xem PDF trực tiếp.
                    </p>
                    <a
                      href={blobUrl}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold"
                    >
                      <ExternalLink className="w-4 h-4" /> Mở trong tab mới
                    </a>
                  </div>
                </iframe>
              </object>
            </div>
          )}

          {!loading && !error && isDocx && (
            <div className="flex-1 overflow-auto p-4 md:p-8 flex justify-center bg-slate-100">
              <div
                ref={docxContainerRef}
                className="w-full max-w-4xl bg-white shadow-md rounded-2xl p-6 min-h-[500px]"
              />
            </div>
          )}

          {!loading && !error && isExcel && (
            <div className="flex-1 flex flex-col min-h-0 p-4">
              {sheets.length > 1 && (
                <div className="flex gap-1.5 pb-2 border-b border-slate-200 overflow-x-auto shrink-0 mb-3">
                  {sheets.map((sheet, idx) => (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setActiveSheet(idx)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap cursor-pointer ${
                        activeSheet === idx
                          ? 'bg-blue-600 text-white shadow-sm shadow-blue-500/20'
                          : 'bg-white text-slate-600 hover:bg-slate-100 border border-slate-200'
                      }`}
                    >
                      {sheet.name}
                    </button>
                  ))}
                </div>
              )}
              <div
                className="flex-1 overflow-auto bg-white rounded-2xl border border-slate-200 p-4 shadow-xs [&_table]:w-full [&_table]:border-collapse [&_th]:border [&_th]:border-slate-200 [&_th]:bg-slate-50 [&_th]:p-2 [&_th]:text-left [&_th]:text-xs [&_th]:font-bold [&_th]:text-slate-700 [&_td]:border [&_td]:border-slate-200 [&_td]:p-2 [&_td]:text-xs [&_td]:text-slate-600"
                dangerouslySetInnerHTML={{ __html: sheets[activeSheet]?.html || '<p class="text-xs text-slate-400 p-4">Trống</p>' }}
              />
            </div>
          )}

          {!loading && !error && isUnsupported && (
            <div className="flex-1 flex flex-col items-center justify-center text-center p-6">
              <div className="p-3.5 rounded-2xl bg-amber-50 text-amber-600 mb-3">
                <FileText className="w-8 h-8" />
              </div>
              <h4 className="text-base font-bold text-slate-800">Định dạng .{ext.toUpperCase()} chưa hỗ trợ xem nhanh</h4>
              <p className="text-xs text-slate-500 max-w-md mt-1 mb-5">
                Trình duyệt chưa hỗ trợ giải mã trực tiếp định dạng này. Bạn hãy tải tệp về để mở bằng ứng dụng trên máy tính.
              </p>
              {onDownload && (
                <button
                  type="button"
                  onClick={() => onDownload(target)}
                  className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold shadow-md shadow-blue-500/20 cursor-pointer"
                >
                  <Download className="w-4 h-4" /> Tải về máy
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
