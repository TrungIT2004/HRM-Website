import { apiClient } from './apiClient';

export interface JobDto {
  jobId: string;
  title: string;
  departmentId?: string;
  departmentName?: string;
}

export interface DepartmentDto {
  departmentId: string;
  name: string;
  totalEmployees: number;
  jobs: JobDto[];
}

export const organizationService = {
  getAllDepartments: async (): Promise<DepartmentDto[]> => {
    return apiClient.get<DepartmentDto[]>('/api/departments');
  },

  createDepartment: async (name: string): Promise<DepartmentDto> => {
    return apiClient.post<DepartmentDto>('/api/departments', { name });
  },

  updateDepartment: async (departmentId: string, name: string): Promise<DepartmentDto> => {
    return apiClient.put<DepartmentDto>(`/api/departments/${departmentId}`, { name });
  },

  /** Trả 409 nếu còn chức danh / nhân viên tham chiếu. */
  deleteDepartment: async (departmentId: string): Promise<{ message: string }> => {
    return apiClient.delete<{ message: string }>(`/api/departments/${departmentId}`);
  },

  getAllJobs: async (departmentId?: string): Promise<JobDto[]> => {
    const q = departmentId ? `?departmentId=${departmentId}` : '';
    return apiClient.get<JobDto[]>(`/api/jobs${q}`);
  },

  createJob: async (title: string, departmentId: string): Promise<JobDto> => {
    return apiClient.post<JobDto>('/api/jobs', { title, departmentId });
  },

  updateJob: async (jobId: string, title: string, departmentId: string): Promise<JobDto> => {
    return apiClient.put<JobDto>(`/api/jobs/${jobId}`, { title, departmentId });
  },

  /** Trả 409 nếu còn nhân viên giữ chức danh này. */
  deleteJob: async (jobId: string): Promise<{ message: string }> => {
    return apiClient.delete<{ message: string }>(`/api/jobs/${jobId}`);
  }
};
