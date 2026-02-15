package com.assetinfo.playasset.api.v1.auth;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;

import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class ApiAuthFilter extends OncePerRequestFilter {

    private final AuthService authService;
    private final ObjectMapper objectMapper;

    public ApiAuthFilter(AuthService authService, ObjectMapper objectMapper) {
        this.authService = authService;
        this.objectMapper = objectMapper;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String path = request.getRequestURI();

        if (HttpMethod.OPTIONS.matches(request.getMethod()) || isPublicPath(path)) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = extractBearerToken(request.getHeader("Authorization"));
        AuthPrincipal principal = authService.resolveByToken(token);
        if (principal == null) {
            writeUnauthorized(response, "인증 토큰이 유효하지 않습니다.");
            return;
        }

        try {
            AuthContextHolder.set(principal);
            filterChain.doFilter(request, response);
        } finally {
            AuthContextHolder.clear();
        }
    }

    private boolean isPublicPath(String path) {
        if (path == null) {
            return true;
        }
        if (!path.startsWith("/api/v1/")) {
            return true;
        }
        return path.equals("/api/v1/auth/login");
    }

    private String extractBearerToken(String authorization) {
        if (authorization == null) {
            return null;
        }
        String prefix = "Bearer ";
        if (!authorization.startsWith(prefix)) {
            return null;
        }
        return authorization.substring(prefix.length()).trim();
    }

    private void writeUnauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        var body = objectMapper.createObjectNode();
        body.put("success", false);
        body.put("timestamp", Instant.now().toString());
        body.put("error", "UNAUTHORIZED");
        body.put("message", message);
        response.getWriter().write(body.toString());
    }
}
