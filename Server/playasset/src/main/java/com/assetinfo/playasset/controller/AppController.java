package com.assetinfo.playasset.controller;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.svc.StockSvc;
import com.assetinfo.playasset.task.user.entity.UserEntity;
import com.assetinfo.playasset.task.user.svc.UserSvc;

import lombok.NonNull;

@RestController
@RequestMapping("/api/controller")
public class AppController {

    private final UserSvc userSvc;
    private final StockSvc stockSvc;

    public AppController(@NonNull UserSvc userSvc, @NonNull StockSvc stockSvc) {
        this.userSvc = userSvc;
        this.stockSvc = stockSvc;
    }

    @GetMapping("/hello")
    public Map<String, Object> hello() {
        List<Map<String, String>> movies = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            Map<String, String> temp = new HashMap<>();
            temp.put("id", Integer.toString(i));
            temp.put("title", "title" + Integer.toString(i));
            movies.add(temp);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("movies", movies);
        result.put("text", "mvc-vt");
        return result;
    }

    @GetMapping("/findOne")
    public UserEntity findOne() {
        return userSvc.findOne();
    }

    @GetMapping("/findAll")
    public List<StockEntity> findAll() {
        return stockSvc.findAll();
    }
}
