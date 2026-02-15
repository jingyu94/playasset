package com.assetinfo.playasset.api.v1.controller;

import java.util.List;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.assetinfo.playasset.api.v1.dto.AlertResponse;
import com.assetinfo.playasset.api.v1.dto.ApiResponse;
import com.assetinfo.playasset.api.v1.dto.CreateTransactionRequest;
import com.assetinfo.playasset.api.v1.dto.CreateTransactionResponse;
import com.assetinfo.playasset.api.v1.dto.DashboardResponse;
import com.assetinfo.playasset.api.v1.dto.PortfolioAdviceResponse;
import com.assetinfo.playasset.api.v1.dto.PortfolioSimulationResponse;
import com.assetinfo.playasset.api.v1.dto.PositionSnapshot;
import com.assetinfo.playasset.api.v1.dto.WatchlistItemResponse;
import com.assetinfo.playasset.api.v1.auth.Authz;
import com.assetinfo.playasset.api.v1.quota.PaidServiceKeys;
import com.assetinfo.playasset.api.v1.quota.PaidServiceQuotaService;
import com.assetinfo.playasset.api.v1.service.PlatformService;

import jakarta.validation.Valid;

@Validated
@RestController
@RequestMapping("/api/v1/users/{userId}")
public class PlatformController {

    private final PlatformService platformService;
    private final PaidServiceQuotaService quotaService;

    public PlatformController(PlatformService platformService, PaidServiceQuotaService quotaService) {
        this.platformService = platformService;
        this.quotaService = quotaService;
    }

    @GetMapping("/dashboard")
    public ApiResponse<DashboardResponse> dashboard(@PathVariable long userId) {
        Authz.requireUserOrAdmin(userId);
        quotaService.consume(PaidServiceKeys.DASHBOARD_READ);
        return ApiResponse.ok(platformService.getDashboard(userId));
    }

    @GetMapping("/portfolio/positions")
    public ApiResponse<List<PositionSnapshot>> positions(@PathVariable long userId) {
        Authz.requireUserOrAdmin(userId);
        quotaService.consume(PaidServiceKeys.POSITIONS_READ);
        return ApiResponse.ok(platformService.getPositions(userId));
    }

    @GetMapping("/portfolio/advice")
    public ApiResponse<PortfolioAdviceResponse> portfolioAdvice(@PathVariable long userId) {
        Authz.requireUserOrAdmin(userId);
        quotaService.consume(PaidServiceKeys.PORTFOLIO_ADVICE);
        return ApiResponse.ok(platformService.getPortfolioAdvice(userId));
    }

    @GetMapping("/portfolio/simulation")
    public ApiResponse<PortfolioSimulationResponse> portfolioSimulation(
            @PathVariable long userId,
            @RequestParam(name = "startDate", required = false) String startDate,
            @RequestParam(name = "endDate", required = false) String endDate) {
        Authz.requireUserOrAdmin(userId);
        quotaService.consume(PaidServiceKeys.PORTFOLIO_SIMULATION);
        return ApiResponse.ok(platformService.getPortfolioSimulation(userId, startDate, endDate));
    }

    @GetMapping("/watchlist")
    public ApiResponse<List<WatchlistItemResponse>> watchlist(@PathVariable long userId) {
        Authz.requireUserOrAdmin(userId);
        quotaService.consume(PaidServiceKeys.WATCHLIST_READ);
        return ApiResponse.ok(platformService.getWatchlist(userId));
    }

    @GetMapping("/alerts")
    public ApiResponse<List<AlertResponse>> alerts(
            @PathVariable long userId,
            @RequestParam(name = "limit", defaultValue = "20") int limit) {
        Authz.requireUserOrAdmin(userId);
        quotaService.consume(PaidServiceKeys.ALERTS_READ);
        return ApiResponse.ok(platformService.getAlerts(userId, limit));
    }

    @PostMapping("/portfolio/transactions")
    public ApiResponse<CreateTransactionResponse> createTransaction(
            @PathVariable long userId,
            @Valid @RequestBody CreateTransactionRequest request) {
        Authz.requireUserOrAdmin(userId);
        return ApiResponse.ok(platformService.createTransaction(userId, request));
    }
}
