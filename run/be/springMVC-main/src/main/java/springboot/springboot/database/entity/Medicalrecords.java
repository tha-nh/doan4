package springboot.springboot.database.entity;

import java.math.BigDecimal;
import java.util.Date;
import java.util.List;

public class Medicalrecords extends Entity<Integer> {
    private Integer record_id;
    private Integer patient_id;
    private String symptoms;
    private String diagnosis;
    private String treatment;
    private String prescription;
    private Date follow_up_date;
    private Integer doctor_id;

    private List<Patients> patients;
    private List<Doctors> doctors;
    private BigDecimal severity;
    private String image;
    public Medicalrecords() {
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }

    public BigDecimal getSeverity() {
        return severity;
    }

    public void setSeverity(BigDecimal severity) {
        this.severity = severity;
    }

    public Integer getRecord_id() {
        return record_id;
    }

    public void setRecord_id(Integer record_id) {
        this.record_id = record_id;
    }

    public Integer getPatient_id() {
        return patient_id;
    }

    public void setPatient_id(Integer patient_id) {
        this.patient_id = patient_id;
    }

    public String getSymptoms() {
        return symptoms;
    }

    public void setSymptoms(String symptoms) {
        this.symptoms = symptoms;
    }

    public String getDiagnosis() {
        return diagnosis;
    }

    public void setDiagnosis(String diagnosis) {
        this.diagnosis = diagnosis;
    }

    public String getTreatment() {
        return treatment;
    }

    public void setTreatment(String treatment) {
        this.treatment = treatment;
    }

    public String getPrescription() {
        return prescription;
    }

    public void setPrescription(String prescription) {
        this.prescription = prescription;
    }

    public Date getFollow_up_date() {
        return follow_up_date;
    }

    public void setFollow_up_date(Date follow_up_date) {
        this.follow_up_date = follow_up_date;
    }

    public Integer getDoctor_id() {
        return doctor_id;
    }

    public void setDoctor_id(Integer doctor_id) {
        this.doctor_id = doctor_id;
    }



    public List<Patients> getPatients() {
        return patients;
    }

    public void setPatients(List<Patients> patients) {
        this.patients = patients;
    }

    public List<Doctors> getDoctors() {
        return doctors;
    }

    public void setDoctors(List<Doctors> doctors) {
        this.doctors = doctors;
    }

    @Override
    public String toString() {
        return "Medicalrecords{" +
                "record_id=" + record_id +
                ", patient_id=" + patient_id +
                ", symptoms='" + symptoms + '\'' +
                ", diagnosis='" + diagnosis + '\'' +
                ", treatment='" + treatment + '\'' +
                ", prescription='" + prescription + '\'' +
                ", follow_up_date=" + follow_up_date +
                ", doctor_id=" + doctor_id +
                ", patients=" + patients +
                ", doctors=" + doctors +
                ", severity=" + severity +
                '}';
    }
}
