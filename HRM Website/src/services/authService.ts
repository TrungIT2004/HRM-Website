import { apiClient } from './apiClient';
import { User } from '@/types';

export interface LoginResponse {
  accessToken: string;
  user: User;
  tokenType?: string;
  expiresIn?: number;
}

const dispatchTokenChanged = () => {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent('act-hrm:token-changed'));
  }
};

const dispatchLogout = () => {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent('act-hrm:logout'));
  }
};

export const authService = {
  login: async (email: string, password = 'test@123'): Promise<LoginResponse> => {
    const response = await apiClient.post<LoginResponse>('/auth/login', { email, password });
    dispatchTokenChanged();
    return response;
  },

  autoLogin: async (): Promise<LoginResponse> => {
    const response = await apiClient.post<LoginResponse>('/auth/auto-login');
    dispatchTokenChanged();
    return response;
  },

  logout: async (): Promise<{ message?: string }> => {
    dispatchLogout();
    return apiClient.post('/auth/logout');
  },

  changePassword: async (oldPassword: string, newPassword: string, confirmPassword: string): Promise<{ message: string }> => {
    const response = await apiClient.put<{ message: string }>('/auth/change-password', { oldPassword, newPassword, confirmPassword });
    dispatchTokenChanged();
    return response;
  }
};