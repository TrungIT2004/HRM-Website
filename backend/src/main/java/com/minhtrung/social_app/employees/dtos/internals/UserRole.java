package com.minhtrung.social_app.employees.dtos.internals;

import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@AllArgsConstructor
@Getter
@Setter
public class UserRole {
    private UUID userId;
    private String department;
    private String job;
}
