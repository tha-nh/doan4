package com.project.transactionn;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class TransactionnApplication {

    public static void main(String[] args) {
        SpringApplication.run(TransactionnApplication.class, args);
    }

}
