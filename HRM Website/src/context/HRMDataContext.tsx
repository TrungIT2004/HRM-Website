'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  AttendanceRecord,
  LeaveRequest,
  OvertimeRecord,
  PayrollRecord,
  EmployeeDetailed,
  AttendanceStatus,
  LeaveRequestStatus,
  OvertimeStatus,
  User
} from '@/types';
import { MOCK_ATTENDANCES } from '@/mock/attendances';
import { MOCK_LEAVE_REQUESTS } from '@/mock/leaves';
import { MOCK_OVERTIMES } from '@/mock/overtimes';
import { MOCK_PAYROLLS } from '@/mock/payrolls';
import { MOCK_EMPLOYEE_DETAILS, getEmployeeDetail } from '@/mock/employeeDetails';
import { useAuth } from './AuthContext';

interface HRMDataContextType {
  attendances: AttendanceRecord[];
  leaveRequests: LeaveRequest[];
  overtimeRecords: OvertimeRecord[];
  payrolls: PayrollRecord[];
  employeeDetails: Record<string, EmployeeDetailed>;
  
  // Attendance actions
  clockInAttendance: (method: 'FACE_SCAN' | 'MANUAL') => { success: boolean; message: string };
  clockOutAttendance: (method: 'FACE_SCAN' | 'MANUAL') => { success: boolean; message: string };
  editAttendanceRecord: (attendanceId: string, updates: Partial<AttendanceRecord>, reason: string) => void;
  deleteAttendanceRecord: (attendanceId: string) => void;
  
  // Leave actions
  submitLeaveRequest: (req: Omit<LeaveRequest, 'requestId' | 'status' | 'createdAt'>) => void;
  handleLeaveRequest: (requestId: string, status: LeaveRequestStatus, rejectionReason?: string) => void;
  cancelLeaveRequest: (requestId: string) => void;

  // Overtime actions
  submitOvertimeRequest: (ot: Omit<OvertimeRecord, 'overtimeRecordId' | 'status' | 'createdAt'>) => void;
  handleOvertimeRequest: (recordId: string, status: OvertimeStatus, rejectionReason?: string) => void;
  cancelOvertimeRequest: (recordId: string) => void;

  // Employee details update
  updateEmployeeProfile: (userId: string, updates: Partial<EmployeeDetailed>) => void;

  // Payroll
  generateMonthlyPayroll: (month: number, year: number) => void;
}

const HRMDataContext = createContext<HRMDataContextType | undefined>(undefined);

