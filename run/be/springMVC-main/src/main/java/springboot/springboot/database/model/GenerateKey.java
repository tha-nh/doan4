package springboot.springboot.database.model;

public class GenerateKey {
//    private static final String URL = "jdbc:mysql://localhost:3306/database_name";
//    private static final String USERNAME = "username";
//    private static final String PASSWORD = "password";
//
//    public static void main(String[] args) {
//        try {
//            Connection connection = DriverManager.getConnection(URL, USERNAME, PASSWORD);
//
//            // Tạo câu lệnh SQL để insert dữ liệu vào bảng 1
//            String query1 = "INSERT INTO table1 (column1, column2) VALUES (?, ?)";
//            PreparedStatement statement1 = connection.prepareStatement(query1, PreparedStatement.RETURN_GENERATED_KEYS);
//            statement1.setString(1, "value1");
//            statement1.setString(2, "value2");
//            statement1.executeUpdate();
//
//            // Lấy khóa chính của bản 1
//            int key1 = -1;
//            ResultSet resultSet = statement1.getGeneratedKeys();
//            if (resultSet.next()) {
//                key1 = resultSet.getInt(1);
//            }
//
//            // Tạo câu lệnh SQL để insert dữ liệu vào bảng 2 sử dụng khóa ngoại của bảng 1
//            String query2 = "INSERT INTO table2 (column1, column2, foreign_key) VALUES (?, ?, ?)";
//            PreparedStatement statement2 = connection.prepareStatement(query2);
//            statement2.setString(1, "value3");
//            statement2.setString(2, "value4");
//            statement2.setInt(3, key1);
//            statement2.executeUpdate();
//
//            connection.close();
//        } catch (SQLException e) {
//            e.printStackTrace();
//        }
//    }





//public <T> List<T> getEntityByField(Entity entity, String fieldName) throws SQLException, IllegalAccessException, InstantiationException {
//    String query = "SELECT * FROM " + entity.getTableName() + " WHERE " + fieldName + " = ?";
//    openPstm(query);
//
//    Field[] fields = entity.getClass().getDeclaredFields();
//    Map<String, Field> fieldMap = new HashMap<>();
//    for (Field field : fields) {
//        fieldMap.put(field.getName(), field);
//    }
//
//    Field field = fieldMap.get(fieldName);
//    field.setAccessible(true);
//    Object value = field.get(entity);
//    pstm.setObject(1, value);
//
//    ResultSet rs = exQuery();
//    List<T> entityList = new ArrayList<>();
//    while (rs.next()) {
//        T newEntity = (T) entity.getClass().newInstance();
//        for (int i = 1; i <= rs.getMetaData().getColumnCount(); i++) {
//            String columnName = rs.getMetaData().getColumnName(i);
//            Field entityField = fieldMap.get(columnName);
//            if (entityField != null) {
//                entityField.setAccessible(true);
//                Object fieldValue = rs.getObject(i);
//                entityField.set(newEntity, fieldValue);
//            }
//        }
//        entityList.add(newEntity);
//    }
//    return entityList;
//}






    //public void getPrimaryAndForeignKeys(Connection connection) throws SQLException {
//    DatabaseMetaData metaData = connection.getMetaData();
//
//    // Lấy thông tin về các bảng trong cơ sở dữ liệu
//    ResultSet tables = metaData.getTables(null, null, null, new String[]{"TABLE"});
//    while (tables.next()) {
//        String tableName = tables.getString("TABLE_NAME");
//
//        // Lấy thông tin về các khóa chính của bảng
//        ResultSet primaryKeys = metaData.getPrimaryKeys(null, null, tableName);
//        while (primaryKeys.next()) {
//            String primaryKeyColumnName = primaryKeys.getString("COLUMN_NAME");
//            // Xử lý thông tin về khóa chính
//            System.out.println("Primary key column in table " + tableName + ": " + primaryKeyColumnName);
//        }
//
//        // Lấy thông tin về các khóa ngoại của bảng
//        ResultSet foreignKeys = metaData.getImportedKeys(null, null, tableName);
//        while (foreignKeys.next()) {
//            String foreignKeyColumnName = foreignKeys.getString("FKCOLUMN_NAME");
//            String referencedTableName = foreignKeys.getString("PKTABLE_NAME");
//            String referencedColumnNameName = foreignKeys.getString("PKCOLUMN_NAME");
//            // Xử lý thông tin về khóa ngoại
//            System.out.println("Foreign key column in table " + tableName + ": " + foreignKeyColumnName);
//            System.out.println("Referenced table: " + referencedTableName);
//            System.out.println("Referenced column: " + referencedColumnNameName);
//        }
//    }
//}




//    public void insertAll(List<Entity> entityList) throws SQLException, IllegalAccessException {
//        String query = queryInsert(new Entity()).toString();
//        PreparedStatement preparedStatement = openConnection().prepareStatement(query, PreparedStatement.RETURN_GENERATED_KEYS);
//
//        for (Entity entity : entityList) {
//            Field[] fields = entity.getClass().getDeclaredFields();
//            int parameterIndex = 1;
//
//            for (Field field : fields) {
//                field.setAccessible(true);
//                Object value = field.get(entity);
//                preparedStatement.setObject(parameterIndex++, value);
//            }
//
//            preparedStatement.addBatch(); // Thêm tham số vào batch
//        }
//
//        preparedStatement.executeBatch(); // Thực hiện batch
//    }
}