package com.assetinfo.playasset.task.user.entity;


import java.sql.Date;

import org.springframework.format.annotation.DateTimeFormat;

import lombok.Data;

@Data
public class UserEntity {
    private String userId;
    private String userPassword;
    private String userName;
    private String userCp;
    private String userAuth;
    private String regId;

    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private Date regDtm;
    private String udtId;

    @DateTimeFormat(pattern = "yyyy-MM-dd")
    private Date udtDtm;
}