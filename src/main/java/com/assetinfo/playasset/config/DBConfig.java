package com.assetinfo.playasset.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.assetinfo.playasset.properties.DeployProperties;

import dev.miku.r2dbc.mysql.MySqlConnectionConfiguration;
import dev.miku.r2dbc.mysql.MySqlConnectionFactory;
import io.r2dbc.spi.ConnectionFactory;

@Configuration
public class DBConfig {

    @Autowired
    DeployProperties props;

    private static final Logger logger = LoggerFactory.getLogger(DBConfig.class);

    @Bean
    public ConnectionFactory connectionFactory() {
        return MySqlConnectionFactory.from(
            MySqlConnectionConfiguration.builder().host(props.getDbHost()).password(props.getDbPasswd()).port(props.getDbPort()).database(props.getDbDatabase()).username(props.getDbAccount()).build()
        );
    }
}
