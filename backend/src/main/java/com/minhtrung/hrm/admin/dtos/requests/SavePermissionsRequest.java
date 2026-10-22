package com.minhtrung.hrm.admin.dtos.requests;

import java.util.List;

import lombok.Data;

@Data
public class SavePermissionsRequest {
    private List<String> permissions;
}
