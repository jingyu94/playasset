package com.assetinfo.playasset.api.v1.repository;

import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
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
                """
                        SELECT role_code
                        FROM user_roles
                        WHERE user_id = ?
                        UNION
                        SELECT gp.permission_code AS role_code
                        FROM TM_AUTH_GROUP_USER_MAP gu
                        JOIN TM_AUTH_GROUP_PERMISSION_MAP gp ON gp.group_id = gu.group_id
                        WHERE gu.user_id = ?
                          AND gu.use_yn = 1
                        """,
                (rs, rowNum) -> rs.getString("role_code"),
                userId,
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
                        SELECT
                            u.user_id,
                            u.email AS login_id,
                            u.display_name,
                            u.status,
                            gu.group_id,
                            g.group_name
                        FROM users u
                        LEFT JOIN TM_AUTH_GROUP_USER_MAP gu
                          ON gu.user_id = u.user_id
                         AND gu.use_yn = 1
                        LEFT JOIN TM_AUTH_GROUP_MAIN g
                          ON g.group_id = gu.group_id
                        ORDER BY u.user_id
                        """,
                (rs, rowNum) -> new AdminUserRow(
                        rs.getLong("user_id"),
                        rs.getString("login_id"),
                        rs.getString("display_name"),
                        rs.getString("status"),
                        rs.getObject("group_id") == null ? null : rs.getLong("group_id"),
                        rs.getString("group_name"),
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

    public List<AdminGroupRow> loadGroupsWithPermissions() {
        List<AdminGroupRow> groups = jdbcTemplate.query(
                """
                        SELECT
                            g.group_id,
                            g.group_key,
                            g.group_name,
                            g.group_desc,
                            g.use_yn,
                            COALESCE(mu.member_count, 0) AS member_count
                        FROM TM_AUTH_GROUP_MAIN g
                        LEFT JOIN (
                            SELECT group_id, COUNT(*) AS member_count
                            FROM TM_AUTH_GROUP_USER_MAP
                            WHERE use_yn = 1
                            GROUP BY group_id
                        ) mu ON mu.group_id = g.group_id
                        ORDER BY g.group_id
                        """,
                (rs, rowNum) -> new AdminGroupRow(
                        rs.getLong("group_id"),
                        rs.getString("group_key"),
                        rs.getString("group_name"),
                        rs.getString("group_desc"),
                        rs.getBoolean("use_yn"),
                        rs.getInt("member_count"),
                        new ArrayList<>()));

        if (groups.isEmpty()) {
            return groups;
        }

        Map<Long, List<String>> permissionMap = new HashMap<>();
        List<GroupPermissionRow> permissions = jdbcTemplate.query(
                """
                        SELECT group_id, permission_code
                        FROM TM_AUTH_GROUP_PERMISSION_MAP
                        ORDER BY group_id, permission_code
                        """,
                (rs, rowNum) -> new GroupPermissionRow(
                        rs.getLong("group_id"),
                        rs.getString("permission_code")));
        for (GroupPermissionRow row : permissions) {
            permissionMap.computeIfAbsent(row.groupId(), k -> new ArrayList<>())
                    .add(row.permissionCode());
        }

        for (AdminGroupRow group : groups) {
            group.permissions().addAll(permissionMap.getOrDefault(group.groupId(), List.of()));
        }
        return groups;
    }

    public boolean userExists(long userId) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE user_id = ?",
                Integer.class,
                userId);
        return count != null && count > 0;
    }

    public boolean groupExists(long groupId) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM TM_AUTH_GROUP_MAIN WHERE group_id = ?",
                Integer.class,
                groupId);
        return count != null && count > 0;
    }

    public Set<String> loadAuthPermissionCodes() {
        return jdbcTemplate.query(
                """
                        SELECT code_cd
                        FROM TM_STD_CODE_ITEM_MAIN
                        WHERE code_group_cd = 'AUTH_PERMISSION'
                          AND use_yn = 1
                        """,
                (rs, rowNum) -> rs.getString("code_cd")).stream().collect(Collectors.toSet());
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

    public void replaceGroupPermissions(long groupId, Set<String> permissions) {
        jdbcTemplate.update("DELETE FROM TM_AUTH_GROUP_PERMISSION_MAP WHERE group_id = ?", groupId);
        if (permissions == null || permissions.isEmpty()) {
            return;
        }

        jdbcTemplate.batchUpdate(
                "INSERT INTO TM_AUTH_GROUP_PERMISSION_MAP(group_id, permission_code) VALUES (?, ?)",
                permissions,
                permissions.size(),
                (ps, permission) -> {
                    ps.setLong(1, groupId);
                    ps.setString(2, permission);
                });
    }

    public void upsertUserGroup(long userId, long groupId) {
        jdbcTemplate.update(
                """
                        INSERT INTO TM_AUTH_GROUP_USER_MAP(user_id, group_id, use_yn, created_at, updated_at)
                        VALUES (?, ?, 1, NOW(), NOW())
                        ON DUPLICATE KEY UPDATE
                            group_id = VALUES(group_id),
                            use_yn = 1,
                            updated_at = NOW()
                        """,
                userId,
                groupId);
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

    public boolean runtimeConfigGroupExists(String groupCode) {
        Integer count = jdbcTemplate.queryForObject(
                """
                        SELECT COUNT(*)
                        FROM TM_STD_CODE_MAIN
                        WHERE code_group_cd = ?
                        """,
                Integer.class,
                groupCode);
        return count != null && count > 0;
    }

    public List<RuntimeConfigRow> loadRuntimeConfigs(String groupCode) {
        if (groupCode == null || groupCode.isBlank()) {
            return jdbcTemplate.query(
                    """
                            SELECT runtime_config_id, config_group_cd, config_key, config_name, value_type_cd,
                                   config_value, config_desc, sort_no, editable_yn, use_yn, updated_at
                            FROM TM_STD_RUNTIME_CONFIG_MAIN
                            ORDER BY config_group_cd, sort_no, runtime_config_id
                            """,
                    (rs, rowNum) -> new RuntimeConfigRow(
                            rs.getLong("runtime_config_id"),
                            rs.getString("config_group_cd"),
                            rs.getString("config_key"),
                            rs.getString("config_name"),
                            rs.getString("value_type_cd"),
                            rs.getString("config_value"),
                            rs.getString("config_desc"),
                            rs.getInt("sort_no"),
                            rs.getBoolean("editable_yn"),
                            rs.getBoolean("use_yn"),
                            Objects.toString(rs.getTimestamp("updated_at"), null)));
        }
        return jdbcTemplate.query(
                """
                        SELECT runtime_config_id, config_group_cd, config_key, config_name, value_type_cd,
                               config_value, config_desc, sort_no, editable_yn, use_yn, updated_at
                        FROM TM_STD_RUNTIME_CONFIG_MAIN
                        WHERE config_group_cd = ?
                        ORDER BY sort_no, runtime_config_id
                        """,
                (rs, rowNum) -> new RuntimeConfigRow(
                        rs.getLong("runtime_config_id"),
                        rs.getString("config_group_cd"),
                        rs.getString("config_key"),
                        rs.getString("config_name"),
                        rs.getString("value_type_cd"),
                        rs.getString("config_value"),
                        rs.getString("config_desc"),
                        rs.getInt("sort_no"),
                        rs.getBoolean("editable_yn"),
                        rs.getBoolean("use_yn"),
                        Objects.toString(rs.getTimestamp("updated_at"), null)),
                groupCode);
    }

    public void upsertRuntimeConfig(
            String groupCode,
            String configKey,
            String configName,
            String valueTypeCd,
            String configValue,
            String configDesc,
            boolean enabled) {
        Integer nextSort = jdbcTemplate.queryForObject(
                """
                        SELECT COALESCE(MAX(sort_no), 0) + 10
                        FROM TM_STD_RUNTIME_CONFIG_MAIN
                        WHERE config_group_cd = ?
                        """,
                Integer.class,
                groupCode);
        int sortNo = nextSort == null ? 100 : nextSort;

        jdbcTemplate.update(
                """
                        INSERT INTO TM_STD_RUNTIME_CONFIG_MAIN(
                            config_group_cd,
                            config_key,
                            config_name,
                            value_type_cd,
                            config_value,
                            config_desc,
                            sort_no,
                            editable_yn,
                            use_yn,
                            created_at,
                            updated_at
                        )
                        VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, NOW(), NOW())
                        ON DUPLICATE KEY UPDATE
                            config_name = VALUES(config_name),
                            value_type_cd = VALUES(value_type_cd),
                            config_value = VALUES(config_value),
                            config_desc = VALUES(config_desc),
                            use_yn = VALUES(use_yn),
                            updated_at = NOW()
                        """,
                groupCode,
                configKey,
                configName,
                valueTypeCd,
                configValue,
                configDesc,
                sortNo,
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
            Long groupId,
            String groupName,
            List<String> roles) {
    }

    public record AdminGroupRow(
            long groupId,
            String groupKey,
            String groupName,
            String groupDesc,
            boolean enabled,
            int memberCount,
            List<String> permissions) {
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

    public record RuntimeConfigRow(
            long runtimeConfigId,
            String configGroupCd,
            String configKey,
            String configName,
            String valueTypeCd,
            String configValue,
            String configDesc,
            int sortNo,
            boolean editable,
            boolean enabled,
            String updatedAt) {
    }

    private record UserRoleRow(
            long userId,
            String roleCode) {
    }

    private record GroupPermissionRow(
            long groupId,
            String permissionCode) {
    }

    private record DailyUsageRow(
            String serviceKey,
            int usedCount) {
    }
}
