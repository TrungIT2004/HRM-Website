package com.minhtrung.hrm.common.utils;

import com.minhtrung.hrm.employees.entities.User;
import com.minhtrung.hrm.employees.repositories.UserRepository;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ApproverResolver {

    private final UserRepository userRepository;

    /**
     * Resolve approvers for a request based on the requestor's department and role hierarchy.
     * Returns department heads, executives, and (if requestor is from Executive Leadership) deputy directors.
     * Excludes the requestor themselves.
     */
    public List<UUID> resolveApprovers(UUID requestorId) {
        String requestorDepartment = userRepository.findUsersDepartment(requestorId);
        if (requestorDepartment == null) {
            return List.of();
        }

        // Find department head of requestor's department
        List<User> departmentHeads = userRepository.findByDepartmentNameAndJobTitleStartsWith(requestorDepartment, "Department Head");
        List<User> executives = userRepository.findByDepartmentName("Executive Leadership");

        List<UUID> approvers = departmentHeads.stream()
            .map(User::getUserId)
            .collect(Collectors.toList());

        // Add executives
        approvers.addAll(executives.stream()
            .map(User::getUserId)
            .collect(Collectors.toList()));

        // If requestor is from Executive Leadership, add Deputy Director
        if ("Executive Leadership".equals(requestorDepartment)) {
            List<User> deputyDirectors = userRepository.findByDepartmentNameAndJobTitleContains("Executive Leadership", "Deputy");
            approvers.addAll(deputyDirectors.stream()
                .map(User::getUserId)
                .collect(Collectors.toList()));
        }

        // Remove requestor themselves if they're in the approvers list
        approvers.remove(requestorId);

        return approvers.stream().distinct().collect(Collectors.toList());
    }
}