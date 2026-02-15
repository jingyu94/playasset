package com.assetinfo.playasset.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.ApplicationContext;
import org.springframework.web.reactive.config.WebFluxConfigurer;
import org.springframework.context.ApplicationContextAware;
import org.springframework.beans.BeansException;
import org.springframework.context.annotation.Bean;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.RouterFunctions;
import org.springframework.web.reactive.function.server.ServerResponse;

import com.assetinfo.playasset.handler.Handler;
import com.assetinfo.playasset.task.stock.handler.StockHandler;

/**
 * @Desc url 요청에 대해 handler mapping을 정의한다.
 */

@Configuration
public class RoutsConfig implements ApplicationContextAware, WebFluxConfigurer {

    ApplicationContext context;

    /**
     * @Desc    .GET/.POST 메소드를 사용해서 HTTP Response 방식을 정의
     * @param   handler
     * @return  
     */
    @Bean
    public RouterFunction<ServerResponse> route(Handler handler) {
        // return RouterFunctions.route(
        // RequestPredicates.GET("/hello").and(RequestPredicates.accept(MediaType.TEXT_PLAIN)),
        // handler::hello);
        return RouterFunctions.route()
                .GET("/hello", handler::hello) // 2
                .GET("/findOne", handler::findOne) // 3
                .GET("/findAll", handler::findAll) // 4
                .build();
    }

    @Bean
    public RouterFunction<ServerResponse> stockRoute(StockHandler handler) {
        return RouterFunctions.route()
                .GET("/stock/findAllTmpNews", handler::findAllTmpNews)
                .GET("/stock/getStockEvaulation", handler::getStockEvaulation)
                .build();
    }

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {

    }
}
