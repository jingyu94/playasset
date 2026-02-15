package com.assetinfo.playasset.task.user.svc;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.assetinfo.playasset.task.user.dao.UserDao;
import com.assetinfo.playasset.task.user.entity.UserEntity;

@Service
public class UserSvcImpl implements UserSvc {
    
    @Autowired
    private UserDao userDao;

    private Logger logger = LoggerFactory.getLogger(UserSvc.class);

    @Override
    public List<UserEntity> findAll() {
        return userDao.findAll();
    }

    @Override
    public UserEntity findOne() {
        return userDao.findOne();
    }
}
