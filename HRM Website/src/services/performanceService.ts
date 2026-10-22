import { apiClient, buildQuery, PageResponse } from './apiClient';
import { PerformanceOverview, PerformanceReview } from '@/types';

export interface PerformanceFilterParams {
  periodType?: 'MONTHLY' | 'YEARLY' | 'ALL';
  year?: number;
  month?: number;
  status?: string;
  keyword?: string;
  department?: string;
  page?: number;
  size?: number;
}

export interface ScorePayload {
  criterionCode: string;
  score: number;
  note?: string;
}

export const performanceService = {
  getCurrent: async (periodType = 'MONTHLY', year?: number, month?: number): Promise<PerformanceReview> => {
    return apiClient.get<PerformanceReview>(
      `/api/performance-reviews/current${buildQuery({ periodType, year, month })}`
    );
  },

  getMyReviews: async (params: PerformanceFilterParams = {}): Promise<PageResponse<PerformanceReview>> => {
    return apiClient.get<PageResponse<PerformanceReview>>(
      `/api/performance-reviews/my-records${buildQuery(params)}`
    );
  },

  getApprovals: async (params: PerformanceFilterParams = {}): Promise<PageResponse<PerformanceReview>> => {
    return apiClient.get<PageResponse<PerformanceReview>>(
      `/api/performance-reviews/approvals${buildQuery(params)}`
    );
  },

  getCompanyRecords: async (params: PerformanceFilterParams = {}): Promise<PageResponse<PerformanceReview>> => {
    return apiClient.get<PageResponse<PerformanceReview>>(
      `/api/performance-reviews/company${buildQuery(params)}`
    );
  },

  getOverview: async (year?: number, month?: number, scope: 'dept' | 'company' = 'dept'): Promise<PerformanceOverview> => {
    return apiClient.get<PerformanceOverview>(
      `/api/performance-reviews/overview${buildQuery({ year, month, scope })}`
    );
  },

  submitSelf: async (reviewId: string, scores: ScorePayload[]): Promise<PerformanceReview> => {
    return apiClient.post<PerformanceReview>(`/api/performance-reviews/${reviewId}/self`, { scores });
  },

  scoreManager: async (reviewId: string, scores: ScorePayload[], overallSummary?: string, nextGoals?: string): Promise<PerformanceReview> => {
    return apiClient.patch<PerformanceReview>(`/api/performance-reviews/${reviewId}/manager`, {
      scores, overallSummary, nextGoals
    });
  },

  lock: async (reviewId: string): Promise<PerformanceReview> => {
    return apiClient.patch<PerformanceReview>(`/api/performance-reviews/${reviewId}/lock`, {});
  },

  lockBatch: async (reviewIds: string[]): Promise<{ locked: number; skipped: { reviewId: string; reason: string }[] }> => {
    return apiClient.post(`/api/performance-reviews/lock-batch`, { reviewIds });
  },

  exportExcel: async (reviewIds: string[]) => {
    return apiClient.downloadBlob(`/api/performance-reviews/export${buildQuery({ reviewIds })}`, 'danh_gia.xlsx');
  }
};

export const REVIEW_STATUS_LABEL: Record<string, string> = {
  DRAFT: 'Nháp',
  SELF_SUBMITTED: 'Đã tự đánh giá',
  MANAGER_SCORED: 'Đã chấm',
  LOCKED: 'Đã khóa'
};
