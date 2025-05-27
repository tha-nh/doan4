package springboot.springboot.database.model;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import springboot.springboot.database.entity.Entity;

import java.io.FileWriter;
import java.util.List;

public class EntityToJSON<T extends Entity<?>> {
    public void writeEmployeeToJson(List<T> entitties, Class entityClass, String method) throws Exception {
        Gson gson = new GsonBuilder().setPrettyPrinting().create();
        FileWriter writer = new FileWriter(method + entityClass.getClass().getSimpleName() + ".json");
        gson.toJson(entitties, writer);
        writer.close();
    }
}

