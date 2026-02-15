package com.assetinfo.playasset.api.v1.controller;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.assetinfo.playasset.api.v1.auth.AuthService;
import com.assetinfo.playasset.api.v1.auth.Authz;
import com.assetinfo.playasset.api.v1.dto.ApiResponse;
import com.assetinfo.playasset.api.v1.dto.CurrentUserResponse;
import com.assetinfo.playasset.api.v1.dto.LoginRequest;
import com.assetinfo.playasset.api.v1.dto.LoginResponse;

import jakarta.validation.Valid;

@Validated
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }

    @GetMapping("/me")
    public ApiResponse<CurrentUserResponse> me() {
        Authz.requireAuthenticated();
        return ApiResponse.ok(authService.me());
    }

    @PostMapping("/logout")
    public ApiResponse<Boolean> logout(@RequestHeader(name = "Authorization", required = false) String authorization) {
        Authz.requireAuthenticated();
        authService.logout(extractBearerToken(authorization));
        return ApiResponse.ok(Boolean.TRUE);
    }

    private String extractBearerToken(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return null;
        }
        return authorization.substring("Bearer ".length()).trim();
    }
}
