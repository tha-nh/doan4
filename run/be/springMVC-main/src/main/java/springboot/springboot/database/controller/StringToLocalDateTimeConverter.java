package springboot.springboot.database.controller;

import org.modelmapper.Converter;
import org.modelmapper.spi.MappingContext;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public class StringToLocalDateTimeConverter implements Converter<String, LocalDateTime> {
    @Override
    public LocalDateTime convert(MappingContext<String, LocalDateTime> context) {
        String dateString = context.getSource();
        if (dateString == null || dateString.trim().isEmpty()) {
            return null;
        }

        // Danh sách các định dạng ngày cần thử
        DateTimeFormatter[] formatters = {
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss"),
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"),
            DateTimeFormatter.ofPattern("yyyy-MM-dd")
        };

        for (DateTimeFormatter formatter : formatters) {
            try {
                // Nếu chỉ có ngày (yyyy-MM-dd), thêm thời gian 00:00:00
                if (dateString.matches("\\d{4}-\\d{2}-\\d{2}")) {
                    LocalDate localDate = LocalDate.parse(dateString, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
                    return localDate.atStartOfDay(); // Chuyển thành LocalDateTime với thời gian 00:00:00
                } else {
                    return LocalDateTime.parse(dateString, formatter);
                }
            } catch (DateTimeParseException e) {
                // Không làm gì, thử định dạng tiếp theo
            }
        }

        // Nếu không có định dạng nào thành công
        throw new IllegalArgumentException("Unparseable date: " + dateString);
    }
}