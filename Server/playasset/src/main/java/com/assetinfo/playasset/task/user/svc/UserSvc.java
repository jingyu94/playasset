package com.assetinfo.playasset.task.user.svc;

import java.util.List;

import com.assetinfo.playasset.task.user.entity.UserEntity;

public interface UserSvc {
    List<UserEntity> findAll();
    UserEntity findOne();
}
