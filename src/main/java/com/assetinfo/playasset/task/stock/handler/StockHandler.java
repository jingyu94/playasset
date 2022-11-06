package com.assetinfo.playasset.task.stock.handler;

import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;

import com.assetinfo.playasset.task.stock.entity.TmpNewsEntity;
import com.assetinfo.playasset.task.stock.svc.StockSvc;

import lombok.NonNull;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * @Desc Router에 정의된 URL과 매핑된 메소드명을 Handler 메소드로 작성
 */
@Component
public class StockHandler {

    private final StockSvc stockSvc;

    @Autowired
    public StockHandler(@NonNull StockSvc stockSvc) {
        this.stockSvc = stockSvc;
    }

    private Logger logger = LoggerFactory.getLogger(StockHandler.class);

    /**
     * @Desc    임시뉴스테이블 다건조회
     * @param   request
     * @return  
     */
    public Mono<ServerResponse> findAllTmpNews(ServerRequest request) {
        String result = request.headers().firstHeader("title");
        logger.warn("result: {}", result);
        String keyword = result;
        Flux<TmpNewsEntity> list = stockSvc.findAllTmpNews(keyword);
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON).body(list, TmpNewsEntity.class);
    }

    /**
     * @Desc    주식평가조회
     * @param   request
     * @return  
     */
    public Mono<ServerResponse> getStockEvaulation(ServerRequest request) {
        Map<String, Object> map = stockSvc.getStockEvaulation();
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON)
                .body(BodyInserters.fromProducer(Mono.just(map), HashMap.class));
    }
}