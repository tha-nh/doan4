package com.project.userservice.service.implement;

import com.project.userservice.service.PasswordService;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.Base64;

@Service
public class PasswordServiceImpl implements PasswordService {
    @Override
    public String generateRandomPassword() {
        SecureRandom secureRandom = new SecureRandom();
        byte[] randomBytes = new byte[16]; // 16 byte = 128 bit password
        secureRandom.nextBytes(randomBytes);
        return Base64.getEncoder().encodeToString(randomBytes); // Mã hóa thành chuỗi Base64
    }
}
