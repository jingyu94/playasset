package com.assetinfo.playasset.task.stock.svc;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.assetinfo.playasset.api.v1.dto.SentimentSnapshot;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;
import com.assetinfo.playasset.task.stock.dao.StockDao;
import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.entity.TmpNewsEntity;

@Service
public class StockSvcImpl implements StockSvc {

    @Autowired
    private StockDao stockDao;

    @Autowired
    private PlatformQueryRepository platformQueryRepository;

    @Override
    public List<StockEntity> findAll() {
        return stockDao.findAll();
    }

    @Override
    public List<TmpNewsEntity> findAllTmpNews(String keywords) {
        return stockDao.findAllTmpNews(keywords);
    }

    @Override
    public Map<String, Object> getStockEvaulation() {
        SentimentSnapshot snapshot = platformQueryRepository.loadSentimentSnapshot();
        Map<String, Object> map = new HashMap<>();
        map.put("positive", snapshot.positive());
        map.put("negative", snapshot.negative());
        map.put("neutral", snapshot.neutral());
        return map;
    }
}
