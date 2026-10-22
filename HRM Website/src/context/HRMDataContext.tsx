'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import {
  AttendanceRecord,
  LeaveRequest,
  OvertimeRecord,
  PayrollRecord,
  EmployeeDetailed,
  LeaveRequestStatus,
  OvertimeStatus
} from '@/types';
import { useAuth } from './AuthContext';
import { attendanceService } from '@/services/attendanceService';
import { leaveService } from '@/services/leaveService';
import { overtimeService } from '@/services/overtimeService';
import { payrollService } from '@/services/payrollService';
import { employeeService } from '@/services/employeeService';

interface HRMDataContextType {
  attendances: AttendanceRecord[];
  leaveRequests: LeaveRequest[];
  overtimeRecords: OvertimeRecord[];
  payrolls: PayrollRecord[];
  employeeDetails: Record<string, EmployeeDetailed>;
  isLoadingData: boolean;
  dataError: string | null;

  // Attendance actions
  clockInAttendance: (method: 'FACE_SCAN' | 'MANUAL') => Promise<{ success: boolean; message: string }>;
  clockOutAttendance: (method: 'FACE_SCAN' | 'MANUAL') => Promise<{ success: boolean; message: string }>;
  editAttendanceRecord: (attendanceId: string, updates: Partial<AttendanceRecord>, reason: string) => Promise<{ success: boolean; message: string }>;
  deleteAttendanceRecord: (attendanceId: string) => Promise<{ success: boolean; message: string }>;

  // Leave actions
  submitLeaveRequest: (req: Omit<LeaveRequest, 'requestId' | 'status' | 'createdAt'>) => Promise<{ success: boolean; message?: string }>;
  handleLeaveRequest: (requestId: string, status: LeaveRequestStatus, rejectionReason?: string) => Promise<{ success: boolean; message: string }>;
  cancelLeaveRequest: (requestId: string) => Promise<{ success: boolean; message: string }>;

  // Overtime actions
  submitOvertimeRequest: (ot: Omit<OvertimeRecord, 'overtimeRecordId' | 'status' | 'createdAt'>) => Promise<{ success: boolean; message?: string }>;
  handleOvertimeRequest: (recordId: string, status: OvertimeStatus, rejectionReason?: string) => Promise<{ success: boolean; message: string }>;
  cancelOvertimeRequest: (recordId: string) => Promise<{ success: boolean; message: string }>;

  // Employee details update
  updateEmployeeProfile: (userId: string, updates: Partial<EmployeeDetailed>) => Promise<{ success: boolean; message: string }>;
  getEmployeeProfileById: (userId: string) => Promise<EmployeeDetailed | null>;

  // Payroll
  generateMonthlyPayroll: (month: number, year: number) => Promise<{ success: boolean; message: string }>;

  // Reload helper
  reloadAllData: () => Promise<void>;
}

const HRMDataContext = createContext<HRMDataContextType | undefined>(undefined);