export function HRMDataProvider({ children }: { children: React.ReactNode }) {
  const { currentUser } = useAuth();

  const [attendances, setAttendances] = useState<AttendanceRecord[]>(MOCK_ATTENDANCES);
  const [leaveRequests, setLeaveRequests] = useState<LeaveRequest[]>(MOCK_LEAVE_REQUESTS);
  const [overtimeRecords, setOvertimeRecords] = useState<OvertimeRecord[]>(MOCK_OVERTIMES);
  const [payrolls, setPayrolls] = useState<PayrollRecord[]>(MOCK_PAYROLLS);
  const [employeeDetails, setEmployeeDetails] = useState<Record<string, EmployeeDetailed>>(MOCK_EMPLOYEE_DETAILS);

  // 1. Chấm công
  const clockInAttendance = (method: 'FACE_SCAN' | 'MANUAL') => {
    if (!currentUser) return { success: false, message: 'Chưa đăng nhập' };
    const todayStr = '2026-09-04'; // Đồng bộ với ngày hệ thống
    const nowTimeStr = new Date().toTimeString().split(' ')[0];

    const existingIndex = attendances.findIndex(
      a => a.userId === currentUser.userId && a.workDate === todayStr
    );

    if (existingIndex >= 0 && attendances[existingIndex].clockInTime) {
      return { success: false, message: 'Bạn đã thực hiện vào ca hôm nay rồi!' };
    }

    const newRecord: AttendanceRecord = {
      attendanceId: `att-live-${Date.now()}`,
      userId: currentUser.userId,
      userName: currentUser.fullName,
      employeeCode: currentUser.employeeCode,
      department: currentUser.department,
      job: currentUser.job,
      workDate: todayStr,
      clockInTime: nowTimeStr,
      status: 'WORKING',
      faceRecognitionVerified: method === 'FACE_SCAN',
      faceConfidence: method === 'FACE_SCAN' ? 99.2 : undefined,
      deviceLocation: method === 'FACE_SCAN' ? 'Cửa chính - AI FaceCam 01' : 'Web Portal thủ công'
    };

    if (existingIndex >= 0) {
      const updated = [...attendances];
      updated[existingIndex] = { ...updated[existingIndex], ...newRecord };
      setAttendances(updated);
    } else {
      setAttendances([newRecord, ...attendances]);
    }

    return { 
      success: true, 
      message: method === 'FACE_SCAN' 
        ? `Đã nhận diện khuôn mặt thành công: ${currentUser.fullName} (${currentUser.employeeCode}) - Vào ca lúc ${nowTimeStr}` 
        : `Chấm công vào ca thành công lúc ${nowTimeStr}` 
    };
  };

  const clockOutAttendance = (method: 'FACE_SCAN' | 'MANUAL') => {
    if (!currentUser) return { success: false, message: 'Chưa đăng nhập' };
    const todayStr = '2026-09-04';
    const nowTimeStr = new Date().toTimeString().split(' ')[0];

    const existingIndex = attendances.findIndex(
      a => a.userId === currentUser.userId && a.workDate === todayStr
    );

    if (existingIndex === -1) {
      return { success: false, message: 'Bạn chưa chấm công vào ca hôm nay!' };
    }

    const record = attendances[existingIndex];
    if (record.clockOutTime) {
      return { success: false, message: 'Bạn đã chấm công ra ca hôm nay rồi!' };
    }

    const updated = [...attendances];
    updated[existingIndex] = {
      ...record,
      clockOutTime: nowTimeStr,
      status: 'SUFFICIENT'
    };
    setAttendances(updated);

    return {
      success: true,
      message: `Đã chấm công ra ca lúc ${nowTimeStr}`
    };
  };

  const editAttendanceRecord = (attendanceId: string, updates: Partial<AttendanceRecord>, reason: string) => {
    setAttendances(prev =>
      prev.map(item => {
        if (item.attendanceId === attendanceId) {
          return {
            ...item,
            ...updates,
            isEdited: true,
            editedReason: reason,
            editorName: currentUser?.fullName || 'Quản trị viên',
            editorEmpCode: currentUser?.employeeCode || 'HR001',
            status: 'ADJUSTED'
          };
        }
        return item;
      })
    );
  };

  const deleteAttendanceRecord = (attendanceId: string) => {
    setAttendances(prev => prev.filter(a => a.attendanceId !== attendanceId));
  };

  // 2. Nghỉ phép
  const submitLeaveRequest = (req: Omit<LeaveRequest, 'requestId' | 'status' | 'createdAt'>) => {
    const newReq: LeaveRequest = {
      ...req,
      requestId: `leave-live-${Date.now()}`,
      status: 'pending',
      createdAt: new Date().toISOString().replace('T', ' ').slice(0, 19)
    };
    setLeaveRequests([newReq, ...leaveRequests]);
  };

  const handleLeaveRequest = (requestId: string, status: LeaveRequestStatus, rejectionReason?: string) => {
    setLeaveRequests(prev =>
      prev.map(r => {
        if (r.requestId === requestId) {
          return {
            ...r,
            status,
            rejectionReason: status === 'rejected' ? rejectionReason : undefined,
            approverId: currentUser?.userId,
            approverName: currentUser?.fullName,
            approverJob: currentUser?.job
          };
        }
        return r;
      })
    );
  };

  const cancelLeaveRequest = (requestId: string) => {
    setLeaveRequests(prev => prev.filter(r => r.requestId !== requestId));
  };

  // 3. Làm thêm giờ
  const submitOvertimeRequest = (ot: Omit<OvertimeRecord, 'overtimeRecordId' | 'status' | 'createdAt'>) => {
    const newRecord: OvertimeRecord = {
      ...ot,
      overtimeRecordId: `ot-live-${Date.now()}`,
      status: 'pending',
      createdAt: new Date().toISOString().replace('T', ' ').slice(0, 19)
    };
    setOvertimeRecords([newRecord, ...overtimeRecords]);
  };

  const handleOvertimeRequest = (recordId: string, status: OvertimeStatus, rejectionReason?: string) => {
    setOvertimeRecords(prev =>
      prev.map(ot => {
        if (ot.overtimeRecordId === recordId) {
          return {
            ...ot,
            status,
            rejectionReason: status === 'rejected' ? rejectionReason : undefined,
            approverId: currentUser?.userId,
            approverName: currentUser?.fullName
          };
        }
        return ot;
      })
    );
  };

  const cancelOvertimeRequest = (recordId: string) => {
    setOvertimeRecords(prev => prev.filter(ot => ot.overtimeRecordId !== recordId));
  };

  // 4. Cập nhật hồ sơ nhân viên
  const updateEmployeeProfile = (userId: string, updates: Partial<EmployeeDetailed>) => {
    setEmployeeDetails(prev => {
      const current = prev[userId] || getEmployeeDetail(userId);
      return {
        ...prev,
        [userId]: {
          ...current,
          ...updates
        }
      };
    });
  };

  // 5. Tính lương
  const generateMonthlyPayroll = (month: number, year: number) => {
    const calculated: PayrollRecord[] = Object.keys(employeeDetails).map(userId => {
      const detail = employeeDetails[userId] || getEmployeeDetail(userId);
      const baseSalary = detail.salary?.baseSalary || 20000000;
      const standardDays = 26;
      const hourlyRate = baseSalary / (standardDays * 8.0);
      const actualWorkHours = standardDays * 8.0;
      const basicPay = baseSalary;
      const allowancePay = 1500000;
      const deductionPay = Math.round(baseSalary * 0.105);
      const netPay = Math.round(basicPay + allowancePay - deductionPay);

      return {
        payrollId: `payroll-${year}-${month}-${detail.employeeCode}`,
        userId: detail.userId,
        employeeName: detail.fullName,
        employeeCode: detail.employeeCode,
        department: detail.department,
        job: detail.job,
        periodMonth: month,
        periodYear: year,
        baseSalary,
        standardDays,
        actualWorkedDays: standardDays,
        actualWorkHours,
        basicPay,
        overtimePay: 0,
        allowancePay,
        deductionPay,
        netPay,
        status: 'approved',
        calculatedAt: new Date().toISOString().replace('T', ' ').slice(0, 19)
      };
    });

    setPayrolls(calculated);
  };

  return (
    <HRMDataContext.Provider
      value={{
        attendances,
        leaveRequests,
        overtimeRecords,
        payrolls,
        employeeDetails,
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
        generateMonthlyPayroll
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
