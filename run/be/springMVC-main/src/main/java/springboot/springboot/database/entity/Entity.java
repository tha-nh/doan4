package springboot.springboot.database.entity;

public class Entity <T>{
    private T id;

    public Entity(T id) {
        this.id = id;
    }

    public Entity() {
    }

    public T getId() {
        return id;
    }

    public void setId(T id) {
        this.id = id;
    }
}
