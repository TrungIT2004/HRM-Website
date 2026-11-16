import { apiClient } from './apiClient';

export interface WorkShiftScheduleDto {
  scheduleId?: string;
  dayOfWeek: number; // 1 = T2 ... 7 = CN
  dayOfWeekName?: string;
  isWorking?: boolean;
  working?: boolean;
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

  /** Ca của chính mình — 404 khi chưa được phân ca. */
  getMyShift: async (): Promise<WorkShiftResponse> => {
    return apiClient.get<WorkShiftResponse>('/api/work-shifts/my-shift');
  },

  createWorkShift: async (data: CreateWorkShiftRequest): Promise<WorkShiftResponse> => {
    return apiClient.post<WorkShiftResponse>('/api/work-shifts', sanitize(data));
  },

  updateWorkShift: async (shiftId: string, data: CreateWorkShiftRequest): Promise<WorkShiftResponse> => {
    return apiClient.put<WorkShiftResponse>(`/api/work-shifts/${shiftId}`, sanitize(data));
  },

  /** Trả 409 nếu còn nhân viên dùng ca hoặc đã có lịch sử chấm công. */
  deleteWorkShift: async (shiftId: string): Promise<{ message: string }> => {
    return apiClient.delete<{ message: string }>(`/api/work-shifts/${shiftId}`);
  }
};

// input type=time trả "" khi trống -> Jackson không parse được; đổi thành undefined để backend nhận null
// ponytail: chỉ strip "", không validate giờ ở client (backend buildValidatedSchedules lo luật 8h/48h)
const sanitize = (data: CreateWorkShiftRequest): CreateWorkShiftRequest => ({
  ...data,
  schedules: data.schedules.map(s => ({
    ...s,
    startTime: s.startTime || undefined,
    endTime: s.endTime || undefined,
    restStartTime: s.restStartTime || undefined,
    restEndTime: s.restEndTime || undefined,
  })),
});
