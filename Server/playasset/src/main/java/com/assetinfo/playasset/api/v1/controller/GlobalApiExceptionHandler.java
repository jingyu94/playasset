package com.assetinfo.playasset.api.v1.controller;

import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.assetinfo.playasset.api.v1.auth.ForbiddenException;
import com.assetinfo.playasset.api.v1.auth.UnauthorizedException;
import com.assetinfo.playasset.api.v1.quota.PaidServiceLimitExceededException;

@RestControllerAdvice
public class GlobalApiExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", Instant.now().toString());
        body.put("error", "VALIDATION_ERROR");
        body.put("message", ex.getBindingResult().getFieldError() == null
                ? "요청 값 검증에 실패했습니다."
                : ex.getBindingResult().getFieldError().getField() + " 값이 유효하지 않습니다.");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleBadRequest(IllegalArgumentException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", Instant.now().toString());
        body.put("error", "BAD_REQUEST");
        body.put("message", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, Object>> handleUnauthorized(UnauthorizedException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", Instant.now().toString());
        body.put("error", "UNAUTHORIZED");
        body.put("message", ex.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(body);
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<Map<String, Object>> handleForbidden(ForbiddenException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", Instant.now().toString());
        body.put("error", "FORBIDDEN");
        body.put("message", ex.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(body);
    }

    @ExceptionHandler(PaidServiceLimitExceededException.class)
    public ResponseEntity<Map<String, Object>> handlePaidServiceLimit(PaidServiceLimitExceededException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", Instant.now().toString());
        body.put("error", "PAYWALL_LIMIT_EXCEEDED");
        body.put("message", ex.getMessage());
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(body);
    }

    @ExceptionHandler(DateTimeParseException.class)
    public ResponseEntity<Map<String, Object>> handleDateTimeParse(DateTimeParseException ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", Instant.now().toString());
        body.put("error", "BAD_REQUEST");
        body.put("message", "날짜 형식은 yyyy-MM-dd 이어야 합니다.");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneral(Exception ex) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("success", false);
        body.put("timestamp", Instant.now().toString());
        body.put("error", "INTERNAL_ERROR");
        body.put("message", ex.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}
