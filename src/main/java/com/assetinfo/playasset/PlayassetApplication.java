package com.assetinfo.playasset;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.PropertySource;

/**
 * @Desc 기본설정 선언
 * 1. @SpringBootApplication 어노테이션을 통해 기본적인 설정들을 선언
 * 2. @ComponentScan 어노테이션을 통해 @Component, @Service, @Repository, @Controller등의 어노테이션들을 스캔하여 Bean에 등록
 * 3. @PropertySource 어노테이션을 통해 커스텀 properties 파일들을 READ
 * 4. ignoreResourceNotFound = true 프로퍼티 파일들이 존재하지 않으면 SKIP
 */
@SpringBootApplication
@PropertySource(value = {
    "classpath:deploy-dev.properties", "classpath:deploy-prd.properties"
}, ignoreResourceNotFound = true)
public class PlayassetApplication {

	public static void main(String[] args) {
		SpringApplication.run(PlayassetApplication.class, args);
	}
}
