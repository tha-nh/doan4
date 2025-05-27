package com.project.userservice.service;

import org.springframework.stereotype.Service;

@Service
public interface AuthService {
public String login(String username, String password);
}
