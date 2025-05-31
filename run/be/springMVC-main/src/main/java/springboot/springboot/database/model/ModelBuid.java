package springboot.springboot.database.model;
import org.reflections.scanners.SubTypesScanner;
import org.reflections.util.ConfigurationBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.reflections.Reflections;
import org.springframework.stereotype.Component;
import springboot.springboot.database.entity.*;
import javax.sql.DataSource;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.*;

@Component
public class ModelBuid<T extends Entity<?>> implements ModelBuidDAO {
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private DataSource dataSource;

    private List<T> entities = new ArrayList<>();

    public Connection openConnection() throws SQLException {
        return dataSource.getConnection();
    }

    public PreparedStatement openPstm(String query, Connection connection) throws SQLException {
        return connection.prepareStatement(query, Statement.RETURN_GENERATED_KEYS);
    }

    public boolean exUpdate(PreparedStatement pstm) throws SQLException {
        int check = pstm.executeUpdate();
        return check > 0;
    }

    public ResultSet exQuery(PreparedStatement pstm) throws SQLException {
        return pstm.executeQuery();
    }

    private String getTableName(Class<T> entityClass) {
        return entityClass.getSimpleName();
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
                    System.out.println(value + " field" + field.getName());
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
        try (Connection connection = openConnection();
             PreparedStatement preparedStatement = openPstm(query, connection)) {
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
                    return generatedKeys.getInt(1);
                } else {
                    throw new SQLException("Tạo bản ghi thất bại, không có ID nào được lấy ra.");
                }
            } else {
                throw new SQLException("Tạo bản ghi thất bại, không có hàng nào bị ảnh hưởng.");
            }
        }
    }

    @Override
    public void insertAll(List entity) throws SQLException, IllegalAccessException {
        List<Entity> entityList = entity;
        try (Connection connection = openConnection()) {
            for (Entity entity1 : entityList) {
                String query = queryInsert(entity1).toString();
                try (PreparedStatement pstm = openPstm(query, connection)) {
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
                    pstm.executeUpdate();
                }
            }
        }
    }

    @Override
    public boolean update(Entity entity) throws SQLException, IllegalAccessException {
        System.out.println(entity);
        Field[] fields = entity.getClass().getDeclaredFields();
        String query = queryUpdate(entity).toString();
        System.out.println(query);
        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query, connection)) {
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

            boolean rowsUpdated = exUpdate(pstm);
            System.out.println(rowsUpdated);
            return rowsUpdated;
        }
    }

    @Override
    public boolean delete(Entity entity) throws IllegalAccessException, SQLException {
        String query = queryDelete(entity).toString();
        System.out.println(query);
        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query, connection)) {
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
            boolean rowsUpdated = exUpdate(pstm);
            System.out.println(rowsUpdated);
            return rowsUpdated;
        }
    }

    @Override
    public List<T> getAll(Class entityClass) throws SQLException, InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        List<T> entities = new ArrayList<>();
        String query = queryGetAll(entityClass).toString();
        System.out.println(query);
        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query, connection);
             ResultSet rs = exQuery(pstm)) {
            while (rs.next()) {
                T newEntity = (T) createEntityFromResultSet(rs, entityClass);
                entities.add(newEntity);
            }
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
                continue;
            }
            field.setAccessible(true);
            Object value = rs.getObject(columnName);
            if (value != null) {
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
        List<T> entityList = new ArrayList<>();
        String query = queryGetEntityById(entity).toString();
        System.out.println("SQL Query: " + query);
        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query, connection)) {
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
                                if (fieldValue == null && field.getType().isPrimitive()) {
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

    public List<Entity> getEntityListById(List<Entity> listObject) throws SQLException {
        List<Entity> entityList = new ArrayList<>();
        try (Connection connection = openConnection()) {
            for (Entity entity : listObject) {
                String query = queryGetEntityById(entity).toString();
                System.out.println(query);
                try (PreparedStatement pstm = openPstm(query, connection)) {
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
                        List<Entity> tempEntityList = new ArrayList<>();
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
                        entityList.addAll(tempEntityList);
                    }
                }
            }
        } catch (InstantiationException | IllegalAccessException | InvocationTargetException | NoSuchMethodException e) {
            e.printStackTrace();
        }
        return entityList;
    }

    public void insertAll1(List<Entity> objectList) throws SQLException, IllegalAccessException {
        try (Connection connection = openConnection()) {
            for (Entity entity : objectList) {
                String query = queryInsert(entity).toString();
                try (PreparedStatement pstm = openPstm(query, connection)) {
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
                    pstm.executeUpdate();
                }
            }
        }
    }

    public void forgotPassword(String patientEmail, String patientCode) throws SQLException {
        StringBuilder query = queryforgot(patientEmail, patientCode);
        try (Connection connection = openConnection();
             PreparedStatement preparedStatement = openPstm(query.toString(), connection)) {
            preparedStatement.setString(1, patientCode);
            preparedStatement.setString(2, patientEmail);
            int rowsAffected = preparedStatement.executeUpdate();
            if (rowsAffected == 0) {
                throw new SQLException("Updating record failed, no rows affected.");
            }
        }
    }

    private StringBuilder queryforgot(String patientEmail, String patientCode) {
        String tableName = "patients";
        StringBuilder query = new StringBuilder("UPDATE ");
        query.append(tableName).append(" SET ");
        query.append("patient_code = ?");
        query.append(" WHERE patient_email = ?");
        System.out.println("SQL Query: " + query.toString());
        System.out.println("patient_code: " + patientCode);
        System.out.println("patient_email: " + patientEmail);
        return query;
    }

    public void resetPassword(String patientEmail, String patientCode, String newPassword) throws SQLException {
        String query = "UPDATE patients SET patient_password = ?, patient_code = NULL WHERE patient_email = ? AND patient_code = ?";
        System.out.println(query);
        try (Connection connection = openConnection();
             PreparedStatement preparedStatement = openPstm(query, connection)) {
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
             PreparedStatement stmt = openPstm(sql, connection)) {
            stmt.setString(1, feedback.getName());
            stmt.setString(2, feedback.getPhone());
            stmt.setString(3, feedback.getEmail());
            stmt.setString(4, feedback.getSubject());
            stmt.setString(5, feedback.getMessage());
            stmt.setTimestamp(6, Timestamp.valueOf(feedback.getCreated_at()));
            stmt.executeUpdate();
        }
    }



    // Phương thức tìm kiếm cho Doctors

    public List<Doctors> searchDoctorsByKeyword(String keyword) throws SQLException, IllegalAccessException, InvocationTargetException, InstantiationException, NoSuchMethodException {
        List<Doctors> entities = new ArrayList<>();
        String query = buildSearchQueryDoctor(Doctors.class, keyword);
        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query, connection)) {
            pstm.setString(1, "%" + keyword + "%");
            pstm.setString(2, "%" + keyword + "%");
            try (ResultSet rs = pstm.executeQuery()) {
                while (rs.next()) {
                    Doctors entity = createEntityFromResultSetForSearch(rs, Doctors.class);
                    entities.add(entity);
                }
            }
        }
        return entities;
    }

    public List<Patients> searchPatientsByKeyword(String keyword) throws SQLException, IllegalAccessException, InvocationTargetException, InstantiationException, NoSuchMethodException {
        List<Patients> entities = new ArrayList<>();
        String query = buildSearchQueryPatient(Patients.class, keyword);
        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query, connection)) {
            pstm.setString(1, "%" + keyword + "%");
            pstm.setString(2, "%" + keyword + "%");
            try (ResultSet rs = pstm.executeQuery()) {
                while (rs.next()) {
                    Patients entity = createEntityFromResultSetForSearch(rs, Patients.class);
                    System.out.println(entity.toString());
                    entities.add(entity);
                }
            }
        }
        System.out.println(query);
        return entities;
    }

    public List<Staffs> searchStaffsByKeyword(String keyword) throws SQLException, IllegalAccessException, InvocationTargetException, InstantiationException, NoSuchMethodException {
        List<Staffs> entities = new ArrayList<>();
        String query = buildSearchQueryStaff(Staffs.class, keyword);
        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query, connection)) {
            pstm.setString(1, "%" + keyword + "%");
            pstm.setString(2, "%" + keyword + "%");
            try (ResultSet rs = pstm.executeQuery()) {
                while (rs.next()) {
                    Staffs entity = createEntityFromResultSetForSearch(rs, Staffs.class);
                    entities.add(entity);
                }
            }
        }
        return entities;
    }

    private String buildSearchQueryPatient(Class<?> entityClass, String keyword) {
        StringBuilder query = new StringBuilder("SELECT * FROM ");
        query.append(getTableNameForSearch(entityClass)).append(" WHERE patient_name LIKE ? OR patient_email LIKE ?");
        return query.toString();
    }

    private String buildSearchQueryStaff(Class<?> entityClass, String keyword) {
        StringBuilder query = new StringBuilder("SELECT * FROM ");
        query.append(getTableNameForSearch(entityClass)).append(" WHERE staff_name LIKE ? OR staff_email LIKE ?");
        return query.toString();
    }

    private String buildSearchQueryDoctor(Class<?> entityClass, String keyword) {
        StringBuilder query = new StringBuilder("SELECT * FROM ");
        query.append(getTableNameForSearch(entityClass)).append(" WHERE doctor_name LIKE ? OR doctor_email LIKE ?");
        return query.toString();
    }

    private <T extends Entity<?>> T createEntityFromResultSetForSearch(ResultSet rs, Class<T> entityClass) throws SQLException, NoSuchMethodException, InvocationTargetException, InstantiationException, IllegalAccessException {
        T entity = entityClass.getDeclaredConstructor().newInstance();
        ResultSetMetaData metaData = rs.getMetaData();
        int columnCount = metaData.getColumnCount();
        for (int i = 1; i <= columnCount; i++) {
            String columnName = metaData.getColumnName(i);
            Field field = null;
            try {
                field = entityClass.getDeclaredField(columnName);
            } catch (NoSuchFieldException e) {
                continue;
            }
            field.setAccessible(true);
            Object value = rs.getObject(columnName);
            if (value != null) {
                if (field.getType().equals(LocalDateTime.class) && value instanceof Timestamp) {
                    field.set(entity, ((Timestamp) value).toLocalDateTime());
                } else {
                    field.set(entity, value);
                }
            }
        }
        return entity;
    }

    private String getTableNameForSearch(Class<?> entityClass) {
        return entityClass.getSimpleName().toLowerCase();
    }



    public List<Appointments> searchAppointmentsByCriteria(String startDate, String endDate, String status) throws SQLException, IllegalAccessException, InvocationTargetException, InstantiationException, NoSuchMethodException {
        List<Appointments> appointmentsList = new ArrayList<>();
        StringBuilder query = new StringBuilder("SELECT * FROM appointments WHERE 1=1");

        if (startDate != null && !startDate.isEmpty()) {
            query.append(" AND medical_day >= '").append(startDate).append("'");
        }
        if (endDate != null && !endDate.isEmpty()) {
            query.append(" AND medical_day <= '").append(endDate).append("'");
        }

        if (status != null && !status.isEmpty()) {
            query.append(" AND status = '").append(status).append("'");
        }

        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query.toString(), connection);
             ResultSet rs = exQuery(pstm)) {
            while (rs.next()) {
                Appointments appointment = createAppointmentFromResultSet(rs);
                appointmentsList.add(appointment);
            }
        }

        return appointmentsList;
    }

    // Các phương thức khác...

    private Appointments createAppointmentFromResultSet(ResultSet rs) throws SQLException, IllegalAccessException {
        Appointments appointment = new Appointments();
        ResultSetMetaData metaData = rs.getMetaData();
        int columnCount = metaData.getColumnCount();

        for (int i = 1; i <= columnCount; i++) {
            String columnName = metaData.getColumnName(i);
            Field field;
            try {
                field = Appointments.class.getDeclaredField(columnName);
            } catch (NoSuchFieldException e) {
                continue;
            }
            field.setAccessible(true);
            Object value = rs.getObject(columnName);
            if (value != null) {
                if (field.getType().equals(LocalDateTime.class) && value instanceof Timestamp) {
                    field.set(appointment, ((Timestamp) value).toLocalDateTime());
                } else {
                    field.set(appointment, value);
                }
            }
        }
        return appointment;
    }
    public List<Appointments> searchAppointmentsByCriteriaAndDoctor(String startDate, String endDate, String status, int doctorId) throws SQLException, IllegalAccessException, InvocationTargetException, InstantiationException, NoSuchMethodException {
        List<Appointments> appointmentsList = new ArrayList<>();
        StringBuilder query = new StringBuilder("SELECT * FROM appointments WHERE doctor_id = ?");

        if (startDate != null && !startDate.isEmpty()) {
            query.append(" AND medical_day >= ?");
        }
        if (endDate != null && !endDate.isEmpty()) {
            query.append(" AND medical_day <= ?");
        }
        if (status != null && !status.isEmpty()) {
            query.append(" AND status = ?");
        }

        try (Connection connection = openConnection();
             PreparedStatement pstm = openPstm(query.toString(), connection)) {
            int paramIndex = 1;
            pstm.setInt(paramIndex++, doctorId);

            if (startDate != null && !startDate.isEmpty()) {
                pstm.setString(paramIndex++, startDate);
            }
            if (endDate != null && !endDate.isEmpty()) {
                pstm.setString(paramIndex++, endDate);
            }
            if (status != null && !status.isEmpty()) {
                pstm.setString(paramIndex++, status);
            }

            try (ResultSet rs = exQuery(pstm)) {
                while (rs.next()) {
                    Appointments appointment = createAppointmentFromResultSet(rs);
                    appointmentsList.add(appointment);
                }
            }
        }

        return appointmentsList;
    }

}
