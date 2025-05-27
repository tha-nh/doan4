package com.project.userservice.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@Component
public class JwtRequestFilter extends OncePerRequestFilter {
    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {

        // Lấy URL của request
        String requestURI = request.getRequestURI();

        // Bỏ qua kiểm tra JWT cho các API không cần xác thực
        if (requestURI.startsWith("/api/userservice/login") ||
                requestURI.startsWith("/api/userservice/patients/register") ||
                requestURI.startsWith("/api/userservice/doctors/register") ||
                requestURI.startsWith("/api/userservice/staffs/register")) {
            // Nếu là các API này, không cần kiểm tra JWT, chỉ cần tiếp tục với chuỗi bộ lọc
            chain.doFilter(request, response);
            System.out.println("api không yêu cầu jwt");
            return;
        }

        final String authorizationHeader = request.getHeader("authorization");

        String jwt = null;
        String username = null;

        // Kiểm tra nếu header chứa Bearer Token
        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            jwt = authorizationHeader.substring(7);  // Lấy JWT từ header

            // Lấy thông tin user từ token (userId, email, role)
            Map<String, Object> userDetails = jwtUtils.getUserDetailsFromToken(jwt);
            System.out.println("giải mã token : " + userDetails);
            if (userDetails != null) {
                username = (String) userDetails.get("email"); // Lấy email từ userDetails
            }
        }

        // Nếu username không null và không có authentication trong context
        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails userDetails = userDetailsService.loadUserByUsername(username);

            // Kiểm tra token hợp lệ
            if (jwtUtils.validateToken(jwt)) {
                // Lấy authorities từ JWT
                List<GrantedAuthority> authorities = jwtUtils.getAuthorities(jwt);

                // Tạo đối tượng Authentication và thiết lập nó vào SecurityContext
                UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                        userDetails, null, authorities);
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        // Tiếp tục xử lý yêu cầu
        chain.doFilter(request, response);
    }
}
