package com.assetinfo.playasset.handler;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.function.ServerRequest;
import org.springframework.web.servlet.function.ServerResponse;

import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.svc.StockSvc;
import com.assetinfo.playasset.task.user.svc.UserSvc;

import lombok.NonNull;

@Component
public class Handler {

    private final UserSvc userSvc;
    private final StockSvc stockSvc;

    public Handler(@NonNull UserSvc userSvc, @NonNull StockSvc stockSvc) {
        this.userSvc = userSvc;
        this.stockSvc = stockSvc;
    }

    public ServerResponse hello(ServerRequest request) {
        List<Map<String, String>> movies = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            Map<String, String> temp = new HashMap<>();
            temp.put("id", Integer.toString(i));
            temp.put("title", "title" + i);
            movies.add(temp);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("movies", movies);
        result.put("text", "mvc-vt");

        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON).body(result);
    }

    public ServerResponse findOne(ServerRequest request) {
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON).body(userSvc.findOne());
    }

    public ServerResponse findAll(ServerRequest request) {
        List<StockEntity> list = stockSvc.findAll();
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON).body(list);
    }
}
