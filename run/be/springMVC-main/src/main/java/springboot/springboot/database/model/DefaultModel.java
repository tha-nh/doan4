package springboot.springboot.database.model;

import org.reflections.scanners.SubTypesScanner;
import org.reflections.util.ConfigurationBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.reflections.Reflections;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;
import springboot.springboot.database.entity.Entity;
import springboot.springboot.database.connectDTB.MySqlConnect;
import springboot.springboot.database.entity.Feedback;


import javax.sql.DataSource;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.*;

@Component
public class DefaultModel<T extends Entity<?>> implements ModelBuidDAO {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    private List<T> entities = new ArrayList<>();// T dai dien cho cac thuc the entity( Product, Customer....)
    public static Connection connection;

    public static Connection openConnection() throws SQLException {
        connection = MySqlConnect.getMySQLConnection();
        return connection;
    }

    public static PreparedStatement pstm;


    public static PreparedStatement openPstm(String query) throws SQLException {
        if (pstm != null && !pstm.isClosed()) {
            pstm.close();
        }
        pstm = openConnection().prepareStatement(query);
        return pstm;
    }


    public static boolean exUpdate() throws SQLException {
        int check = pstm.executeUpdate();
        return check > 0;
    }

    public static ResultSet exQuery() throws SQLException {
        ResultSet rs = pstm.executeQuery();
        return rs;
    }

    private String getTableName(Class<T> entityClass) {
        String tableName = entityClass.getSimpleName();
        return tableName;
    }

