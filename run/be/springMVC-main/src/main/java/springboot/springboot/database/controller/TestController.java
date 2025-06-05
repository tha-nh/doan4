package springboot.springboot.database.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;

@RestController
public class TestController {

    @Autowired
    private DataSource dataSource;

    @GetMapping("/test-db")
    public String testDatabase() {
        try (Connection connection = dataSource.getConnection()) {
            return "✅ Database connection successful!\n" +
                    "Database: " + connection.getCatalog() + "\n" +
                    "URL: " + connection.getMetaData().getURL();
        } catch (Exception e) {
            return "❌ Database connection failed: " + e.getMessage();
        }
    }

    @GetMapping("/health")
    public String health() {
        return "🚀 FPT Healthcare API is running!";
    }
}