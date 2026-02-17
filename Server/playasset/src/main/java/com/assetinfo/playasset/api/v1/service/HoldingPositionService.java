package com.assetinfo.playasset.api.v1.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.assetinfo.playasset.api.v1.dto.PositionSnapshot;
import com.assetinfo.playasset.api.v1.dto.UpdateHoldingPositionRequest;
import com.assetinfo.playasset.api.v1.repository.PlatformQueryRepository;

@Service
public class HoldingPositionService {

    private final PlatformQueryRepository repository;
    private final PlatformCacheEvictService cacheEvictService;

    public HoldingPositionService(
            PlatformQueryRepository repository,
            PlatformCacheEvictService cacheEvictService) {
        this.repository = repository;
        this.cacheEvictService = cacheEvictService;
    }

    @Transactional
    public PositionSnapshot updateHoldingPosition(long userId, long assetId, UpdateHoldingPositionRequest request) {
        Long accountId = repository.findOwnedAccountIdByUserAndAsset(userId, assetId);
        if (accountId == null) {
            accountId = repository.findPrimaryAccountIdByUser(userId);
        }
        if (accountId == null) {
            throw new IllegalArgumentException("No account found for user");
        }

        repository.upsertPositionByAccount(accountId, assetId, request.quantity(), request.avgCost());
        cacheEvictService.evictMarketDrivenCaches();

        List<PositionSnapshot> positions = repository.loadPositions(userId);
        return positions.stream()
                .filter(p -> p.assetId() == assetId)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Updated position not found"));
    }
}
