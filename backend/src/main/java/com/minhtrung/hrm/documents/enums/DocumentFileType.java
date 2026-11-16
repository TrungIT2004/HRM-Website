package com.minhtrung.hrm.documents.enums;

public enum DocumentFileType {
    DOCX, DOC, PDF, XLSX, XLS, PPT, PPTX;

    public static DocumentFileType fromFilename(String filename) {
        if (filename == null || filename.lastIndexOf(".") == -1) return null;
        try {
            return valueOf(filename.substring(filename.lastIndexOf(".") + 1).toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
