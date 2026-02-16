package com.assetinfo.playasset.api.v1.admin;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.assetinfo.playasset.api.v1.dto.AdminGroupResponse;
import com.assetinfo.playasset.api.v1.dto.AdminUserResponse;
import com.assetinfo.playasset.api.v1.dto.PaidServicePolicyResponse;
import com.assetinfo.playasset.api.v1.dto.RuntimeConfigResponse;
import com.assetinfo.playasset.api.v1.dto.UpdateGroupPermissionsRequest;
import com.assetinfo.playasset.api.v1.dto.UpdatePaidServicePolicyRequest;
import com.assetinfo.playasset.api.v1.dto.UpdateRuntimeConfigRequest;
import com.assetinfo.playasset.api.v1.dto.UpdateUserGroupRequest;
import com.assetinfo.playasset.api.v1.repository.AdminAuthRepository;
import com.assetinfo.playasset.api.v1.service.RuntimeConfigService;
import com.assetinfo.playasset.config.CacheNames;

@Service
public class AdminService {

    private final AdminAuthRepository repository;
    private final RuntimeConfigService runtimeConfigService;

    public AdminService(AdminAuthRepository repository, RuntimeConfigService runtimeConfigService) {
        this.repository = repository;
        this.runtimeConfigService = runtimeConfigService;
    }

    public List<PaidServicePolicyResponse> loadPolicies(LocalDate date) {
        LocalDate target = date == null ? LocalDate.now() : date;
        return repository.loadPoliciesWithUsage(target).stream()
                .map(row -> {
                    int remaining = Math.max(0, row.dailyLimit() - row.usedCount());
                    return new PaidServicePolicyResponse(
                            row.serviceKey(),
                            row.displayName(),
                            row.dailyLimit(),
                            row.enabled(),
                            row.usedCount(),
                            remaining);
                })
                .toList();
    }

