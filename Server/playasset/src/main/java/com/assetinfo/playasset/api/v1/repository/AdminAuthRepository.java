package com.assetinfo.playasset.api.v1.repository;

import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class AdminAuthRepository {

    private final JdbcTemplate jdbcTemplate;

    public AdminAuthRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public CredentialRow findCredentialByLoginId(String loginId) {
        List<CredentialRow> rows = jdbcTemplate.query(
                """
                        SELECT u.user_id, u.email AS login_id, u.display_name, u.status,
                               c.password_hash, c.hash_algorithm
                        FROM users u
                        JOIN user_auth_credentials c ON c.user_id = u.user_id
                        WHERE u.email = ?
                        LIMIT 1
                        """,
                (rs, rowNum) -> new CredentialRow(
                        rs.getLong("user_id"),
                        rs.getString("login_id"),
                        rs.getString("display_name"),
                        rs.getString("status"),
                        rs.getString("password_hash"),
                        rs.getString("hash_algorithm")),
                loginId);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Set<String> findRolesByUserId(long userId) {
        return jdbcTemplate.query(
                "SELECT role_code FROM user_roles WHERE user_id = ?",
                (rs, rowNum) -> rs.getString("role_code"),
                userId).stream().collect(Collectors.toSet());
    }

    public void createSession(String sessionToken, long userId, LocalDateTime expiresAt) {
        jdbcTemplate.update(
                """
                        INSERT INTO auth_sessions(session_token, user_id, expires_at)
                        VALUES (?, ?, ?)
                        """,
                sessionToken,
                userId,
                Timestamp.valueOf(expiresAt));
    }

    public SessionRow findValidSession(String sessionToken) {
        List<SessionRow> rows = jdbcTemplate.query(
                """
                        SELECT s.session_token, s.user_id, s.expires_at,
                               u.email AS login_id, u.display_name, u.status
                        FROM auth_sessions s
                        JOIN users u ON u.user_id = s.user_id
                        WHERE s.session_token = ?
                          AND s.revoked_at IS NULL
                          AND s.expires_at > NOW()
                          AND u.status = 'ACTIVE'
                        LIMIT 1
                        """,
                (rs, rowNum) -> new SessionRow(
                        rs.getString("session_token"),
                        rs.getLong("user_id"),
                        rs.getString("login_id"),
                        rs.getString("display_name"),
                        rs.getTimestamp("expires_at").toLocalDateTime()),
                sessionToken);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public void revokeSession(String sessionToken) {
        jdbcTemplate.update(
                """
                        UPDATE auth_sessions
                        SET revoked_at = NOW()
                        WHERE session_token = ?
                          AND revoked_at IS NULL
                        """,
                sessionToken);
    }

    public List<AdminUserRow> loadUsersWithRoles() {
        List<AdminUserRow> users = jdbcTemplate.query(
                """
                        SELECT user_id, email AS login_id, display_name, status
                        FROM users
                        ORDER BY user_id
                        """,
                (rs, rowNum) -> new AdminUserRow(
                        rs.getLong("user_id"),
                        rs.getString("login_id"),
                        rs.getString("display_name"),
                        rs.getString("status"),
                        new ArrayList<>()));

        if (users.isEmpty()) {
            return users;
        }

        Map<Long, List<String>> roleMap = new HashMap<>();
        List<UserRoleRow> roles = jdbcTemplate.query(
                "SELECT user_id, role_code FROM user_roles ORDER BY user_id, role_code",
                (rs, rowNum) -> new UserRoleRow(
                        rs.getLong("user_id"),
                        rs.getString("role_code")));
        for (UserRoleRow role : roles) {
            roleMap.computeIfAbsent(role.userId(), k -> new ArrayList<>()).add(role.roleCode());
        }

        for (AdminUserRow user : users) {
            List<String> userRoles = roleMap.getOrDefault(user.userId(), List.of());
            user.roles().addAll(userRoles);
        }
        return users;
    }

    public boolean userExists(long userId) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE user_id = ?",
                Integer.class,
                userId);
        return count != null && count > 0;
    }

    public void replaceUserRoles(long userId, Set<String> roles) {
        jdbcTemplate.update("DELETE FROM user_roles WHERE user_id = ?", userId);
        if (roles == null || roles.isEmpty()) {
            return;
        }
        jdbcTemplate.batchUpdate(
                "INSERT INTO user_roles(user_id, role_code) VALUES (?, ?)",
                roles,
                roles.size(),
                (ps, role) -> {
                    ps.setLong(1, userId);
                    ps.setString(2, role);
                });
    }

    public PolicyRow findPolicyForUpdate(String serviceKey) {
        List<PolicyRow> rows = jdbcTemplate.query(
                """
                        SELECT service_key, display_name, daily_limit, is_enabled
                        FROM paid_service_policies
                        WHERE service_key = ?
                        FOR UPDATE
                        """,
                (rs, rowNum) -> new PolicyRow(
                        rs.getString("service_key"),
                        rs.getString("display_name"),
                        rs.getInt("daily_limit"),
                        rs.getBoolean("is_enabled")),
                serviceKey);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Integer findUsageForUpdate(LocalDate usageDate, String serviceKey) {
        List<Integer> rows = jdbcTemplate.query(
                """
                        SELECT used_count
                        FROM paid_service_daily_usage
                        WHERE usage_date = ? AND service_key = ?
                        FOR UPDATE
                        """,
                (rs, rowNum) -> rs.getInt("used_count"),
                usageDate,
                serviceKey);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public void insertUsage(LocalDate usageDate, String serviceKey, int usedCount) {
        jdbcTemplate.update(
                """
                        INSERT INTO paid_service_daily_usage(usage_date, service_key, used_count)
                        VALUES (?, ?, ?)
                        """,
                usageDate,
                serviceKey,
                usedCount);
    }

    public void updateUsage(LocalDate usageDate, String serviceKey, int usedCount) {
        jdbcTemplate.update(
                """
                        UPDATE paid_service_daily_usage
                        SET used_count = ?
                        WHERE usage_date = ? AND service_key = ?
                        """,
                usedCount,
                usageDate,
                serviceKey);
    }

    public List<PolicyUsageRow> loadPoliciesWithUsage(LocalDate usageDate) {
        return jdbcTemplate.query(
                """
                        SELECT p.service_key, p.display_name, p.daily_limit, p.is_enabled,
                               COALESCE(u.used_count, 0) AS used_count
                        FROM paid_service_policies p
                        LEFT JOIN paid_service_daily_usage u
                          ON u.service_key = p.service_key
                         AND u.usage_date = ?
                        ORDER BY p.service_key
                        """,
                (rs, rowNum) -> new PolicyUsageRow(
                        rs.getString("service_key"),
                        rs.getString("display_name"),
                        rs.getInt("daily_limit"),
                        rs.getBoolean("is_enabled"),
                        rs.getInt("used_count")),
                usageDate);
    }

    public void upsertPolicy(String serviceKey, String displayName, int dailyLimit, boolean enabled) {
        jdbcTemplate.update(
                """
                        INSERT INTO paid_service_policies(service_key, display_name, daily_limit, is_enabled)
                        VALUES (?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE
                            display_name = VALUES(display_name),
                            daily_limit = VALUES(daily_limit),
                            is_enabled = VALUES(is_enabled),
                            updated_at = CURRENT_TIMESTAMP
                        """,
                serviceKey,
                displayName,
                dailyLimit,
                enabled ? 1 : 0);
    }

    public Map<String, Integer> loadUsageByDate(LocalDate usageDate) {
        Map<String, Integer> result = new LinkedHashMap<>();
        List<DailyUsageRow> rows = jdbcTemplate.query(
                "SELECT service_key, used_count FROM paid_service_daily_usage WHERE usage_date = ? ORDER BY service_key",
                (rs, rowNum) -> new DailyUsageRow(
                        rs.getString("service_key"),
                        rs.getInt("used_count")),
                usageDate);
        for (DailyUsageRow row : rows) {
            result.put(row.serviceKey(), row.usedCount());
        }
        return result;
    }

    public record CredentialRow(
            long userId,
            String loginId,
            String displayName,
            String status,
            String passwordHash,
            String hashAlgorithm) {
    }

    public record SessionRow(
            String sessionToken,
            long userId,
            String loginId,
            String displayName,
            LocalDateTime expiresAt) {
    }

    public record AdminUserRow(
            long userId,
            String loginId,
            String displayName,
            String status,
            List<String> roles) {
    }

    public record PolicyRow(
            String serviceKey,
            String displayName,
            int dailyLimit,
            boolean enabled) {
    }

    public record PolicyUsageRow(
            String serviceKey,
            String displayName,
            int dailyLimit,
            boolean enabled,
            int usedCount) {
    }

    private record UserRoleRow(
            long userId,
            String roleCode) {
    }

    private record DailyUsageRow(
            String serviceKey,
            int usedCount) {
    }
}
