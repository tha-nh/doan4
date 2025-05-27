//package springboot.springboot.database;
//
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.stereotype.Component;
//
//import java.io.BufferedReader;
//import java.io.InputStreamReader;
//import java.io.IOException;
//import java.net.HttpURLConnection;
//import java.net.URL;
//import java.util.concurrent.TimeUnit;
//
//@Component
//public class FlaskStarter implements CommandLineRunner {
//
//    @Override
//    public void run(String... args) throws Exception {
//        // Đường dẫn tới file activate trong môi trường ảo myenv
//        String activateScript = "D:/ai-demo/myenv/Scripts/activate.bat";
//
//        // Đường dẫn tới tệp Python của bạn
//        String scriptPath = "D:/ai-demo/app_yolo.py";
//
//        // Khởi chạy command để kích hoạt môi trường ảo và chạy Flask
//        ProcessBuilder processBuilder = new ProcessBuilder("cmd.exe", "/c", activateScript + " && python " + scriptPath);
//        processBuilder.inheritIO(); // Hiển thị đầu ra của quá trình trong console Spring Boot
//
//        try {
//            // Khởi động Flask từ môi trường ảo
//            Process flaskProcess = processBuilder.start();
//
//            // Kiểm tra xem Flask đã khởi động thành công chưa
//            boolean flaskStarted = false;
//            int maxRetries = 10;
//            int retries = 0;
//
//            while (!flaskStarted && retries < maxRetries) {
//                try {
//                    // Gửi yêu cầu GET đến một endpoint của Flask để kiểm tra
//                    HttpURLConnection connection = (HttpURLConnection) new URL("http://localhost:8000/").openConnection();
//                    connection.setRequestMethod("GET");
//                    connection.setConnectTimeout(2000);
//                    int responseCode = connection.getResponseCode();
//                    if (responseCode == 200) {
//                        flaskStarted = true;
//                        System.out.println("Flask đã khởi động thành công!");
//                    }
//                } catch (IOException e) {
//                    retries++;
//                    System.out.println("Đang chờ Flask khởi động... (lần thử " + retries + ")");
//                    TimeUnit.SECONDS.sleep(2); // Đợi 2 giây trước khi thử lại
//                }
//            }
//
//            if (!flaskStarted) {
//                System.err.println("Flask không thể khởi động sau " + maxRetries + " lần thử.");
//                flaskProcess.destroy(); // Hủy quá trình Flask nếu không thể khởi động
//            }
//
//        } catch (IOException e) {
//            e.printStackTrace();
//            System.err.println("Không thể khởi động Flask: " + e.getMessage());
//        }
//    }
//}
