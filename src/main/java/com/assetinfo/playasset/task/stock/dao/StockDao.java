package com.assetinfo.playasset.task.stock.dao;

import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;

import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.entity.TmpNewsEntity;

import reactor.core.publisher.Flux;

@Repository
public interface StockDao extends ReactiveCrudRepository<StockEntity, Long> {

    @Query("SELECT * FROM TM_STOCK")
    Flux<StockEntity> findAll();

    @Query("SELECT * FROM TMP_NEWS_TITLE WHERE title LIKE lower(concat('%', concat(:keywords, '%')))")
    Flux<TmpNewsEntity> findAllTmpNews(String keywords);
}
