package com.minhtrung.hrm.documents.dtos.requests;

import com.minhtrung.hrm.documents.enums.DocumentCategory;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UpsertDocumentRequest {
    @NotBlank(message = "Tiêu đề hiển thị không được để trống")
    @Size(max = 255, message = "Tiêu đề không được vượt quá 255 ký tự")
    private String documentTitle;

    @NotNull(message = "Nhóm đơn không được để trống")
    private DocumentCategory category;

    @Size(max = 2000, message = "Tóm tắt không được vượt quá 2000 ký tự")
    private String summary;
}