    private StringBuilder queryInsert(Entity entity) {
        String tableName = getTableName((Class<T>) entity.getClass());
        StringBuilder query = new StringBuilder("insert into ");
        query.append(tableName).append(" (");
        Field[] fields = entity.getClass().getDeclaredFields();
        List<Field> includedFields = new ArrayList<>();
        List<Object> fieldValues = new ArrayList<>();
        for (Field field : fields) {
            field.setAccessible(true);
            try {
                Object value = field.get(entity);
                if (value != null && !"0".equals(value.toString())) {
                    includedFields.add(field);
                    fieldValues.add(value);
                }
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
        }
        for (int i = 0; i < includedFields.size(); i++) {
            if (i > 0) {
                query.append(", ");
            }
            query.append(includedFields.get(i).getName());
        }
        query.append(") values (");

        for (int i = 0; i < includedFields.size(); i++) {
            if (i > 0) {
                query.append(", ");
            }
            query.append("?");
        }
        query.append(")");
        // In ra các trường và giá trị của chúng
        for (int i = 0; i < includedFields.size(); i++) {
            System.out.println(includedFields.get(i).getName());
            System.out.println(fieldValues.get(i));
        }

        return query;
    }


    private StringBuilder queryUpdate(Entity entity) {
        String tableName = getTableName((Class<T>) entity.getClass());
        StringBuilder query = new StringBuilder("update ");
        query.append(tableName).append(" set ");

        Field[] fields = entity.getClass().getDeclaredFields();
        Field idField = fields[0];

        List<Field> updatedFields = new ArrayList<>();
        List<Object> fieldValues = new ArrayList<>();

        for (int i = 1; i < fields.length; i++) {
            fields[i].setAccessible(true);
            try {
                Object value = fields[i].get(entity);
                if (value != null && !"0".equals(value.toString())) {
                    updatedFields.add(fields[i]);
                    fieldValues.add(value);
                }
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }
        }

        for (int i = 0; i < updatedFields.size(); i++) {
            if (i > 0) {
                query.append(", ");
            }
            query.append(updatedFields.get(i).getName()).append(" = ").append("?");

            // In ra tên trường và giá trị của trường
            System.out.println(updatedFields.get(i).getName());
            System.out.println(fieldValues.get(i));
        }

        query.append(" where ").append(idField.getName()).append(" = ?");

        // In ra tên trường id và giá trị của trường id
        idField.setAccessible(true);
        try {
            Object idValue = idField.get(entity);

            System.out.println(idField.getName());
            System.out.println(idValue);
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }

        return query;
    }

    private StringBuilder queryDelete(Entity entity) {
        String tableName = getTableName((Class<T>) entity.getClass());
        StringBuilder query = new StringBuilder("delete from ");
        query.append(tableName).append(" where ");
        Field[] fields = entity.getClass().getDeclaredFields();
        boolean foundField = false; // Biến để xác định xem trường nào có giá trị không

        for (Field field : fields) {
            field.setAccessible(true);
            try {
                Object value = field.get(entity);
                if (value != null && !"0".equals(value.toString())) {
                    // Bỏ field có giá trị là null hoặc 0
                    System.out.println(value);
                    if (foundField) {
                        query.append(" and ");
                    }
                    query.append(field.getName()).append(" = ?");
                    foundField = true; // Đánh dấu rằng đã tìm thấy trường có giá trị
                }
            } catch (IllegalAccessException e) {
                e.printStackTrace(); // Xử lý exception theo cách phù hợp
            }
        }

        if (!foundField) {
            // Xử lý trường hợp không tìm thấy trường có giá trị
            // Ví dụ: Ghi log, throw exception, hoặc thực hiện hành động khác
        }
        return query;
    }

    public List<Entity> executeQueryGetAll(Entity entity) throws IllegalAccessException {
        StringBuilder query = queryGetAll(entity);
        Object[] params = extractParams(entity);

        return jdbcTemplate.query(query.toString(), params, new RowMapper<Entity>() {
            @Override
            public Entity mapRow(ResultSet rs, int rowNum) throws SQLException {
                try {
                    Entity resultEntity = entity.getClass().newInstance();
                    Field[] fields = entity.getClass().getDeclaredFields();
                    for (Field field : fields) {
                        field.setAccessible(true);
                        field.set(resultEntity, rs.getObject(field.getName()));
                    }
                    return resultEntity;
                } catch (InstantiationException | IllegalAccessException e) {
                    throw new SQLException("Error mapping row to entity", e);
                }
            }
        });
    }

    private Object[] extractParams(Entity entity) throws IllegalAccessException {
        List<Object> params = new ArrayList<>();
        Field[] fields = entity.getClass().getDeclaredFields();

        for (Field field : fields) {
            field.setAccessible(true);
            Object value = field.get(entity);
            if (value != null && !"0".equals(value.toString())) {
                params.add(value);
            }
        }

        return params.toArray();
    }

    private StringBuilder queryGetAll(Class<T> entityClass) {
        String tableName = getTableName(entityClass);
        StringBuilder query = new StringBuilder("select * from ");
        query.append(tableName);
        return query;
    }

    private String extractTableName(Class<?> clazz) {
        return clazz.getSimpleName().toLowerCase();
    }

    private Set<Class<? extends Entity>> getAllEntitySubclasses() {
        Reflections reflections = new Reflections(
                new ConfigurationBuilder()
                        .forPackages("springboot.springboot.database.entity") // Replace with your package name
                        .addScanners(new SubTypesScanner(false))
        );
        return reflections.getSubTypesOf(Entity.class);
    }

    public StringBuilder queryGetAll(Entity entity) throws IllegalAccessException {
        StringBuilder query = new StringBuilder("SELECT * FROM ");

        // Get all subclasses of Entity
        Set<Class<? extends Entity>> entityClasses = getAllEntitySubclasses();
        Map<String, Set<Field>> tableFieldMap = new HashMap<>();

        // Map table names to their fields
        for (Class<? extends Entity> entityClass : entityClasses) {
            String tableName = extractTableName(entityClass);
            Set<Field> fields = new HashSet<>();
            for (Field field : entityClass.getDeclaredFields()) {
                fields.add(field);
            }
            tableFieldMap.put(tableName, fields);
        }

        // Create join part of the query
        boolean firstTable = true;
        String previousTableName = null;
        for (String tableName : tableFieldMap.keySet()) {
            if (!firstTable) {
                query.append(" JOIN ").append(tableName).append(" ").append(tableName.substring(0, 1));
                // Find common fields between the current and previous table for join condition
                String joinCondition = findJoinCondition(tableFieldMap, previousTableName, tableName, new HashSet<>());
                if (joinCondition != null) {
                    query.append(" ON ").append(joinCondition);
                } else {
                    throw new IllegalStateException("No join condition found between " + previousTableName + " and " + tableName);
                }
            } else {
                query.append(tableName).append(" ").append(tableName.substring(0, 1));
                firstTable = false;
            }
            previousTableName = tableName;
        }

        // Append the WHERE clause
        Field[] fields = entity.getClass().getDeclaredFields();
        boolean foundField = false;
        for (Field field : fields) {
            field.setAccessible(true);
            Object value = field.get(entity);
            if (value != null && !"0".equals(value.toString())) {
                if (!foundField) {
                    query.append(" WHERE ");
                    foundField = true;
                } else {
                    query.append(" AND ");
                }
                String tableName = extractTableName(entity.getClass());
                query.append(tableName).append(".").append(field.getName()).append(" = ?");
            }
        }

        System.out.println(query.toString());
        return query;
    }


    private String findJoinCondition(Map<String, Set<Field>> tableFieldMap, String table1, String table2, Set<String> visitedTables) {
        visitedTables.add(table1);

        String directJoinCondition = getJoinCondition(tableFieldMap, table1, table2);
        if (directJoinCondition != null) {
            return directJoinCondition;
        }

        for (String intermediateTable : tableFieldMap.keySet()) {
            if (!visitedTables.contains(intermediateTable)) {
                String joinCondition1 = getJoinCondition(tableFieldMap, table1, intermediateTable);
                String joinCondition2 = getJoinCondition(tableFieldMap, intermediateTable, table2);
                if (joinCondition1 != null && joinCondition2 != null) {
                    return joinCondition1 + " AND " + joinCondition2;
                } else {
                    String recursiveJoinCondition = findJoinCondition(tableFieldMap, intermediateTable, table2, visitedTables);
                    if (recursiveJoinCondition != null) {
                        if (joinCondition1 != null) {
                            return joinCondition1 + " AND " + recursiveJoinCondition;
                        } else {
                            return recursiveJoinCondition;
                        }
                    }
                }
            }
        }

        return null;
    }

    private String getJoinCondition(Map<String, Set<Field>> tableFieldMap, String table1, String table2) {
        Set<Field> fieldsTable1 = tableFieldMap.get(table1);
        Set<Field> fieldsTable2 = tableFieldMap.get(table2);

        for (Field field1 : fieldsTable1) {
            for (Field field2 : fieldsTable2) {
                if (field1.getName().equals(field2.getName()) && field1.getType().equals(field2.getType()) && field1.getType().equals(int.class)) {
                    return table1 + "." + field1.getName() + " = " + table2 + "." + field2.getName();
                }
            }
        }

        return null; // No common field found for join
    }


    public List<Entity> executeQuery(String query, Entity entity) throws SQLException, IllegalAccessException, InstantiationException, NoSuchMethodException, InvocationTargetException {
        List<Entity> entities = new ArrayList<>();
        jdbcTemplate.query(query, rs -> {
            Entity resultEntity = null;
            try {
                resultEntity = entity.getClass().getDeclaredConstructor().newInstance();
            } catch (InstantiationException e) {
                throw new RuntimeException(e);
            } catch (IllegalAccessException e) {
                throw new RuntimeException(e);
            } catch (InvocationTargetException e) {
                throw new RuntimeException(e);
            } catch (NoSuchMethodException e) {
                throw new RuntimeException(e);
            }
            for (Field field : entity.getClass().getDeclaredFields()) {
                field.setAccessible(true);
                try {
                    field.set(resultEntity, rs.getObject(field.getName()));
                } catch (IllegalAccessException e) {
                    throw new RuntimeException(e);
                }
            }
            entities.add(resultEntity);
        });
        return entities;
    }

    private StringBuilder queryGetEntityById(Entity entity) {
        String tableName = getTableName((Class<T>) entity.getClass());
        StringBuilder query = new StringBuilder("select * from ");
        query.append(tableName).append(" where ");

        Field[] fields = entity.getClass().getDeclaredFields();
        boolean foundField = false; // Biến để xác định xem trường nào có giá trị không

        for (Field field : fields) {
            field.setAccessible(true);
            try {
                Object value = field.get(entity);
                if (value != null && !"0".equals(value.toString())) {
                    // Bỏ field có giá trị là null hoặc 0
                    System.out.println(value);
                    if (foundField) {
                        query.append(" and ");
                    }
                    query.append(field.getName()).append(" = ?");
                    foundField = true; // Đánh dấu rằng đã tìm thấy trường có giá trị
                }
            } catch (IllegalAccessException e) {
                e.printStackTrace(); // Xử lý exception theo cách phù hợp
            }
        }

        if (!foundField) {
            // Xử lý trường hợp không tìm thấy trường có giá trị
            // Ví dụ: Ghi log, throw exception, hoặc thực hiện hành động khác
        }

        return query;
    }

    @Override
    public int insert(Entity entity) throws SQLException, IllegalAccessException {
        Field[] fields = entity.getClass().getDeclaredFields();
        String query = queryInsert(entity).toString();
        PreparedStatement preparedStatement = openConnection().prepareStatement(query, PreparedStatement.RETURN_GENERATED_KEYS);
        System.out.println(query);
        int parameterIndex = 1;
        for (Field field : fields) {
            field.setAccessible(true);
            Object value = field.get(entity);
            if (value != null && !"0".equals(value.toString())) {
                preparedStatement.setObject(parameterIndex++, value);
            }
        }
        int rowsAffected = preparedStatement.executeUpdate();
        if (rowsAffected > 0) {
            ResultSet generatedKeys = preparedStatement.getGeneratedKeys();
            if (generatedKeys.next()) {
                int generatedKey = generatedKeys.getInt(1);
                return generatedKey;
            } else {
                throw new SQLException("Creating record failed, no ID obtained.");
            }
        } else {
            throw new SQLException("Creating record failed, no rows affected.");
        }
    }

    @Override
    public void insertAll(List entity) throws SQLException, IllegalAccessException {
        List<Entity> entityList = entity;
        PreparedStatement pstm = null;

        try {
            for (Entity entity1 : entityList) {
                String query = queryInsert(entity1).toString(); // Tạo query insert riêng cho từng phần tử
                pstm = openPstm(query);
                System.out.println(query);
                Field[] fields = entity1.getClass().getDeclaredFields();
                int parameterIndex = 1;
                for (Field field : fields) {
                    field.setAccessible(true);
                    Object value = field.get(entity1);
                    if (value != null && !"0".equals(value.toString())) {
                        pstm.setObject(parameterIndex++, value);
                    }
                }

                pstm.executeUpdate(); // Thực hiện insert cho từng phần tử
            }
        } finally {
            if (pstm != null) {
                pstm.close();
            }
        }
    }

    @Override
    public boolean update(Entity entity) throws SQLException, IllegalAccessException {
        System.out.println(entity);
        Field[] fields = entity.getClass().getDeclaredFields();
        String query = queryUpdate(entity).toString();
        System.out.println(query);
        pstm = openPstm(query);

        int parameterIndex = 1;
        for (int i = 1; i < fields.length; i++) {
            fields[i].setAccessible(true);
            Object value = fields[i].get(entity);
            if (value != null && !"0".equals(value.toString())) {
                pstm.setObject(parameterIndex++, value);
            }
        }

        fields[0].setAccessible(true);
        Object value1 = fields[0].get(entity);
        pstm.setObject(parameterIndex, value1);

        boolean rowsUpdated = exUpdate();
        System.out.println(rowsUpdated);
        return rowsUpdated;
    }

    @Override
    public boolean delete(Entity entity) throws IllegalAccessException, SQLException {
        String query = queryDelete(entity).toString();
        System.out.println(query);
        pstm = openPstm(query);
        Field[] fields = entity.getClass().getDeclaredFields();
        List<Field> validFields = new ArrayList<>();
        for (Field f : fields) {
            f.setAccessible(true);
            Object val = f.get(entity);
            if (val != null && !"0".equals(val.toString())) {
                validFields.add(f);
            }
        }
        int index = 1;
        for (Field f : validFields) {
            Object val = f.get(entity);
            pstm.setObject(index, val);
            index++;
        }
        boolean rowsUpdated = exUpdate();
        System.out.println(rowsUpdated);
        return rowsUpdated;
    }

    @Override
    public List<T> getAll(Class entityClass) throws SQLException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        List<T> entities = new ArrayList<>();
        String query = queryGetAll(entityClass).toString();
        pstm = openPstm(query);
        System.out.println(query);
        ResultSet rs = exQuery();
        while (rs.next()) {
            T newEntity = (T) createEntityFromResultSet(rs, entityClass);
            entities.add(newEntity);
        }
        return entities;
    }


