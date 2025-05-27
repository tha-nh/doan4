package springboot.springboot.database.entity;

public class FeedbackReplyDto extends Entity<Integer>{
    private String name;
    private String email;
    private String message;

    public FeedbackReplyDto() {
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
