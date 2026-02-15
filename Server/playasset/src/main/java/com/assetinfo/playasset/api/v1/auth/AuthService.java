package com.assetinfo.playasset.api.v1.auth;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.assetinfo.playasset.api.v1.dto.CurrentUserResponse;
import com.assetinfo.playasset.api.v1.dto.LoginRequest;
import com.assetinfo.playasset.api.v1.dto.LoginResponse;
import com.assetinfo.playasset.api.v1.repository.AdminAuthRepository;

@Service
public class AuthService {

    private final AdminAuthRepository repository;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Value("${app.auth.session-hours:24}")
    private long sessionHours;

    public AuthService(AdminAuthRepository repository) {
        this.repository = repository;
    }

    public LoginResponse login(LoginRequest request) {
        String loginId = normalize(request.loginId());
        AdminAuthRepository.CredentialRow credential = repository.findCredentialByLoginId(loginId);
        if (credential == null || !"ACTIVE".equalsIgnoreCase(credential.status())) {
            throw new UnauthorizedException("아이디 또는 비밀번호가 올바르지 않습니다.");
        }

        if (!matchesPassword(request.password(), credential.passwordHash(), credential.hashAlgorithm())) {
            throw new UnauthorizedException("아이디 또는 비밀번호가 올바르지 않습니다.");
        }

        Set<String> roles = repository.findRolesByUserId(credential.userId());
        String token = UUID.randomUUID().toString().replace("-", "") + UUID.randomUUID().toString().replace("-", "");
        LocalDateTime expiresAt = LocalDateTime.now().plusHours(Math.max(1, sessionHours));
        repository.createSession(token, credential.userId(), expiresAt);

        return new LoginResponse(
                token,
                "Bearer",
                expiresAt.toString(),
                credential.userId(),
                credential.loginId(),
                credential.displayName(),
                roles.stream().sorted().toList());
    }

    public AuthPrincipal resolveByToken(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        AdminAuthRepository.SessionRow session = repository.findValidSession(token);
        if (session == null) {
            return null;
        }
        Set<String> roles = repository.findRolesByUserId(session.userId());
        return new AuthPrincipal(session.userId(), session.loginId(), session.displayName(), roles);
    }

    public void logout(String token) {
        if (token == null || token.isBlank()) {
            return;
        }
        repository.revokeSession(token);
    }

    public CurrentUserResponse me() {
        AuthPrincipal principal = Authz.requireAuthenticated();
        return new CurrentUserResponse(
                principal.userId(),
                principal.loginId(),
                principal.displayName(),
                principal.roles().stream().sorted().toList());
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private boolean matchesPassword(String rawPassword, String passwordHash, String hashAlgorithm) {
        String algorithm = hashAlgorithm == null ? "" : hashAlgorithm.trim().toUpperCase(Locale.ROOT);
        if ("BCRYPT".equals(algorithm)) {
            return passwordEncoder.matches(rawPassword, passwordHash);
        }
        if ("PLAINTEXT".equals(algorithm)) {
            return rawPassword != null && rawPassword.equals(passwordHash);
        }
        return false;
    }
}