    private T createEntityFromResultSet(ResultSet rs, Class<T> entityClass) throws SQLException, NoSuchMethodException, InvocationTargetException, InstantiationException, IllegalAccessException {
        T newEntity = entityClass.getDeclaredConstructor().newInstance();
        ResultSetMetaData metaData = rs.getMetaData();
        int columnCount = metaData.getColumnCount();
        for (int i = 1; i <= columnCount; i++) {
            String columnName = metaData.getColumnName(i);
            Field field = null;
            try {
                field = entityClass.getDeclaredField(columnName);
            } catch (NoSuchFieldException e) {
                // Field không tồn tại trong lớp entityClass, bỏ qua
                continue;
            }

            field.setAccessible(true);
            Object value = rs.getObject(columnName);
            if (value != null) {
                // Kiểm tra nếu trường là LocalDateTime và giá trị là Timestamp
                if (field.getType().equals(LocalDateTime.class) && value instanceof Timestamp) {
                    field.set(newEntity, ((Timestamp) value).toLocalDateTime());
                } else {
                    field.set(newEntity, value);
                }
            }
        }
        return newEntity;
    }




    @Override
    public List<T> getEntityById(Entity entity) throws SQLException, IllegalAccessException, InstantiationException {
        List<T> entityList = new ArrayList<>(); // Khai báo và khởi tạo entityList

        String query = queryGetEntityById(entity).toString();
        System.out.println("SQL Query: " + query);

        // Đảm bảo rằng PreparedStatement và ResultSet được quản lý tốt
        try (PreparedStatement pstm = openPstm(query)) {
            Field[] fields = entity.getClass().getDeclaredFields();
            List<Field> validFields = new ArrayList<>();

            for (Field f : fields) {
                f.setAccessible(true);
                Object val = f.get(entity);
                if (val != null && !"0".equals(val.toString())) {
                    validFields.add(f);
                }
            }

            int index = 1;
            for (Field f : validFields) {
                Object val = f.get(entity);
                pstm.setObject(index, val);
                index++;
            }

            try (ResultSet rs = pstm.executeQuery()) {
                if (rs == null) {
                    throw new SQLException("ResultSet is null");
                }

                ResultSetMetaData metaData = rs.getMetaData();
                if (metaData == null) {
                    throw new SQLException("ResultSetMetaData is null");
                }

                System.out.println("Column Count: " + metaData.getColumnCount());

                while (rs.next()) {
                    T newEntity = (T) entity.getClass().newInstance();
                    for (int i = 1; i <= metaData.getColumnCount(); i++) {
                        String columnName = metaData.getColumnName(i);
                        for (Field field : fields) {
                            field.setAccessible(true);
                            if (field.getName().equals(columnName)) {
                                Object fieldValue = rs.getObject(i);
                                // Kiểm tra nếu fieldValue là null và kiểu dữ liệu của field là nguyên thủy (như int)
                                if (fieldValue == null && field.getType().isPrimitive()) {
                                    // Nếu fieldValue là null và field là nguyên thủy, bỏ qua việc thiết lập giá trị
                                    continue;
                                }
                                field.set(newEntity, fieldValue);
                                break;
                            }
                        }
                    }
                    System.out.println(newEntity.toString());
                    entityList.add(newEntity);
                }
            }
        }

        return entityList;
    }







