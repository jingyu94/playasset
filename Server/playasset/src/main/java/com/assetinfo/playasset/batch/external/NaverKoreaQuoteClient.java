package com.assetinfo.playasset.batch.external;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import com.assetinfo.playasset.batch.provider.MarketDataProvider;

@Component
public class NaverKoreaQuoteClient implements MarketDataProvider {

    private static final Logger log = LoggerFactory.getLogger(NaverKoreaQuoteClient.class);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(6);
    private static final Pattern ITEM_PATTERN = Pattern.compile("<item\\s+data=\"([^\"]+)\"");

    @Override
    public Map<String, QuoteSnapshot> fetchQuotes(List<String> symbols) {
        if (symbols == null || symbols.isEmpty()) {
            return Collections.emptyMap();
        }
        Map<String, QuoteSnapshot> result = new HashMap<>();
        for (String rawSymbol : symbols) {
            String symbol = rawSymbol == null ? "" : rawSymbol.trim();
            if (!symbol.matches("\\d{6}")) {
                continue;
            }
            try {
                String body = WebClient.builder()
                        .baseUrl("https://fchart.stock.naver.com")
                        .build()
                        .get()
                        .uri(uriBuilder -> uriBuilder
                                .path("/sise.nhn")
                                .queryParam("symbol", symbol)
                                .queryParam("timeframe", "day")
                                .queryParam("count", "1")
                                .queryParam("requestType", "0")
                                .build())
                        .retrieve()
                        .bodyToMono(String.class)
                        .block(REQUEST_TIMEOUT);
                QuoteSnapshot snapshot = parseSnapshot(body);
                if (snapshot != null) {
                    result.put(symbol, snapshot);
                }
            } catch (Exception ex) {
                log.debug("korea quote fetch failed for {}: {}", symbol, ex.getMessage());
            }
        }
        return result;
    }

    @Override
    public boolean supports(String market, String symbol, String currency) {
        if (symbol == null || symbol.isBlank()) {
            return false;
        }
        boolean krTicker = symbol.matches("\\d{6}");
        boolean krMarket = market != null && (market.toUpperCase().startsWith("KR")
                || "KOSPI".equalsIgnoreCase(market)
                || "KOSDAQ".equalsIgnoreCase(market)
                || "KRX".equalsIgnoreCase(market));
        boolean krCurrency = currency != null && "KRW".equalsIgnoreCase(currency);
        return krTicker && (krMarket || krCurrency);
    }

    @Override
    public String providerKey() {
        return "NAVER_FCHART";
    }

    private QuoteSnapshot parseSnapshot(String xml) {
        if (xml == null || xml.isBlank()) {
            return null;
        }
        Matcher matcher = ITEM_PATTERN.matcher(xml);
        if (!matcher.find()) {
            return null;
        }
        String data = matcher.group(1);
        String[] tokens = data.split("\\|");
        if (tokens.length < 6) {
            return null;
        }
        try {
            BigDecimal open = new BigDecimal(tokens[1]);
            BigDecimal high = new BigDecimal(tokens[2]);
            BigDecimal low = new BigDecimal(tokens[3]);
            BigDecimal close = new BigDecimal(tokens[4]);
            BigDecimal volume = new BigDecimal(tokens[5]);
            return new QuoteSnapshot(
                    open.setScale(2, RoundingMode.HALF_UP),
                    high.setScale(2, RoundingMode.HALF_UP),
                    low.setScale(2, RoundingMode.HALF_UP),
                    close.setScale(2, RoundingMode.HALF_UP),
                    volume);
        } catch (Exception ex) {
            return null;
        }
    }
}
