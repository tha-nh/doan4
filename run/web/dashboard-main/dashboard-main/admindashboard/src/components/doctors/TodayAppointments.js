
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Sidebar from './Sidebar';
import './TodayAppointments.css';
import $ from 'jquery';

const TodayAppointments = () => {
    const [todayAppointments, setTodayAppointments] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');
    const [newStatus, setNewStatus] = useState('');
    const [newAppointment, setNewAppointment] = useState('');
    const [selectedAppointment, setSelectedAppointment] = useState(null);
    const [openAddMedicalRecordDialog, setOpenAddMedicalRecordDialog] = useState(false);
    const [openMedicalRecordsDialog, setOpenMedicalRecordsDialog] = useState(false);
    const [openNewAppointmentDialog, setOpenNewAppointmentDialog] = useState(false);
    const [patientMedicalRecords, setPatientMedicalRecords] = useState([]);
    const [patientName, setPatientName] = useState('');
    const [patientEmail, setPatientEmail] = useState('');
    const [successMessage, setSuccessMessage] = useState('');
    const [newMedicalRecord, setNewMedicalRecord] = useState({
        symptoms: '',
        diagnosis: '',
        test_results: '',
        prescription: '',
        notes: '',
        image: ''
    });
    const [currentStep, setCurrentStep] = useState(1);

    const timeSlots = [
        { label: '08:00 AM - 09:00 AM', value: 1, start: '08:00', end: '09:00' },
        { label: '09:00 AM - 10:00 AM', value: 2, start: '09:00', end: '10:00' },
        { label: '10:00 AM - 11:00 AM', value: 3, start: '10:00', end: '11:00' },
        { label: '11:00 AM - 12:00 PM', value: 4, start: '11:00', end: '12:00' },
        { label: '01:00 PM - 02:00 PM', value: 5, start: '13:00', end: '14:00' },
        { label: '02:00 PM - 03:00 PM', value: 6, start: '14:00', end: '15:00' },
        { label: '03:00 PM - 04:00 PM', value: 7, start: '15:00', end: '16:00' },
        { label: '04:00 PM - 05:00 PM', value: 8, start: '16:00', end: '17:00' }
    ];

    const navigate = useNavigate();

    useEffect(() => {
        const storedDoctorId = localStorage.getItem('doctor_id');
        if (storedDoctorId) {
            const today = new Date().toISOString().split('T')[0];
            axios.get('http://localhost:8081/api/v1/appointments/search', {
                params: {
                    medical_day: today,
                    doctor_id: storedDoctorId
                }
            })
                .then(response => {
                    setTodayAppointments(response.data);
                })
                .catch(error => {
                    console.error('Lỗi khi lấy lịch khám hôm nay', error);
                });
        }
    }, []);

    const handleNewStatusChange = (e) => {
        setNewStatus(e.target.value);
    };

    const handleUpdateStatus = (appointmentId) => {
        axios.put('http://localhost:8081/api/v1/appointments/updateStatus', {
            appointment_id: appointmentId,
            status: newStatus,
            doctor_id: localStorage.getItem('doctor_id')
        })
            .then(response => {
                console.log('Cập nhật trạng thái thành công:', response.data);
                setNewStatus('');
                setSelectedAppointment(null);
                const today = new Date().toISOString().split('T')[0];
                axios.get('http://localhost:8081/api/v1/appointments/search', {
                    params: {
                        medical_day: today,
                        doctor_id: localStorage.getItem('doctor_id')
                    }
                })
                    .then(response => {
                        setTodayAppointments(response.data);
                    })
                    .catch(error => {
                        console.error('Lỗi khi lấy lịch khám hôm nay', error);
                    });
            })
            .catch(error => {
                console.error('Lỗi khi cập nhật trạng thái', error);
            });
    };

    const handleShowMedicalRecords = (patientId) => {
        axios.get('http://localhost:8081/api/v1/medicalrecords/search', {
            params: {
                patient_id: patientId
            }
        })
            .then(response => {
                setPatientMedicalRecords(response.data);
                axios.get('http://localhost:8081/api/v1/patients/' + patientId)
                    .then(res => {
                        setPatientName(res.data.patient_name);
                        setPatientEmail(res.data.patient_email);
                    })
                    .catch(err => {
                        console.error('Lỗi khi lấy thông tin bệnh nhân', err);
                    });
                setOpenMedicalRecordsDialog(true);
            })
            .catch(error => {
                console.error('Lỗi khi lấy bệnh án', error);
            });
    };

    const handleCloseMedicalRecordsDialog = () => {
        setOpenMedicalRecordsDialog(false);
        setPatientMedicalRecords([]);
        setPatientName('');
        setPatientEmail('');
    };

    const handleAddMedicalRecordOpen = (appointment) => {
        setSelectedAppointment(appointment);
        setCurrentStep(1);
        setOpenAddMedicalRecordDialog(true);
    };

    const handleAddMedicalRecordClose = () => {
        setOpenAddMedicalRecordDialog(false);
        setNewMedicalRecord({
            symptoms: '',
            diagnosis: '',
            test_results: '',
            prescription: '',
            notes: '',
            image: ''
        });
        setCurrentStep(1);
    };

    const handleNewMedicalRecordChange = (e) => {
        const { name, value } = e.target;
        setNewMedicalRecord((prevData) => ({
            ...prevData,
            [name]: value,
        }));
    };

    const handleNextStep = () => {
        setCurrentStep(prev => prev + 1);
    };

    const handlePrevStep = () => {
        setCurrentStep(prev => prev - 1);
    };

    const handleAddMedicalRecordSubmit = () => {
        if (!selectedAppointment) {
            console.error('No appointment selected');
            return;
        }

        const medicalRecordData = {
            ...newMedicalRecord,
            patient_id: selectedAppointment.patient_id,
            doctor_id: localStorage.getItem('doctor_id'),
            follow_up_date: new Date().toISOString().split('T')[0],
        };

        axios.post('http://localhost:8081/api/v1/medicalrecords/insert', medicalRecordData)
            .then(response => {
                console.log('Thêm bệnh án thành công:', response.data);
                setNewMedicalRecord({
                    symptoms: '',
                    diagnosis: '',
                    test_results: '',
                    prescription: '',
                    notes: '',
                    image: ''
                });
                setSuccessMessage('Add Medical Record Successfully!');
                setTimeout(() => setSuccessMessage(''), 2000);
                setOpenAddMedicalRecordDialog(false);
                setCurrentStep(1);
            })
            .catch(error => {
                console.error('Lỗi khi thêm bệnh án', error);
            });
    };

    const handleNewAppointmentOpen = (appointment) => {
        setSelectedAppointment(appointment);
        setNewAppointment((prevData) => ({
            ...prevData,
            patient_id: appointment.patient_id,
            patient_email: appointment.patient?.[0]?.patient_email || ''
        }));
        setOpenNewAppointmentDialog(true);
    };

    const handleNewAppointmentClose = () => {
        setOpenNewAppointmentDialog(false);
    };

    const handleNewAppointmentChange = (e) => {
        const { name, value } = e.target;
        setNewAppointment((prevData) => ({
            ...prevData,
            [name]: value,
        }));
    };

    const handleNewAppointmentSubmit = () => {
        const appointmentData = {
            ...newAppointment,
            price: 19.99,
            appointment_date: new Date().toISOString()
        };

        axios.post('http://localhost:8081/api/v1/appointments/insert', appointmentData)
            .then(response => {
                console.log('Thêm lịch khám thành công:', response.data);
                setNewAppointment({
                    patient_id: '',
                    doctor_id: localStorage.getItem('doctor_id'),
                    medical_day: '',
                    timeSlot: '',
                    status: 'Pending',
                    patient_email: ''
                });
                setSuccessMessage('Add Appointment Successfully!');
                setTimeout(() => setSuccessMessage(''), 2000);
                setOpenNewAppointmentDialog(false);
            })
            .catch(error => {
                console.error('Lỗi khi thêm lịch khám', error);
            });
    };

    const filteredTodayAppointments = todayAppointments.filter(appointment =>
        appointment.patient?.[0]?.patient_name.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const getTimeSlotLabel = (slotValue) => {
        const slot = timeSlots.find(s => s.value === slotValue);
        return slot ? slot.label : '';
    };

    const handleOpenTodayAppointments = () => {
        navigate('/todayappointments');
    };

    const handleOpenMonthlyAppointments = () => {
        navigate('/monthlyappointments');
    };

    const handleOpenMedicalRecords = () => {
        navigate('/medicalrecords');
    };

    const viewRecordDetails = (record) => {
        navigate('/record-details', { state: { record } });
    };

    return (
        <div className="today-appointments">
            <Sidebar
                handleOpenTodayAppointments={handleOpenTodayAppointments}
                handleOpenMonthlyAppointments={handleOpenMonthlyAppointments}
                handleOpenMedicalRecords={handleOpenMedicalRecords}
            />
            <div className="content">
                {successMessage && (
                    <div className="success-message">
                        {successMessage}
                    </div>
                )}
                <h3 className="tab-title">Today's Appointments Schedule</h3>
                <input
                    type="text"
                    placeholder="Search by patient name"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="search-input"
                />
                <ul className="appointments-list">
                    {filteredTodayAppointments.map((appointment, index) => (
                        <li key={index}>
                            <div>
                                <p>Patient Name: {appointment.patient?.[0]?.patient_name || 'N/A'}</p>
                                <p>Date: {new Date(appointment.medical_day).toLocaleDateString()}</p>
                                <p>Time: {getTimeSlotLabel(appointment.slot)}</p>
                                <p>Status: {appointment.status}</p>
                            </div>
                            {appointment.status !== 'Completed' && (
                                <div>
                                    <select value={newStatus} onChange={handleNewStatusChange}>
                                        <option value="">None</option>
                                        <option value="Cancelled">Cancelled</option>
                                        <option value="Completed">Completed</option>
                                    </select>
                                    <button onClick={() => handleUpdateStatus(appointment.appointment_id)}>Update Status</button>
                                    <button onClick={() => handleAddMedicalRecordOpen(appointment)}>Add medical record</button>
                                    <button onClick={() => handleShowMedicalRecords(appointment.patient?.[0]?.patient_id)}>Show medical records</button>
                                </div>
                            )}
                            {appointment.status === 'Completed' && (
                                <div>
                                    <button onClick={() => handleNewAppointmentOpen(appointment)}>Create new appointment</button>
                                    <button onClick={() => handleAddMedicalRecordOpen(appointment)}>Add medical record</button>
                                </div>
                            )}
                        </li>
                    ))}
                </ul>
                {openAddMedicalRecordDialog && (
                    <div className="dialog">
                        <div className="dialog-title">
                            Add more sections for patients
                            <div>Patient Name: {selectedAppointment ? selectedAppointment.patient?.[0]?.patient_name : 'Unknown Patient'}</div>
                        </div>
                        <div className="dialog-content">
                            {currentStep === 1 && (
                                <div>
                                    <label>Please enter patient's symptoms</label>
                                    <textarea
                                        name="symptoms"
                                        placeholder="Enter patient's symptoms here"
                                        value={newMedicalRecord.symptoms}
                                        onChange={handleNewMedicalRecordChange}
                                    />
                                </div>
                            )}
                            {currentStep === 2 && (
                                <div>
                                    <label>Enter doctor's diagnosis</label>
                                    <textarea
                                        name="diagnosis"
                                        placeholder="Enter diagnosis"
                                        value={newMedicalRecord.diagnosis}
                                        onChange={handleNewMedicalRecordChange}
                                    />
                                    <label>Upload image from file</label>
                                    <input
                                        type="file"
                                        name="imageFile"
                                        accept="image/*"
                                        onChange={(e) => {
                                            const file = e.target.files[0];
                                            if (file) {
                                                const reader = new FileReader();
                                                reader.onload = () => {
                                                    handleNewMedicalRecordChange({
                                                        target: { name: 'image', value: reader.result }
                                                    });
                                                };
                                                reader.readAsDataURL(file);
                                            }
                                        }}
                                    />
                                    {newMedicalRecord.image && (
                                        <div style={{ marginTop: '10px' }}>
                                            <img
                                                src={newMedicalRecord.image}
                                                alt="Medical record image"
                                                style={{ maxWidth: '100%', maxHeight: '200px', objectFit: 'contain', border: '1px solid #000' }}
                                                onError={(e) => (e.target.style.display = 'none')}
                                            />
                                        </div>
                                    )}
                                </div>
                            )}
                            {currentStep === 3 && (
                                <div>
                                    <label>Test Results</label>
                                    <textarea
                                        name="test_results"
                                        placeholder="Enter test results"
                                        value={newMedicalRecord.test_results}
                                        onChange={handleNewMedicalRecordChange}
                                    />
                                </div>
                            )}
                            {currentStep === 4 && (
                                <div>
                                    <label>Prescription</label>
                                    <textarea
                                        name="prescription"
                                        placeholder="Enter prescription"
                                        value={newMedicalRecord.prescription}
                                        onChange={handleNewMedicalRecordChange}
                                    />
                                </div>
                            )}
                            {currentStep === 5 && (
                                <div>
                                    <label>Notes</label>
                                    <textarea
                                        name="notes"
                                        placeholder="Enter notes"
                                        value={newMedicalRecord.notes}
                                        onChange={handleNewMedicalRecordChange}
                                    />
                                </div>
                            )}
                            {currentStep === 6 && (
                                <div>
                                    <h4>Review Medical Record</h4>
                                    {newMedicalRecord.image && (
                                        <div style={{ marginTop: '10px' }}>
                                            <img
                                                src={newMedicalRecord.image}
                                                alt="Medical record image"
                                                style={{ maxWidth: '100%', maxHeight: '200px', objectFit: 'contain', border: '1px solid #000' }}
                                                onError={(e) => (e.target.style.display = 'none')}
                                            />
                                        </div>
                                    )}
                                    <p><strong>Symptoms:</strong> {newMedicalRecord.symptoms || 'Not provided'}</p>
                                    <p><strong>Diagnosis:</strong> {newMedicalRecord.diagnosis || 'Not provided'}</p>
                                    <p><strong>Test Results:</strong> {newMedicalRecord.test_results || 'Not provided'}</p>
                                    <p><strong>Prescription:</strong> {newMedicalRecord.prescription || 'Not provided'}</p>
                                    <p><strong>Notes:</strong> {newMedicalRecord.notes || 'Not provided'}</p>
                                </div>
                            )}
                        </div>
                        <div className="dialog-actions">
                            <button onClick={handleAddMedicalRecordClose} className="btn btn-danger">Cancel</button>
                            {currentStep > 1 && (
                                <button onClick={handlePrevStep} className="btn btn-secondary">Previous</button>
                            )}
                            {currentStep === 1 && newMedicalRecord.symptoms && (
                                <button onClick={handleNextStep} className="btn btn-primary">Next</button>
                            )}
                            {currentStep === 2 && newMedicalRecord.diagnosis && (
                                <button onClick={handleNextStep} className="btn btn-primary">Next</button>
                            )}
                            {currentStep === 3 && newMedicalRecord.test_results && (
                                <button onClick={handleNextStep} className="btn btn-primary">Next</button>
                            )}
                            {currentStep === 4 && newMedicalRecord.prescription && (
                                <button onClick={handleNextStep} className="btn btn-primary">Next</button>
                            )}
                            {currentStep === 5 && newMedicalRecord.notes && (
                                <button onClick={handleNextStep} className="btn btn-primary">Next</button>
                            )}
                            {currentStep === 6 && (
                                <button onClick={handleAddMedicalRecordSubmit} className="btn btn-primary">Add</button>
                            )}
                        </div>
                    </div>
                )}
                {openNewAppointmentDialog && (
                    <div className="dialog">
                        <div className="dialog-title">Create New Appointment</div>
                        <div className="dialog-content">
                            <input
                                type="date"
                                name="medical_day"
                                placeholder="Medical Day"
                                value={newAppointment.medical_day}
                                onChange={handleNewAppointmentChange}
                            />
                            <select
                                name="timeSlot"
                                value={newAppointment.timeSlot}
                                onChange={handleNewAppointmentChange}
                            >
                                <option value="">Select Time Slot</option>
                                {timeSlots.map(slot => (
                                    <option key={slot.value} value={slot.value}>
                                        {slot.label}
                                    </option>
                                ))}
                            </select>
                        </div>
                        <div className="dialog-actions">
                            <button onClick={handleNewAppointmentClose} className="btn btn-danger">Cancel</button>
                            <button onClick={handleNewAppointmentSubmit} className="btn btn-primary">Create</button>
                        </div>
                    </div>
                )}
                {openMedicalRecordsDialog && (
                    <div className="dialog-records">
                        <div className="dialog-title">Medical Records</div>
                        <div className="dialog-content">
                            <ul className="medical-records-list">
                                {patientMedicalRecords.map((record, index) => (
                                    <li key={index}>
                                        <p>Medical Record ID: {record.record_id}</p>
                                        <div className="medical-record-details">
                                            <p><strong>Symptoms:</strong> {record.symptoms || 'Not Available'}</p>
                                            <p><strong>Diagnosis:</strong> {record.diagnosis || 'Not Available'}</p>
                                            <p><strong>Test Results:</strong> {record.test_results || 'Not Available'}</p>
                                            <p><strong>Prescription:</strong> {record.prescription || 'Not Available'}</p>
                                            <p><strong>Notes:</strong> {record.notes || 'Not Available'}</p>
                                            <p><strong>Image URL:</strong> {record.image || 'Not Available'}</p>
                                            <p><strong>Date:</strong> {record.follow_up_date || 'Not Available'}</p>
                                            <button onClick={() => viewRecordDetails(record)}>View Details</button>
                                        </div>
                                    </li>
                                ))}
                            </ul>
                        </div>
                        <div className="dialog-actions">
                            <button onClick={handleCloseMedicalRecordsDialog} className="btn btn-danger">Close</button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default TodayAppointments;