    public T getManyToOne(Entity entity) throws SQLException, IllegalAccessException, InstantiationException {
        String query = queryGetEntityById(entity).toString();
        System.out.println(query);
        openPstm(query);

        Field[] fields = entity.getClass().getDeclaredFields();
        List<Field> validFields = new ArrayList<>();

        for (Field f : fields) {
            f.setAccessible(true);
            Object val = f.get(entity);
            if (val != null && !"0".equals(val.toString())) {
                validFields.add(f);
            }
        }

        int index = 1;
        for (Field f : validFields) {
            Object val = f.get(entity);
            pstm.setObject(index, val);
            index++;
        }
        ResultSet rs = exQuery();

        T newEntity = null;
        if (rs.next()) {
            newEntity = (T) entity.getClass().newInstance();
            for (int i = 1; i <= rs.getMetaData().getColumnCount(); i++) {
                String columnName = rs.getMetaData().getColumnName(i);
                for (Field field : fields) {
                    field.setAccessible(true);
                    if (field.getName().equals(columnName)) {
                        Object fieldValue = rs.getObject(i);
                        field.set(newEntity, fieldValue);
                        System.out.println(field.getName() + ": " + fieldValue);
                        break;
                    }
                }
            }
        }

        return newEntity;
    }

    public List<Entity> getEntityListById(List<Entity> listObject) throws SQLException {
        List<Entity> entityList = new ArrayList<>();
        Connection conn = null;
        PreparedStatement pstm = null;
        ResultSet rs = null;

        try {
            conn = openConnection(); // Lấy kết nối tới cơ sở dữ liệu

            for (Entity entity : listObject) {
                String query = queryGetEntityById(entity).toString();
                System.out.println(query);
                pstm = conn.prepareStatement(query);

                Field[] fields = entity.getClass().getDeclaredFields();
                List<Field> validFields = new ArrayList<>();

                for (Field f : fields) {
                    f.setAccessible(true);
                    Object val = f.get(entity);
                    if (val != null && !"0".equals(val.toString())) {
                        validFields.add(f);
                    }
                }

                int index = 1;
                for (Field f : validFields) {
                    Object val = f.get(entity);
                    pstm.setObject(index, val);
                    index++;
                }

                rs = pstm.executeQuery();

                List<Entity> tempEntityList = new ArrayList<>(); // Tạo một list tạm để lưu trữ entity mới

                while (rs.next()) {
                    Entity newEntity = entity.getClass().getDeclaredConstructor().newInstance();
                    for (Field field : fields) {
                        field.setAccessible(true);
                        String columnName = field.getName();
                        Object fieldValue = rs.getObject(columnName);

                        if (fieldValue != null && !"0".equals(fieldValue.toString())) {
                            field.set(newEntity, fieldValue);
                            System.out.println(columnName + ": " + fieldValue);
                        }
                    }
                    tempEntityList.add(newEntity);
                }

                entityList.addAll(tempEntityList); // Thêm tất cả entity mới vào entityList sau khi xử lý ResultSet
            }
        } catch (InstantiationException | IllegalAccessException | InvocationTargetException |
                 NoSuchMethodException e) {
            // Xử lý ngoại lệ khi tạo mới Entity không thành công
            e.printStackTrace();
        } finally {
            if (rs != null) {
                rs.close();
            }
            if (pstm != null) {
                pstm.close();
            }
            if (conn != null) {
                conn.close(); // Đóng kết nối
            }
        }

        return entityList;
    }

