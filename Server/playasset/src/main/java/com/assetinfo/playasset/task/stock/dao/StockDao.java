package com.assetinfo.playasset.task.stock.dao;

import java.util.List;

import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.entity.TmpNewsEntity;

@Repository
public class StockDao {

    private final JdbcTemplate jdbcTemplate;
    private final BeanPropertyRowMapper<StockEntity> stockRowMapper = new BeanPropertyRowMapper<>(StockEntity.class);
    private final BeanPropertyRowMapper<TmpNewsEntity> newsRowMapper = new BeanPropertyRowMapper<>(TmpNewsEntity.class);

    public StockDao(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<StockEntity> findAll() {
        return jdbcTemplate.query("""
                SELECT
                    symbol AS stock_id,
                    name AS stock_name,
                    market AS srch_tag,
                    'SYSTEM' AS reg_id,
                    DATE(created_at) AS reg_dtm,
                    'SYSTEM' AS udt_id,
                    DATE(updated_at) AS udt_dtm
                FROM assets
                WHERE is_active = 1
                ORDER BY symbol
                """, stockRowMapper);
    }

    public List<TmpNewsEntity> findAllTmpNews(String keywords) {
        String sql = """
                SELECT article_id AS idx, title
                FROM news_articles
                WHERE LOWER(title) LIKE LOWER(CONCAT('%', ?, '%'))
                ORDER BY published_at DESC
                LIMIT 50
                """;
        return jdbcTemplate.query(sql, newsRowMapper, keywords);
    }
}
