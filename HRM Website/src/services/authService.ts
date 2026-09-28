import { apiClient } from './apiClient';
import { User } from '@/types';

export interface LoginResponse {
  accessToken: string;
  user: User;
  tokenType?: string;
  expiresIn?: number;
}

export const authService = {
  login: async (email: string, password = 'test@123'): Promise<LoginResponse> => {
    return apiClient.post<LoginResponse>('/auth/login', { email, password });
  },

  autoLogin: async (): Promise<LoginResponse> => {
    return apiClient.post<LoginResponse>('/auth/auto-login');
  },

  logout: async (): Promise<{ message?: string }> => {
    return apiClient.post('/auth/logout');
  },

  changePassword: async (oldPassword: string, newPassword: string, confirmPassword: string): Promise<{ message: string }> => {
    return apiClient.put('/auth/change-password', { oldPassword, newPassword, confirmPassword });
  }
};
