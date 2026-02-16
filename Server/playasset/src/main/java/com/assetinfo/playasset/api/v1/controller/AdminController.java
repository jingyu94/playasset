package com.assetinfo.playasset.api.v1.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.assetinfo.playasset.api.v1.admin.AdminService;
import com.assetinfo.playasset.api.v1.auth.Authz;
import com.assetinfo.playasset.api.v1.dto.AdminGroupResponse;
import com.assetinfo.playasset.api.v1.dto.AdminUserResponse;
import com.assetinfo.playasset.api.v1.dto.ApiResponse;
import com.assetinfo.playasset.api.v1.dto.PaidServicePolicyResponse;
import com.assetinfo.playasset.api.v1.dto.RuntimeConfigResponse;
import com.assetinfo.playasset.api.v1.dto.UpdateGroupPermissionsRequest;
import com.assetinfo.playasset.api.v1.dto.UpdatePaidServicePolicyRequest;
import com.assetinfo.playasset.api.v1.dto.UpdateRuntimeConfigRequest;
import com.assetinfo.playasset.api.v1.dto.UpdateUserGroupRequest;
import com.assetinfo.playasset.api.v1.dto.UpdateUserRolesRequest;

import jakarta.validation.Valid;

@Validated
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/paid-services/policies")
    public ApiResponse<List<PaidServicePolicyResponse>> paidServicePolicies(
            @RequestParam(name = "date", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.loadPolicies(date));
    }

    @PutMapping("/paid-services/policies/{serviceKey}")
    public ApiResponse<PaidServicePolicyResponse> updatePaidServicePolicy(
            @PathVariable String serviceKey,
            @Valid @RequestBody UpdatePaidServicePolicyRequest request) {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.updatePolicy(serviceKey, request));
    }

    @GetMapping("/users")
    public ApiResponse<List<AdminUserResponse>> users() {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.loadUsers());
    }

    @GetMapping("/groups")
    public ApiResponse<List<AdminGroupResponse>> groups() {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.loadGroups());
    }

    @PutMapping("/users/{userId}/roles")
    public ApiResponse<AdminUserResponse> replaceUserRoles(
            @PathVariable long userId,
            @Valid @RequestBody UpdateUserRolesRequest request) {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.replaceUserRoles(userId, request.roles()));
    }

    @PutMapping("/users/{userId}/group")
    public ApiResponse<AdminUserResponse> updateUserGroup(
            @PathVariable long userId,
            @Valid @RequestBody UpdateUserGroupRequest request) {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.updateUserGroup(userId, request));
    }

    @PutMapping("/groups/{groupId}/permissions")
    public ApiResponse<AdminGroupResponse> replaceGroupPermissions(
            @PathVariable long groupId,
            @Valid @RequestBody UpdateGroupPermissionsRequest request) {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.replaceGroupPermissions(groupId, request));
    }

    @GetMapping("/runtime-configs")
    public ApiResponse<List<RuntimeConfigResponse>> runtimeConfigs(
            @RequestParam(name = "groupCode", required = false) String groupCode) {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.loadRuntimeConfigs(groupCode));
    }

    @PutMapping("/runtime-configs/{groupCode}/{configKey}")
    public ApiResponse<RuntimeConfigResponse> upsertRuntimeConfig(
            @PathVariable String groupCode,
            @PathVariable String configKey,
            @Valid @RequestBody UpdateRuntimeConfigRequest request) {
        Authz.requireAdmin();
        return ApiResponse.ok(adminService.upsertRuntimeConfig(groupCode, configKey, request));
    }
}