export function HRMDataProvider({ children }: { children: React.ReactNode }) {
  const { currentUser, isHR, isManager, isExecutive, can } = useAuth();

  const [attendances, setAttendances] = useState<AttendanceRecord[]>([]);
  const [leaveRequests, setLeaveRequests] = useState<LeaveRequest[]>([]);
  const [overtimeRecords, setOvertimeRecords] = useState<OvertimeRecord[]>([]);
  const [payrolls, setPayrolls] = useState<PayrollRecord[]>([]);
  const [employeeDetails, setEmployeeDetails] = useState<Record<string, EmployeeDetailed>>({});
  const [isLoadingData, setIsLoadingData] = useState(false);
  const [dataError, setDataError] = useState<string | null>(null);

  // Load live data from Spring Boot backend based on user RBAC permissions
  const loadData = useCallback(async () => {
    if (!currentUser) {
      setAttendances([]);
      setLeaveRequests([]);
      setOvertimeRecords([]);
      setPayrolls([]);
      return;
    }

    setIsLoadingData(true);
    setDataError(null);

    try {
      const results = await Promise.allSettled([
        // 1. Attendances
        (isHR || isExecutive || can('ATTENDANCE_VIEW_ALL'))
          ? attendanceService.getCompanyAttendances({ size: 100 })
          : isManager
          ? attendanceService.getDepartmentAttendances({ size: 100 })
          : attendanceService.getMyAttendances({ size: 100 }),

        // 2. Leave Requests
        (isHR || can('LEAVE_VIEW_ALL'))
          ? leaveService.getCompanyLeaves({ size: 100 })
          : (isManager || isExecutive)
          ? leaveService.getDepartmentLeaves({ size: 100 })
          : leaveService.getMyLeaves({ size: 100 }),

        // 3. Overtime Records
        (isHR || can('OVERTIME_VIEW_ALL'))
          ? overtimeService.getCompanyOvertimes({ size: 100 })
          : (isManager || isExecutive)
          ? overtimeService.getDepartmentOvertimes({ size: 100 })
          : overtimeService.getMyOvertimes({ size: 100 }),

        // 4. Payrolls (backend chỉ cho Kế toán + BGĐ xem company; HR/Admin xem lương của chính mình)
        (isExecutive || can('PAYROLL_MANAGE') || currentUser?.department === 'Finance & Accounting' || Boolean(currentUser?.job?.toLowerCase().includes('accountant')))
          ? payrollService.getCompanyPayrolls({ size: 100 })
          : payrollService.getMyPayrolls({ size: 100 })
      ]);

      if (results[0].status === 'fulfilled' && results[0].value?.content) {
        setAttendances(results[0].value.content);
      }
      if (results[1].status === 'fulfilled' && results[1].value?.content) {
        setLeaveRequests(results[1].value.content);
      }
      if (results[2].status === 'fulfilled' && results[2].value?.content) {
        setOvertimeRecords(results[2].value.content);
      }
      if (results[3].status === 'fulfilled' && results[3].value?.content) {
        setPayrolls(results[3].value.content);
      }
    } catch (err: any) {
      setDataError(err.message || 'Lỗi khi tải dữ liệu từ máy chủ Backend');
    } finally {
      setIsLoadingData(false);
    }
  }, [currentUser, isHR, isManager, isExecutive, can]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // 1. Chấm công
  const clockInAttendance = async (method: 'FACE_SCAN' | 'MANUAL') => {
    if (!currentUser) return { success: false, message: 'Bạn chưa đăng nhập vào hệ thống' };

    try {
      const res = await attendanceService.checkAttendance(currentUser.userId);
      await loadData();
      return {
        success: true,
        message: method === 'FACE_SCAN'
          ? `Nhận diện khuôn mặt thành công: ${currentUser.fullName} (${currentUser.employeeCode})`
          : `Ghi nhận thành công: ${res?.action || 'Đã chấm công'}`
      };
    } catch (err: any) {
      return {
        success: false,
        message: err.message || 'Lỗi khi ghi nhận chấm công với máy chủ'
      };
    }
  };

  const clockOutAttendance = async (method: 'FACE_SCAN' | 'MANUAL') => {
    return clockInAttendance(method);
  };

  const editAttendanceRecord = async (attendanceId: string, updates: Partial<AttendanceRecord>, reason: string) => {
    try {
      await attendanceService.editAttendance(attendanceId, {
        clockInTime: updates.clockInTime,
        clockOutTime: updates.clockOutTime,
        status: updates.status,
        reason
      });
      await loadData();
      return { success: true, message: 'Điều chỉnh bản ghi chấm công thành công' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi điều chỉnh bản ghi' };
    }
  };

  const deleteAttendanceRecord = async (attendanceId: string) => {
    try {
      await attendanceService.deleteAttendance(attendanceId);
      await loadData();
      return { success: true, message: 'Đã xóa bản ghi chấm công' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi khi xóa bản ghi' };
    }
  };

  // 2. Nghỉ phép
  const submitLeaveRequest = async (req: Omit<LeaveRequest, 'requestId' | 'status' | 'createdAt'>) => {
    try {
      await leaveService.createLeave({
        fromDate: req.fromDate,
        toDate: req.toDate,
        reason: req.reason
      });
      await loadData();
      return { success: true, message: 'Gửi đơn nghỉ phép lên hệ thống thành công!' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Không thể gửi đơn nghỉ phép' };
    }
  };

  const handleLeaveRequest = async (requestId: string, status: LeaveRequestStatus, rejectionReason?: string) => {
    try {
      if (status === 'accepted') {
        await leaveService.approveLeave(requestId);
      } else if (status === 'rejected') {
        await leaveService.rejectLeave(requestId, rejectionReason || 'Không được phê duyệt');
      }
      await loadData();
      return { success: true, message: `Đã ${status === 'accepted' ? 'phê duyệt' : 'từ chối'} đơn nghỉ phép` };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi khi xử lý đơn nghỉ phép' };
    }
  };

  const cancelLeaveRequest = async (requestId: string) => {
    try {
      await leaveService.cancelLeave(requestId);
      await loadData();
      return { success: true, message: 'Đã hủy đơn xin nghỉ phép' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi khi hủy đơn nghỉ phép' };
    }
  };

  // 3. Làm thêm giờ (OT)
  const submitOvertimeRequest = async (ot: Omit<OvertimeRecord, 'overtimeRecordId' | 'status' | 'createdAt'>) => {
    try {
      await overtimeService.createOvertime({
        approvedDate: ot.approvedDate,
        approvedStartTime: ot.approvedStartTime,
        approvedEndTime: ot.approvedEndTime,
        reason: ot.reason
      });
      await loadData();
      return { success: true, message: 'Gửi đơn đăng ký OT thành công!' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Không thể gửi đơn đăng ký OT' };
    }
  };

  const handleOvertimeRequest = async (recordId: string, status: OvertimeStatus, rejectionReason?: string) => {
    try {
      if (status === 'accepted') {
        await overtimeService.approveOvertime(recordId);
      } else if (status === 'rejected') {
        await overtimeService.rejectOvertime(recordId, rejectionReason || 'Không được phê duyệt');
      }
      await loadData();
      return { success: true, message: `Đã ${status === 'accepted' ? 'phê duyệt' : 'từ chối'} đơn OT` };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi khi xử lý đơn OT' };
    }
  };

  const cancelOvertimeRequest = async (recordId: string) => {
    try {
      await overtimeService.cancelOvertime(recordId);
      await loadData();
      return { success: true, message: 'Đã hủy đơn đăng ký OT' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi khi hủy đơn OT' };
    }
  };

  // 4. Cập nhật hồ sơ & nạp chi tiết
  const getEmployeeProfileById = async (userId: string): Promise<EmployeeDetailed | null> => {
    if (employeeDetails[userId]) return employeeDetails[userId];
    try {
      const detailed = await employeeService.getDetailedProfile(userId);
      if (detailed) {
        setEmployeeDetails(prev => ({ ...prev, [userId]: detailed }));
        return detailed;
      }
      return null;
    } catch {
      return null;
    }
  };

  const updateEmployeeProfile = async (userId: string, updates: Partial<EmployeeDetailed>) => {
    try {
      if (updates.phoneNumber || updates.birthDate || updates.gender) {
        await employeeService.updateLegalProfile(userId, {
          phoneNumber: updates.phoneNumber,
          birthDate: updates.birthDate,
          gender: updates.gender
        });
      }
      const refreshed = await employeeService.getDetailedProfile(userId);
      if (refreshed) {
        setEmployeeDetails(prev => ({ ...prev, [userId]: refreshed }));
      }
      return { success: true, message: 'Cập nhật hồ sơ nhân sự thành công' };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi cập nhật hồ sơ' };
    }
  };

  // 5. Tính lương
  const generateMonthlyPayroll = async (month: number, year: number) => {
    try {
      await payrollService.generatePayroll(month, year);
      await loadData();
      return { success: true, message: `Đã khởi tạo bảng lương tháng ${month}/${year}` };
    } catch (err: any) {
      return { success: false, message: err.message || 'Lỗi khi khởi tạo bảng lương' };
    }
  };

  return (
    <HRMDataContext.Provider
      value={{
        attendances,
        leaveRequests,
        overtimeRecords,
        payrolls,
        employeeDetails,
        isLoadingData,
        dataError,
        clockInAttendance,
        clockOutAttendance,
        editAttendanceRecord,
        deleteAttendanceRecord,
        submitLeaveRequest,
        handleLeaveRequest,
        cancelLeaveRequest,
        submitOvertimeRequest,
        handleOvertimeRequest,
        cancelOvertimeRequest,
        updateEmployeeProfile,
        getEmployeeProfileById,
        generateMonthlyPayroll,
        reloadAllData: loadData
      }}
    >
      {children}
    </HRMDataContext.Provider>
  );
}

export function useHRMData() {
  const context = useContext(HRMDataContext);
  if (!context) {
    throw new Error('useHRMData must be used within an HRMDataProvider');
  }
  return context;
}
