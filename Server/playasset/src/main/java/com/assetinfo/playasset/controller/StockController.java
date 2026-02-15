package com.assetinfo.playasset.controller;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.assetinfo.playasset.task.stock.entity.TmpNewsEntity;
import com.assetinfo.playasset.task.stock.svc.StockSvc;

import lombok.NonNull;

@RestController
@RequestMapping("/api/controller/stock")
public class StockController {

    private final StockSvc stockSvc;

    public StockController(@NonNull StockSvc stockSvc) {
        this.stockSvc = stockSvc;
    }

    @GetMapping("/findAllTmpNews")
    public List<TmpNewsEntity> findAllTmpNews(
            @RequestParam(name = "keywords", defaultValue = "SAMSUNG") String keywords) {
        return stockSvc.findAllTmpNews(keywords);
    }

    @GetMapping("/getStockEvaulation")
    public Map<String, Object> getStockEvaulation() {
        return stockSvc.getStockEvaulation();
    }
}
