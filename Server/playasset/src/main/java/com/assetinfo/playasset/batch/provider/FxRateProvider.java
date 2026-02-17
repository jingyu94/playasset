package com.assetinfo.playasset.batch.provider;

import java.math.BigDecimal;
import java.util.Optional;

public interface FxRateProvider {

    Optional<BigDecimal> fetchUsdKrw();

    String providerKey();
}

