import { apiClient } from './apiClient';

export interface WorkShiftScheduleDto {
  scheduleId?: string;
  dayOfWeek: number; // 1 = T2 ... 7 = CN
  dayOfWeekName?: string;
  isWorking: boolean;
  startTime?: string;
  endTime?: string;
  restStartTime?: string;
  restEndTime?: string;
}

export interface WorkShiftResponse {
  shiftId: string;
  name: string;
  schedules: WorkShiftScheduleDto[];
}

export interface CreateWorkShiftRequest {
  name: string;
  schedules: Array<{
    dayOfWeek: number;
    isWorking: boolean;
    startTime?: string;
    endTime?: string;
    restStartTime?: string;
    restEndTime?: string;
  }>;
}

export const workShiftService = {
  getAllWorkShifts: async (): Promise<WorkShiftResponse[]> => {
    return apiClient.get<WorkShiftResponse[]>('/api/work-shifts');
  },

  createWorkShift: async (data: CreateWorkShiftRequest): Promise<WorkShiftResponse> => {
    return apiClient.post<WorkShiftResponse>('/api/work-shifts', data);
  }
};
