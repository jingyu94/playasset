package com.assetinfo.playasset.task.stock.entity;

import java.sql.Date;

import lombok.Data;

@Data
public class StockEntity {
    private String stockId;
    private String stockName;
    private String srchTag;
    private String regId;
    private Date regDtm;
    private String udtId;
    private Date udtDtm;
}