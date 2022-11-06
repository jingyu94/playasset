package com.assetinfo.playasset.task.user.dao;

import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import org.springframework.stereotype.Repository;

import com.assetinfo.playasset.task.user.entity.UserEntity;

import reactor.core.publisher.Mono;

@Repository
public interface UserDao extends ReactiveCrudRepository<UserEntity, Long> {

    @Query("SELECT * FROM TM_USER")
    Mono<UserEntity> findOne();
}
