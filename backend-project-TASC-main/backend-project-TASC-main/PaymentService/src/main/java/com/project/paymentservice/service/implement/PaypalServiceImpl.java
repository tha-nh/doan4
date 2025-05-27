package com.project.paymentservice.service.implement;

import com.project.paymentservice.service.PaypalService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@Service // Đảm bảo Spring quản lý class này
public class PaypalServiceImpl implements PaypalService {

    @Autowired
    private RestTemplate restTemplate; // Inject RestTemplate

    private String clientId = "Aek0TvvDlldOX570tv2QpF7h6xQBusCCGTpz5WsJm6KxTLx1zCIGHgKUknBtRBWfd3OHQ6w8RLPDiz4n";

    private String clientSecret = "EIVnVgXXjmtpBFMUzdPj_25CV80r0UaHKzzmMqzbaxBAFneh_f9LYh1E3JKO4oejYSPgs7uM_STD545-";

    private static final String PAYPAL_SANDBOX_URL = "https://api.sandbox.paypal.com";
    private static final String PAYPAL_API_URL = "/v1/oauth2/token";

    // Hàm lấy access token từ PayPal
    private String getAccessToken() {
        String auth = clientId + ":" + clientSecret;

        String encodedAuth = Base64.getEncoder().encodeToString(auth.getBytes());
        System.out.println(encodedAuth);
        // Tạo header với Authorization
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Basic " + encodedAuth);
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        // Tạo body cho yêu cầu
        String body = "grant_type=client_credentials";

        HttpEntity<String> entity = new HttpEntity<>(body, headers);

        // Thực hiện POST request để lấy access token
        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                    PAYPAL_SANDBOX_URL + PAYPAL_API_URL,
                    HttpMethod.POST,
                    entity,
                    Map.class
            );

            // Kiểm tra nếu phản hồi trả về thành công
            if (response.getStatusCode() == HttpStatus.OK) {
                Map<String, Object> responseBody = response.getBody();
                if (responseBody != null && responseBody.containsKey("access_token")) {
                    return (String) responseBody.get("access_token");
                }
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi lấy access token từ PayPal: " + e.getMessage());
            e.printStackTrace();
        }

        return null; // Nếu không lấy được token
    }


    @Override
    public boolean verifyPayment(String orderID) {
        System.out.println("Order ID: " + orderID);

        // Kiểm tra nếu tham số cần thiết đã được cung cấp
        if (orderID == null) {
            System.err.println("Lỗi: Order ID không hợp lệ.");
            return false;
        }

        // Chọn URL để xác thực (capture) đơn hàng
        String url = PAYPAL_SANDBOX_URL + "/v2/checkout/orders/" + orderID + "/capture";

        // Lấy access token để xác thực (vì không cần gửi facilitatorAccessToken trực tiếp)
        String accessToken = getAccessToken();
        System.out.println("Access token trả về: " + accessToken);
        if (accessToken == null) {
            System.err.println("Lỗi: Không thể lấy access token.");
            return false;
        }

        // Tạo header với Authorization sử dụng Bearer token
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + accessToken);
        headers.setContentType(MediaType.APPLICATION_JSON);

        // Tạo HttpEntity để gói dữ liệu request (không cần gửi payer_id ở đây)
        HttpEntity<String> entity = new HttpEntity<>(headers);

        try {
            // Gửi yêu cầu tới PayPal để xác thực (capture) đơn hàng
            ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.POST, entity, Map.class);

            // Kiểm tra mã phản hồi HTTP
            if (response.getStatusCode() == HttpStatus.OK || response.getStatusCode() == HttpStatus.CREATED) {
                Map<String, Object> responseBody = response.getBody();
                if (responseBody != null) {
                    String status = (String) responseBody.get("status");
                    if ("COMPLETED".equals(status)) {
                        System.out.println("Xác thực thanh toán thành công!");
                        return true; // Nếu thanh toán đã được phê duyệt và hoàn tất
                    } else {
                        System.out.println("Thanh toán chưa được phê duyệt. Trạng thái: " + status);
                    }
                } else {
                    System.err.println("Lỗi: Phản hồi từ PayPal không có nội dung.");
                }
            } else {
                System.err.println("Lỗi: Không thể xác thực thanh toán. Mã trạng thái HTTP: " + response.getStatusCode());
            }
        } catch (Exception e) {
            // In lỗi chi tiết khi có lỗi trong quá trình xác thực
            System.err.println("Lỗi khi xác thực thanh toán PayPal: " + e.getMessage());
            e.printStackTrace();
        }

        return false; // Nếu xác thực không thành công
    }




}
