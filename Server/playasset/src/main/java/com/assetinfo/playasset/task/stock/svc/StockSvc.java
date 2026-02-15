package com.assetinfo.playasset.task.stock.svc;

import java.util.List;
import java.util.Map;

import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.entity.TmpNewsEntity;

public interface StockSvc {
    List<StockEntity> findAll();
    List<TmpNewsEntity> findAllTmpNews(String keywords);
    Map<String, Object> getStockEvaulation();
}
