package com.assetinfo.playasset.task.stock.svc;

import java.util.Map;

import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.entity.TmpNewsEntity;

import reactor.core.publisher.Flux;

public interface StockSvc {
    public Flux<StockEntity> findAll();
    public Flux<TmpNewsEntity> findAllTmpNews(String keywords);
    public Map<String, Object> getStockEvaulation();
}