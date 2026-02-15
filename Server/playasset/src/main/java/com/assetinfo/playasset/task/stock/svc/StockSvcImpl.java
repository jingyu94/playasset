package com.assetinfo.playasset.task.stock.svc;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.assetinfo.playasset.task.stock.dao.StockDao;
import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.entity.TmpNewsEntity;

import reactor.core.publisher.Flux;

@Service
public class StockSvcImpl implements StockSvc {

    @Autowired
    private StockDao stockDao;

    @Override
    public Flux<StockEntity> findAll() {
        return stockDao.findAll();
    }

    @Override
    public Flux<TmpNewsEntity> findAllTmpNews(String keywords) {
        return stockDao.findAllTmpNews(keywords);
    }

    @Override
    public Map<String, Object> getStockEvaulation() {
        Map<String, Object> map = new HashMap<>();
        map.put("positive", 50);
        map.put("negative", 30);
        map.put("neutral", 20);
        return map;
    }
}
