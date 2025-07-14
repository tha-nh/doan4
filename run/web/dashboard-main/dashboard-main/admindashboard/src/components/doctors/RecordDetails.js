import React, { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import "../doctors/RecordDetails.css";
import axios from "axios";
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

const RecordDetails = () => {
    const [patientData, setPatientData] = useState({});
    const [departmentData, setDepartmentData] = useState({});
    const [doctorData, setDoctorData] = useState({});
    const [loading, setLoading] = useState(true);
    const [selectedRecord, setSelectedRecord] = useState(null);
    const location = useLocation();
    const { records } = location.state || { records: [] };

    useEffect(() => {
        const scrollToTop = () => {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        };
        scrollToTop();
    }, []);

    useEffect(() => {
        const fetchPatientData = async () => {
            try {
                if (records.length > 0 && records[0].patient_id) {
                    const response = await axios.get(
                        `http://localhost:8081/api/v1/patients/search?patient_id=${records[0].patient_id}`
                    );
                    setPatientData(response.data[0] || {});
                }
            } catch (error) {
                console.error("Error fetching patient data", error);
            }
        };

        const fetchDoctorData = async () => {
            try {
                if (records.length > 0 && records[0].doctors && records[0].doctors.length > 0) {
                    const doc = records[0].doctors[0];
                    setDoctorData(doc);
                    if (doc.department_id) {
                        const response = await axios.get(
                            `http://localhost:8081/api/v1/departments/search?department_id=${doc.department_id}`
                        );
                        setDepartmentData(response.data[0] || {});
                    }
                }
            } catch (error) {
                console.error("Error fetching doctor data", error);
            } finally {
                setLoading(false);
            }
        };

        if (records.length > 0) {
            fetchPatientData();
            fetchDoctorData();
        } else {
            setLoading(false);
        }
    }, [records]);

    const calculateAge = (dob) => {
        if (!dob) return 'Not Available';
        const birthDate = new Date(dob);
        const today = new Date();
        let age = today.getFullYear() - birthDate.getFullYear();
        const monthDifference = today.getMonth() - birthDate.getMonth();
        if (monthDifference < 0 || (monthDifference === 0 && today.getDate() < birthDate.getDate())) {
            age--;
        }
        return `${age} years old`;
    };

    const formatDate = (dateString) => {
        if (!dateString) return 'Not Available';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    };

    const generatePDF = (record) => {
        const button = document.querySelector(`.download-pdf-button-${record.record_id}`);
        const originalDisplay = button.style.display;
        button.style.display = 'none';

        const input = document.getElementById(`record-form-${record.record_id}`);

        html2canvas(input, {
            scale: 2,
            useCORS: true,
            allowTaint: true,
            backgroundColor: '#ffffff'
        }).then((canvas) => {
            const imgData = canvas.toDataURL('image/png');
            const pdf = new jsPDF('p', 'mm', 'a4');
            const imgWidth = 210;
            const pageHeight = 295;
            const imgHeight = canvas.height * imgWidth / canvas.width;
            let heightLeft = imgHeight;
            let position = 0;

            pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
            heightLeft -= pageHeight;

            while (heightLeft >= 0) {
                position -= pageHeight;
                pdf.addPage();
                pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
                heightLeft -= pageHeight;
            }

            const fileName = `medical-record-${record.record_id}-${new Date().toISOString().split('T')[0]}.pdf`;
            pdf.save(fileName);

            button.style.display = originalDisplay;
        }).catch((error) => {
            console.error('Error generating PDF:', error);
            button.style.display = originalDisplay;
        });
    };

    const getGenderIcon = (gender) => {
        if (gender?.toLowerCase() === 'male') return '👨';
        if (gender?.toLowerCase() === 'female') return '👩';
        return '👤';
    };

    const handleRecordClick = (record) => {
        setSelectedRecord(record);
    };

    const closeModal = () => {
        setSelectedRecord(null);
    };

    if (loading) {
        return (
            <div className="content">
                <div className="record-details-container">
                    <div style={{ textAlign: 'center', padding: '50px' }}>
                        <div style={{ fontSize: '18px', color: '#666' }}>Loading record details...</div>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="content">
            <div className="record-details-container">
                <div className="record-header">
                    <h12 className="record-title">Medical Record Details</h12>
                    <span className="recordID">Patient Email: {patientData.patient_email || 'N/A'}</span>
                </div>

                <section className="section">
                    <h4>
                        <div className="section-icon">I</div>
                        Patient Information
                    </h4>
                    <div className="patient-info-grid">
                        <div className="patient-info-item">
                            <div className="patient-info-icon">👤</div>
                            <div className="patient-info-content">
                                <div className="patient-info-label">Full Name</div>
                                <div className="patient-info-value">
                                    {patientData.patient_name || 'Not Available'}
                                </div>
                            </div>
                        </div>
                        <div className="patient-info-item">
                            <div className="patient-info-icon">🎂</div>
                            <div className="patient-info-content">
                                <div className="patient-info-label">Date of Birth</div>
                                <div className="patient-info-value">
                                    {formatDate(patientData.patient_dob)}
                                </div>
                            </div>
                        </div>
                        <div className="patient-info-item">
                            <div className="patient-info-icon">{getGenderIcon(patientData.patient_gender)}</div>
                            <div className="patient-info-content">
                                <div className="patient-info-label">Gender</div>
                                <div className="patient-info-value">
                                    {patientData.patient_gender || 'Not Available'}
                                </div>
                            </div>
                        </div>
                        <div className="patient-info-item">
                            <div className="patient-info-icon">🏠</div>
                            <div className="patient-info-content">
                                <div className="patient-info-label">Address</div>
                                <div className="patient-info-value">
                                    {patientData.patient_address || 'Not Available'}
                                </div>
                            </div>
                        </div>
                        <div className="patient-info-item">
                            <div className="patient-info-icon">📧</div>
                            <div className="patient-info-content">
                                <div className="patient-info-label">Email</div>
                                <div className="patient-info-value">
                                    {patientData.patient_email || 'Not Available'}
                                </div>
                            </div>
                        </div>
                        <div className="patient-info-item">
                            <div className="patient-info-icon">📅</div>
                            <div className="patient-info-content">
                                <div className="patient-info-label">Age</div>
                                <div className="patient-info-value">
                                    {calculateAge(patientData.patient_dob)}
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                <section>
                    <h4>
                        <div className="section-icon">II</div>
                        Medical Records List
                    </h4>
                    <div className="records-list">
                        {records.length === 0 ? (
                            <p style={{ textAlign: 'center', fontSize: '18px', color: '#666' }}>
                                No record details available
                            </p>
                        ) : (
                            records.map((record) => (
                                <div
                                    key={record.record_id}
                                    className="record-list-item"
                                    onClick={() => handleRecordClick(record)}
                                >
                                    <div className="record-list-id">MR-{String(record.record_id).padStart(4, '0')}</div>
                                    <div className="record-list-date">{formatDate(record.follow_up_date)}</div>
                                    <div className="record-list-department">
                                        {departmentData.department_name || 'Not Available'}
                                    </div>
                                    <div className="record-list-doctor">
                                        {doctorData.doctor_name || 'Not Available'}
                                    </div>
                                    <div className="record-list-status">
                                        <span className="status-badge">Active</span>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </section>

                {selectedRecord && (
                    <div className="modal-overlay">
                        <div className="modal-content">
                            <button className="modal-close-button" onClick={closeModal}>
                                ✕
                            </button>
                            <form id={`record-form-${selectedRecord.record_id}`} className="record-form">
                                <h5>Record ID: MR-{String(selectedRecord.record_id).padStart(4, '0')}</h5>
                                <div className="diagnosis-grid">
                                    <div className="diagnosis-item">
                                        <p><strong>Record Date:</strong> {formatDate(selectedRecord.follow_up_date)}</p>
                                    </div>
                                    <div className="diagnosis-item">
                                        <p><strong>Department:</strong> {departmentData.department_name || 'Not Available'}</p>
                                    </div>
                                    <div className="diagnosis-item">
                                        <p><strong>Attending Physician:</strong> {doctorData.doctor_name || 'Not Available'}</p>
                                    </div>
                                    <div className="diagnosis-item">
                                        <p><strong>Status:</strong> <span className="status-badge">Active</span></p>
                                    </div>
                                </div>

                                <div style={{ marginTop: '20px' }}>
                                    <p><strong>Chief Complaint & Symptoms:</strong></p>
                                    <div className="notes-container">
                                        {selectedRecord.symptoms || 'No symptoms recorded'}
                                    </div>

                                    <p><strong>Primary Diagnosis:</strong></p>
                                    <div className="notes-container">
                                        {selectedRecord.diagnosis || 'No diagnosis recorded'}
                                    </div>
                                </div>

                                {selectedRecord.image && (
                                    <div className="medical-image-container">
                                        <h5 style={{ marginBottom: '15px', color: '#004b91' }}>Medical Imaging</h5>
                                        <img
                                            src={selectedRecord.image}
                                            alt={`Medical record imaging ${selectedRecord.record_id}`}
                                            onError={(e) => {
                                                e.target.style.display = 'none';
                                                e.target.nextSibling.style.display = 'block';
                                            }}
                                        />
                                        <div style={{ display: 'none', color: '#666', fontStyle: 'italic' }}>
                                            Medical image could not be loaded
                                        </div>
                                    </div>
                                )}

                                <div style={{ marginTop: '20px' }}>
                                    <p><strong>Prescribed Medications:</strong></p>
                                    <div className="notes-container">
                                        {selectedRecord.prescription || 'No prescription recorded'}
                                    </div>

                                    <p><strong>Treatment Plan & Prognosis:</strong></p>
                                    <div className="prognosis-container">
                                        {selectedRecord.treatment || 'No treatment plan recorded'}
                                    </div>
                                </div>

                                <button
                                    type="button"
                                    onClick={() => generatePDF(selectedRecord)}
                                    className={`download-pdf-button download-pdf-button-${selectedRecord.record_id}`}
                                >
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                                        <path d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z" />
                                    </svg>
                                    <span>Download Record {String(selectedRecord.record_id).padStart(4, '0')}</span>
                                </button>
                            </form>
                        </div>
                    </div>
                )}

                <div style={{ marginTop: '20px', padding: '15px', backgroundColor: '#f0f9ff', border: '1px solid #0ea5e9', borderRadius: '8px' }}>
                    <p style={{ margin: '0', fontSize: '14px', color: '#0369a1' }}>
                        <strong>Important:</strong> These medical records are confidential and should be handled according to HIPAA guidelines.
                        Please consult with your healthcare provider for any questions regarding this medical information.
                    </p>
                </div>
            </div>
        </div>
    );
};

export default RecordDetails;