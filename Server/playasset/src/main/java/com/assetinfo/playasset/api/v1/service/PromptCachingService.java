package com.assetinfo.playasset.api.v1.service;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import com.assetinfo.playasset.config.CacheNames;

@Service
public class PromptCachingService {

    @Cacheable(cacheNames = CacheNames.LLM_PROMPT_TEMPLATE, key = "#promptKey + ':' + #promptVersion")
    public String cachePromptTemplate(String promptKey, String promptVersion, String templateBody) {
        return templateBody;
    }

    @Cacheable(cacheNames = CacheNames.LLM_PROMPT_PAYLOAD, key = "#cacheKey")
    public String cachePromptPayload(String cacheKey, String payloadJson) {
        return payloadJson;
    }
}
