package com.assetinfo.playasset.batch.provider;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface MarketDataProvider {

    Map<String, QuoteSnapshot> fetchQuotes(List<String> symbols);

    boolean supports(String market, String symbol, String currency);

    String providerKey();

    record QuoteSnapshot(
            BigDecimal openPrice,
            BigDecimal highPrice,
            BigDecimal lowPrice,
            BigDecimal closePrice,
            BigDecimal volume) {
    }
}
