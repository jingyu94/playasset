package com.assetinfo.playasset.task.user.svc;

import com.assetinfo.playasset.task.user.entity.UserEntity;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

public interface UserSvc {
    Flux<UserEntity> findAll();
    Mono<UserEntity> findOne();
}
