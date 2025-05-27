package com.project.userservice.service.implement;

import com.project.userservice.model.CustomUserDetails;
import com.project.userservice.security.JwtUtils;
import com.project.userservice.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.security.core.GrantedAuthority;

@Service
public class AuthServiceImpl implements AuthService {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private CustomUserDetailsService customUserDetailsService;

    @Override
    public String login(String email, String password) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, password)
            );
            UserDetails userDetails = customUserDetailsService.loadUserByUsername(email);
            String role = userDetails.getAuthorities().stream()
                    .findFirst()
                    .map(GrantedAuthority::getAuthority)
                    .orElse("USER");
            Integer userId = ((CustomUserDetails) userDetails).getId(); // Casting để lấy id

            return jwtUtils.createToken(email, role,userId);
        } catch (AuthenticationException e) {
            throw new RuntimeException("Invalid login attempt");
        }
    }



}
