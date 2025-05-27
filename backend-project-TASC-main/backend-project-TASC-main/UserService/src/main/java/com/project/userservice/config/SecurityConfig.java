package com.project.userservice.config;

import com.project.userservice.security.JwtRequestFilter;
import com.project.userservice.service.implement.CustomUserDetailsService;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    private final CustomUserDetailsService userDetailsService;
    private final JwtRequestFilter jwtRequestFilter;

    public SecurityConfig(CustomUserDetailsService userDetailsService, JwtRequestFilter jwtRequestFilter) {
        this.userDetailsService = userDetailsService;
        this.jwtRequestFilter = jwtRequestFilter;
    }


    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests(authorizeRequests ->
                        authorizeRequests
                                .requestMatchers("/api/userservice/notjwt/**").permitAll() // Không yêu cầu JWT
                                .requestMatchers("/swagger-ui/**","/v3/api-docs/**","/swagger-ui.html").permitAll()
                                .requestMatchers("/redis/**").permitAll() // Không yêu cầu JWT
                                .requestMatchers("/api/userservice/jwt/patient/").hasRole("PATIENT") // Quyền bệnh nhân
                                .requestMatchers("/api/userservice/jwt/doctor/").hasRole("DOCTOR")   // Quyền bác sĩ
                                .requestMatchers("/api/userservice/jwt/staff/").hasRole("STAFF")     // Quyền nhân viên
                                .requestMatchers("/api/userservice/jwt/admin/").hasRole("ADMIN")     // Quyền admin
                                .anyRequest().authenticated() // Các API khác yêu cầu xác thực
                )
                .csrf(csrf -> csrf.disable()) // Tắt CSRF
                .addFilterBefore(jwtRequestFilter, UsernamePasswordAuthenticationFilter.class); // Thêm bộ lọc JWT

        return http.build();
    }

    @Bean
    public AuthenticationManager authManager(HttpSecurity http) throws Exception {
        AuthenticationManagerBuilder authenticationManagerBuilder =
                http.getSharedObject(AuthenticationManagerBuilder.class);
        authenticationManagerBuilder
                .userDetailsService(userDetailsService) // Sử dụng CustomUserDetailsService
                .passwordEncoder(passwordEncoder()); // Sử dụng mã hóa mật khẩu
        return authenticationManagerBuilder.build();
    }

    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
