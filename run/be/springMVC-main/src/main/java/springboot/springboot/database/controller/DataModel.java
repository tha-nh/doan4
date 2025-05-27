package springboot.springboot.database.controller;

import springboot.springboot.database.entity.Entity;

import java.lang.reflect.Field;
import java.util.List;
import java.util.Map;

public class DataModel<T extends Entity<?>> {


    public String type;
    public Map<String, String> data;
    public void processData(List<DataModel> dataList) {
        for (DataModel dataModel : dataList) {
            try {
                Class<?> clazz = Class.forName("path.to.your.package." + dataModel.type);
                Object obj = clazz.newInstance();

                Map<String, String> data = dataModel.data;
                for (Map.Entry<String, String> entry : data.entrySet()) {
                    try {
                        Field field = clazz.getDeclaredField(entry.getKey());
                        field.setAccessible(true);

                        if (field.getType() == Integer.class) {
                            field.set(obj, Integer.parseInt(entry.getValue()));
                        } else {
                            field.set(obj, entry.getValue());
                        }
                    } catch (NoSuchFieldException | IllegalAccessException e) {
                        e.printStackTrace();
                    }
                }

                System.out.println(obj.toString());
            } catch (ClassNotFoundException | InstantiationException | IllegalAccessException e) {
                e.printStackTrace();
            }
        }
    }


}