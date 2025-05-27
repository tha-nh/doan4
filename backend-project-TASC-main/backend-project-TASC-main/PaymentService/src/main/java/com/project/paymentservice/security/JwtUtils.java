package com.project.paymentservice.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.*;

@Component
public class JwtUtils {

    @Value("${jwt.secret}") // Lấy giá trị secret key từ file cấu hình
    private String secretKey;

    private long validityInMilliseconds = 3600000; // 1 hour

    public String createToken(String email, String role, Integer userId) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", role);
        claims.put("userId", userId);  // Thêm id vào claims

        // Chuyển chuỗi secretKey thành SecretKey
        SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes());
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(email)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + validityInMilliseconds))
                .signWith(key, SignatureAlgorithm.HS256) // Sử dụng SecretKey thay vì String
                .compact();
    }

    public boolean validateToken(String token) {
        return !isTokenExpired(token);
    }

    private boolean isTokenExpired(String token) {
        Claims claims = extractAllClaims(token);
        return claims.getExpiration().before(new Date());
    }

    public String getUsername(String token) {
        Claims claims = extractAllClaims(token);
        return claims.getSubject();
    }

    public String getRole(String token) {
        Claims claims = extractAllClaims(token);
        return (String) claims.get("role");
    }

    // Phương thức để trích xuất tất cả các claims từ token
    private Claims extractAllClaims(String token) {
        SecretKey key = Keys.hmacShaKeyFor(secretKey.getBytes()); // Chuyển chuỗi secretKey thành SecretKey
        return Jwts.parserBuilder() // Sử dụng parserBuilder thay vì parser
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public List<GrantedAuthority> getAuthorities(String token) {
        Claims claims = extractAllClaims(token);
        // Lấy vai trò từ claims, sửa "roles" thành "role"
        String role = claims.get("role", String.class); // Lấy vai trò đơn
        // Chuyển đổi thành quyền
        return Collections.singletonList(new SimpleGrantedAuthority(role)); // Trả về danh sách quyền
    }

    // Hàm lấy thông tin userId, email, và role từ token trong một lần duy nhất
    public Map<String, Object> getUserDetailsFromToken(String token) {
        try {
            Claims claims = extractAllClaims(token);

            Map<String, Object> userDetails = new HashMap<>();
            if (claims != null) {
                userDetails.put("userId", claims.get("userId"));
                userDetails.put("email", claims.getSubject()); // lấy email từ subject
                userDetails.put("role", claims.get("role"));
            }
            return userDetails;
        } catch (MalformedJwtException e) {
            System.out.println("Token không hợp lệ: " + e.getMessage());
            return null;
        } catch (Exception e) {
            System.out.println("Lỗi khi giải mã token: " + e.getMessage());
            return null;
        }
    }
}
