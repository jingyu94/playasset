package com.assetinfo.playasset.api.v1.admin;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.assetinfo.playasset.api.v1.dto.AdminUserResponse;
import com.assetinfo.playasset.api.v1.dto.PaidServicePolicyResponse;
import com.assetinfo.playasset.api.v1.dto.UpdatePaidServicePolicyRequest;
import com.assetinfo.playasset.api.v1.repository.AdminAuthRepository;

@Service
public class AdminService {

    private final AdminAuthRepository repository;

    public AdminService(AdminAuthRepository repository) {
        this.repository = repository;
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
                        row.roles().stream().sorted().toList()))
                .toList();
    }

    @Transactional
    public AdminUserResponse replaceUserRoles(long userId, List<String> requestedRoles) {
        if (!repository.userExists(userId)) {
            throw new IllegalArgumentException("존재하지 않는 사용자입니다.");
        }

        Set<String> roles = requestedRoles.stream()
                .map(role -> role == null ? "" : role.trim().toUpperCase())
                .filter(role -> !role.isBlank())
                .peek(role -> {
                    if (!isAllowedRole(role)) {
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

    private String normalizeServiceKey(String serviceKey) {
        if (serviceKey == null || serviceKey.isBlank()) {
            throw new IllegalArgumentException("serviceKey는 필수입니다.");
        }
        return serviceKey.trim().toUpperCase();
    }

    private boolean isAllowedRole(String role) {
        return "ADMIN".equals(role) || "USER".equals(role) || "OPERATOR".equals(role);
    }
}