    public void insertAll1(List<Entity> objectList) throws SQLException, IllegalAccessException {
        for (Entity entity : objectList) {
            PreparedStatement pstm = null;
            try {
                String query = queryInsert(entity).toString(); // Tạo query insert riêng cho từng phần tử
                pstm = openPstm(query);
                System.out.println(query);
                Field[] fields = entity.getClass().getDeclaredFields();
                int parameterIndex = 1;
                for (Field field : fields) {
                    field.setAccessible(true);
                    Object value = field.get(entity);
                    if (value != null && !"0".equals(value.toString())) {
                        pstm.setObject(parameterIndex++, value);
                    }
                }
                pstm.executeUpdate(); // Thực hiện insert cho từng phần tử
            } finally {
                if (pstm != null) {
                    pstm.close();
                }
            }
        }
    }

    public void forgotPassword(String patientEmail, String patientCode) throws SQLException {
        StringBuilder query = queryforgot(patientEmail, patientCode);
        try (Connection connection = openConnection();
             PreparedStatement preparedStatement = connection.prepareStatement(query.toString())) {

            // Đặt các giá trị tham số cho câu lệnh SQL
            preparedStatement.setString(1, patientCode);
            preparedStatement.setString(2, patientEmail);

            int rowsAffected = preparedStatement.executeUpdate();
            if (rowsAffected == 0) {
                throw new SQLException("Updating record failed, no rows affected.");
            }
        }
    }

