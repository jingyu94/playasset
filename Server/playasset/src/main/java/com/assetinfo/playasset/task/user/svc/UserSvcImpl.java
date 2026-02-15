package com.assetinfo.playasset.task.user.svc;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.assetinfo.playasset.task.user.dao.UserDao;
import com.assetinfo.playasset.task.user.entity.UserEntity;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class UserSvcImpl implements UserSvc {
    
    @Autowired
    private UserDao userDao;

    private Logger logger = LoggerFactory.getLogger(UserSvc.class);

    @Override
    public Flux<UserEntity> findAll() {
        return userDao.findAll();
    }

    @Override
    public Mono<UserEntity> findOne() {
        return userDao.findOne();
    }
}