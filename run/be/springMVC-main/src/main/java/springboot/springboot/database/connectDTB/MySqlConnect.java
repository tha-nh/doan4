package springboot.springboot.database.connectDTB;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class MySqlConnect {

    public static Connection getMySQLConnection() throws SQLException {
        // Thông tin kết nối cơ sở dữ liệu Azure MySQL
        String hostName = "fpthealth.mysql.database.azure.com";
        String dbName = "fpthealth";
        String userName = "duongthu";
        String password = "Thu@456258"; // Đặt mật khẩu của bạn
        String connectionURL = "jdbc:mysql://" + hostName + ":3306/" + dbName + "?useSSL=true&requireSSL=true";
        return DriverManager.getConnection(connectionURL, userName, password);
    }
}
