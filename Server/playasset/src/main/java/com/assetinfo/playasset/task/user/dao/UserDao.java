package com.assetinfo.playasset.task.user.dao;

import java.util.List;

import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import com.assetinfo.playasset.task.user.entity.UserEntity;

@Repository
public class UserDao {

    private final JdbcTemplate jdbcTemplate;
    private final BeanPropertyRowMapper<UserEntity> rowMapper = new BeanPropertyRowMapper<>(UserEntity.class);

    public UserDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<UserEntity> findAll() {
        return jdbcTemplate.query("""
                SELECT
                    CAST(user_id AS CHAR) AS user_id,
                    '' AS user_password,
                    display_name AS user_name,
                    NULL AS user_cp,
                    'USER' AS user_auth,
                    'SYSTEM' AS reg_id,
                    DATE(created_at) AS reg_dtm,
                    'SYSTEM' AS udt_id,
                    DATE(updated_at) AS udt_dtm
                FROM users
                ORDER BY user_id
                """, rowMapper);
    }

    public UserEntity findOne() {
        return jdbcTemplate.query("""
                SELECT
                    CAST(user_id AS CHAR) AS user_id,
                    '' AS user_password,
                    display_name AS user_name,
                    NULL AS user_cp,
                    'USER' AS user_auth,
                    'SYSTEM' AS reg_id,
                    DATE(created_at) AS reg_dtm,
                    'SYSTEM' AS udt_id,
                    DATE(updated_at) AS udt_dtm
                FROM users
                ORDER BY user_id
                LIMIT 1
                """, rowMapper).stream().findFirst().orElse(null);
    }
}
