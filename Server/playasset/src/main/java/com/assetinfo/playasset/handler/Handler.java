package com.assetinfo.playasset.handler;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.ServerRequest;
import org.springframework.web.reactive.function.server.ServerResponse;

import com.assetinfo.playasset.properties.DeployProperties;
import com.assetinfo.playasset.task.stock.entity.StockEntity;
import com.assetinfo.playasset.task.stock.svc.StockSvc;
import com.assetinfo.playasset.task.user.entity.UserEntity;
import com.assetinfo.playasset.task.user.svc.UserSvc;

import lombok.NonNull;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

/**
 * @Desc Router에 정의된 URL과 매핑된 메소드명을 Handler 메소드로 작성
 */
@Component
public class Handler {

    private final UserSvc userSvc;
    private final StockSvc stockSvc;

    @Autowired
    public Handler(@NonNull UserSvc userSvc, @NonNull StockSvc stockSvc) {
        this.userSvc = userSvc;
        this.stockSvc = stockSvc;
    }

    @Autowired
    private DeployProperties prop;

    private Logger logger = LoggerFactory.getLogger(Handler.class);

    private HashMap<Object, Object> result = new HashMap<>();
    private Mono<HashMap<Object, Object>> mapper = Mono.just(result);

    public Mono<ServerResponse> hello(ServerRequest request) {

        List<Map> movies = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            Map<String, String> temp = new HashMap<>();
            temp.put("id", Integer.toString(i));
            temp.put("title", "title" + Integer.toString(i));
            movies.add(temp);
        }
        result.put("movies", movies);
        result.put("text", "webFlux");
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON)
                .body(BodyInserters.fromProducer(mapper, HashMap.class));
    }

    /**
     * @Desc    단건조회
     * @param   request
     * @return  
     */
    public Mono<ServerResponse> findOne(ServerRequest request) {
        /*
         * DeployProperties 에서 읽어옴
         */
        logger.warn("deployProps: {}", prop.getDbHost());
        return ServerResponse.ok().contentType(MediaType.APPLICATION_JSON)
                .body(BodyInserters.fromProducer(userSvc.findOne(), UserEntity.class));
    }

    /**
     * @Desc    다건조회
     * @param   request
     * @return  
     */
    public Mono<ServerResponse> findAll(ServerRequest request) {
        Flux<StockEntity> list = stockSvc.findAll();
        return ServerResponse.ok().contentType(MediaType.TEXT_EVENT_STREAM).body(list, StockEntity.class);
    }
}