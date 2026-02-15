package com.assetinfo.playasset.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.RouterFunctions;
import org.springframework.web.servlet.function.ServerResponse;

import com.assetinfo.playasset.handler.Handler;
import com.assetinfo.playasset.task.stock.handler.StockHandler;

@Configuration
public class RoutsConfig {

    @Bean
    public RouterFunction<ServerResponse> route(Handler handler) {
        return RouterFunctions.route()
                .GET("/hello", handler::hello)
                .GET("/findOne", handler::findOne)
                .GET("/findAll", handler::findAll)
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> stockRoute(StockHandler handler) {
        return RouterFunctions.route()
                .GET("/stock/findAllTmpNews", handler::findAllTmpNews)
                .GET("/stock/getStockEvaulation", handler::getStockEvaulation)
                .build();
    }
}
