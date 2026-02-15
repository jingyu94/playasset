package com.assetinfo.playasset.api.v1.quota;

import java.time.LocalDate;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.assetinfo.playasset.api.v1.repository.AdminAuthRepository;

@Service
public class PaidServiceQuotaService {

    private final AdminAuthRepository repository;

    public PaidServiceQuotaService(AdminAuthRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public void consume(String serviceKey) {
        AdminAuthRepository.PolicyRow policy = repository.findPolicyForUpdate(serviceKey);
        if (policy == null) {
            throw new IllegalArgumentException("정책이 등록되지 않은 서비스입니다: " + serviceKey);
        }
        if (!policy.enabled()) {
            throw new PaidServiceLimitExceededException("서비스가 비활성화되어 있습니다: " + serviceKey);
        }

        LocalDate today = LocalDate.now();
        Integer currentUsed = repository.findUsageForUpdate(today, serviceKey);
        int dailyLimit = Math.max(0, policy.dailyLimit());
        int used = currentUsed == null ? 0 : currentUsed;

        if (used >= dailyLimit) {
            throw new PaidServiceLimitExceededException(
                    "일일 호출 한도를 초과했습니다. service=" + serviceKey + ", limit=" + dailyLimit);
        }

        int next = used + 1;
        if (currentUsed == null) {
            repository.insertUsage(today, serviceKey, next);
        } else {
            repository.updateUsage(today, serviceKey, next);
        }
    }
}