    @Transactional
    public PaidServicePolicyResponse updatePolicy(String serviceKey, UpdatePaidServicePolicyRequest request) {
        String normalizedKey = normalizeServiceKey(serviceKey);
        repository.upsertPolicy(normalizedKey, request.displayName().trim(), request.dailyLimit(), request.enabled());
        return loadPolicies(LocalDate.now()).stream()
                .filter(policy -> policy.serviceKey().equals(normalizedKey))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("정책 저장 후 조회에 실패했습니다."));
    }

    public List<AdminUserResponse> loadUsers() {
        return repository.loadUsersWithRoles().stream()
                .map(row -> new AdminUserResponse(
                        row.userId(),
                        row.loginId(),
                        row.displayName(),
                        row.status(),
                        row.groupId(),
                        row.groupName(),
                        row.roles().stream().sorted().toList()))
                .toList();
    }

    public List<AdminGroupResponse> loadGroups() {
        return repository.loadGroupsWithPermissions().stream()
                .map(row -> new AdminGroupResponse(
                        row.groupId(),
                        row.groupKey(),
                        row.groupName(),
                        row.groupDesc(),
                        row.enabled(),
                        row.memberCount(),
                        row.permissions().stream().sorted().toList()))
                .toList();
    }

    @Transactional
    public AdminGroupResponse replaceGroupPermissions(long groupId, UpdateGroupPermissionsRequest request) {
        if (!repository.groupExists(groupId)) {
            throw new IllegalArgumentException("존재하지 않는 권한 그룹입니다.");
        }

        Set<String> allowedPermissions = repository.loadAuthPermissionCodes().stream()
                .map(code -> code.trim().toUpperCase())
                .collect(Collectors.toSet());
        if (allowedPermissions.isEmpty()) {
            throw new IllegalStateException("AUTH_PERMISSION 기준정보가 비어 있습니다.");
        }

        Set<String> permissions = request.permissions().stream()
                .map(permission -> permission == null ? "" : permission.trim().toUpperCase())
                .filter(permission -> !permission.isBlank())
                .peek(permission -> {
                    if (!allowedPermissions.contains(permission)) {
                        throw new IllegalArgumentException("허용되지 않은 권한 코드입니다: " + permission);
                    }
                })
                .collect(Collectors.toSet());

        if (permissions.isEmpty()) {
            throw new IllegalArgumentException("최소 1개 이상의 권한 코드가 필요합니다.");
        }

        repository.replaceGroupPermissions(groupId, permissions);
        return loadGroups().stream()
                .filter(group -> group.groupId() == groupId)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("변경된 그룹을 조회할 수 없습니다."));
    }

    @Transactional
    public AdminUserResponse updateUserGroup(long userId, UpdateUserGroupRequest request) {
        if (!repository.userExists(userId)) {
            throw new IllegalArgumentException("존재하지 않는 사용자입니다.");
        }
        if (!repository.groupExists(request.groupId())) {
            throw new IllegalArgumentException("존재하지 않는 권한 그룹입니다.");
        }

        repository.upsertUserGroup(userId, request.groupId());
        return loadUsers().stream()
                .filter(user -> user.userId() == userId)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("변경된 사용자 정보를 조회할 수 없습니다."));
    }

    @Transactional
    public AdminUserResponse replaceUserRoles(long userId, List<String> requestedRoles) {
        if (!repository.userExists(userId)) {
            throw new IllegalArgumentException("존재하지 않는 사용자입니다.");
        }

        Set<String> loadedRoles = repository.loadAuthPermissionCodes().stream()
                .map(role -> role.trim().toUpperCase())
                .collect(Collectors.toSet());
        final Set<String> allowedRoles = loadedRoles.isEmpty()
                ? Set.of("ADMIN", "OPERATOR", "USER")
                : loadedRoles;

        Set<String> roles = requestedRoles.stream()
                .map(role -> role == null ? "" : role.trim().toUpperCase())
                .filter(role -> !role.isBlank())
                .peek(role -> {
                    if (!allowedRoles.contains(role)) {
                        throw new IllegalArgumentException("허용되지 않은 role 입니다: " + role);
                    }
                })
                .collect(Collectors.toSet());

        if (roles.isEmpty()) {
            throw new IllegalArgumentException("최소 1개 이상의 role 이 필요합니다.");
        }

        repository.replaceUserRoles(userId, roles);

        return loadUsers().stream()
                .filter(user -> user.userId() == userId)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("역할 변경 후 사용자 조회에 실패했습니다."));
    }

    public List<RuntimeConfigResponse> loadRuntimeConfigs(String groupCode) {
        String normalizedGroup = groupCode == null ? null : normalizeGroupCode(groupCode);
        if (normalizedGroup != null && !repository.runtimeConfigGroupExists(normalizedGroup)) {
            throw new IllegalArgumentException("존재하지 않는 기준정보 그룹입니다: " + normalizedGroup);
        }
        return repository.loadRuntimeConfigs(normalizedGroup).stream()
                .map(row -> new RuntimeConfigResponse(
                        row.runtimeConfigId(),
                        row.configGroupCd(),
                        row.configKey(),
                        row.configName(),
                        row.valueTypeCd(),
                        row.configValue(),
                        row.configDesc(),
                        row.sortNo(),
                        row.editable(),
                        row.enabled(),
                        row.updatedAt()))
                .toList();
    }

    @Caching(evict = {
            @CacheEvict(cacheNames = CacheNames.RUNTIME_CONFIG, key = "#groupCode.toUpperCase()"),
            @CacheEvict(cacheNames = CacheNames.PORTFOLIO_ADVICE, allEntries = true),
            @CacheEvict(cacheNames = CacheNames.PORTFOLIO_SIMULATION, allEntries = true)
    })
    @Transactional
    public RuntimeConfigResponse upsertRuntimeConfig(String groupCode, String configKey, UpdateRuntimeConfigRequest request) {
        String normalizedGroup = normalizeGroupCode(groupCode);
        if (!repository.runtimeConfigGroupExists(normalizedGroup)) {
            throw new IllegalArgumentException("존재하지 않는 기준정보 그룹입니다: " + normalizedGroup);
        }

        String normalizedKey = normalizeConfigKey(configKey);
        String normalizedType = normalizeValueType(request.valueTypeCd());
        repository.upsertRuntimeConfig(
                normalizedGroup,
                normalizedKey,
                request.configName().trim(),
                normalizedType,
                request.configValue().trim(),
                request.configDesc() == null ? "" : request.configDesc().trim(),
                request.enabled());
        runtimeConfigService.evictGroup(normalizedGroup);
        return loadRuntimeConfigs(normalizedGroup).stream()
                .filter(config -> config.configKey().equals(normalizedKey))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("기준정보 저장 후 조회에 실패했습니다."));
    }

    private String normalizeServiceKey(String serviceKey) {
        if (serviceKey == null || serviceKey.isBlank()) {
            throw new IllegalArgumentException("serviceKey는 필수입니다.");
        }
        return serviceKey.trim().toUpperCase();
    }

    private String normalizeGroupCode(String groupCode) {
        if (groupCode == null || groupCode.isBlank()) {
            throw new IllegalArgumentException("groupCode는 필수입니다.");
        }
        return groupCode.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizeConfigKey(String configKey) {
        if (configKey == null || configKey.isBlank()) {
            throw new IllegalArgumentException("configKey는 필수입니다.");
        }
        return configKey.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizeValueType(String valueTypeCd) {
        if (valueTypeCd == null || valueTypeCd.isBlank()) {
            throw new IllegalArgumentException("valueTypeCd는 필수입니다.");
        }
        String normalized = valueTypeCd.trim().toUpperCase(Locale.ROOT);
        Set<String> allowed = Set.of("STRING", "NUMBER", "BOOLEAN", "JSON");
        if (!allowed.contains(normalized)) {
            throw new IllegalArgumentException("허용되지 않은 valueTypeCd 입니다: " + normalized);
        }
        return normalized;
    }
}
