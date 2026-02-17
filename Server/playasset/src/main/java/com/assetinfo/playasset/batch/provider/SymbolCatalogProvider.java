package com.assetinfo.playasset.batch.provider;

import java.util.List;

public interface SymbolCatalogProvider {

    List<SymbolCatalogItem> fetchUsSymbols(int maxCount);

    String providerKey();

    record SymbolCatalogItem(
            String symbol,
            String assetName,
            String market,
            String currency) {
    }
}

