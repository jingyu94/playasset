package com.assetinfo.playasset.task.stock.handler;

import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.function.ServerRequest;
import org.springframework.web.servlet.function.ServerResponse;

import com.assetinfo.playasset.task.stock.svc.StockSvc;

import lombok.NonNull;

@Component
public class StockHandler {

    private final StockSvc stockSvc;

    public StockHandler(@NonNull StockSvc stockSvc) {
        this.stockSvc = stockSvc;
    }

    public ServerResponse findAllTmpNews(ServerRequest request) {
        String keywords = request.param("keywords").orElse("SAMSUNG");
        return ServerResponse.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(stockSvc.findAllTmpNews(keywords));
    }

    public ServerResponse getStockEvaulation(ServerRequest request) {
        Map<String, Object> map = stockSvc.getStockEvaulation();
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON).body(map);
    }
}
