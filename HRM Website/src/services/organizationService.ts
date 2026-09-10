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

  getAllJobs: async (departmentId?: string): Promise<JobDto[]> => {
    const q = departmentId ? `?departmentId=${departmentId}` : '';
    return apiClient.get<JobDto[]>(`/api/jobs${q}`);
  },

  createJob: async (title: string, departmentId: string): Promise<JobDto> => {
    return apiClient.post<JobDto>('/api/jobs', { title, departmentId });
  }
};
