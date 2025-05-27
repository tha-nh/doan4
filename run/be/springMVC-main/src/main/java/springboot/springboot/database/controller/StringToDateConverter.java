package springboot.springboot.database.controller;

import org.modelmapper.Converter;
import org.modelmapper.spi.MappingContext;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

public class StringToDateConverter implements Converter<String, Date> {
    @Override
    public Date convert(MappingContext<String, Date> context) {
        String dateString = context.getSource();
        if (dateString == null) {
            return null;
        }

        // Danh sách các định dạng ngày cần thử
        String[] dateFormats = {
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd"
        };

        for (String dateFormat : dateFormats) {
            SimpleDateFormat sdf = new SimpleDateFormat(dateFormat);
            try {
                // Chuyển đổi chuỗi ngày tháng thành đối tượng Date
                return sdf.parse(dateString);
            } catch (ParseException e) {
                // Không làm gì, thử định dạng tiếp theo
            }
        }

        // Nếu không có định dạng nào thành công
        throw new IllegalArgumentException("Unparseable date: " + dateString);
    }
}