    private StringBuilder queryforgot(String patientEmail, String patientCode) {
        String tableName = "patients"; // Tên bảng trong cơ sở dữ liệu
        StringBuilder query = new StringBuilder("UPDATE ");
        query.append(tableName).append(" SET ");

        // Thêm patient_code vào phần set
        query.append("patient_code = ?");

        // Thêm điều kiện where với patient_email
        query.append(" WHERE patient_email = ?");

        // In ra câu lệnh SQL để kiểm tra
        System.out.println("SQL Query: " + query.toString());
        System.out.println("patient_code: " + patientCode);
        System.out.println("patient_email: " + patientEmail);

        return query;
    }

    public void resetPassword(String patientEmail, String patientCode, String newPassword) throws SQLException {
        String query = "UPDATE patients SET patient_password = ?, patient_code = NULL WHERE patient_email = ? AND patient_code = ?";
        System.out.println(query);
        try (Connection connection = openConnection();
             PreparedStatement preparedStatement = connection.prepareStatement(query)) {

            preparedStatement.setString(1, newPassword);
            preparedStatement.setString(2, patientEmail);
            preparedStatement.setString(3, patientCode);

            int rowsAffected = preparedStatement.executeUpdate();
            if (rowsAffected == 0) {
                throw new SQLException("Updating password failed, no rows affected.");
            }
        }
    }

    public void saveFeedback(Feedback feedback) throws SQLException {
        String sql = "INSERT INTO feedback (name, phone, email, subject, message, created_at) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection connection = openConnection();
             PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, feedback.getName());
            stmt.setString(2, feedback.getPhone());
            stmt.setString(3, feedback.getEmail());
            stmt.setString(4, feedback.getSubject());
            stmt.setString(5, feedback.getMessage());
            stmt.setTimestamp(6, Timestamp.valueOf(feedback.getCreated_at()));
            stmt.executeUpdate();
        }
    }
}

