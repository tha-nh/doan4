import React, {useEffect, useState} from 'react';
import axios from 'axios';
import {useParams, useNavigate} from 'react-router-dom';
import Sidebar from './Sidebar';
import FeedbackListWithReply from './FeedbackListWithReply';
import '../admins/AppointmentDetailPage.css';
import $ from 'jquery';

const AppointmentDetailPage = () => {
    const {appointmentId} = useParams();
    const [appointment, setAppointment] = useState(null);
    const [isFeedbackModalOpen, setIsFeedbackModalOpen] = useState(false);
    const navigate = useNavigate();
    const [departmentData, setDepartmentData] = useState({});


    useEffect(() => {
        const fetchAppointmentDetails = async () => {
            try {
                const response = await axios.get(`http://localhost:8081/api/v1/appointments/${appointmentId}`);
                setAppointment(response.data);
            } catch (error) {
                console.error('Error fetching appointment details', error);
            }
        };
        fetchAppointmentDetails();
    }, [appointmentId]);

    useEffect(() => {
        const fetchDoctorData = async () => {
            try {
                const fetchPromises = appointment.doctor.map(async (doc) => {
                    const response = await axios.get(`http://localhost:8081/api/v1/departments/search?department_id=${doc.department_id}`);
                    setDepartmentData(response.data[0] || {});
                });
                await Promise.all(fetchPromises);
            } catch (error) {
                console.error("Error fetching doctor data", error);
            }
        };

        fetchDoctorData();
    }, [appointment]);

    const handleBack = () => {
        navigate('/appointments');
    };

    const handleOpenFeedbackModal = () => {
        setIsFeedbackModalOpen(true);
    };

    const handleCloseFeedbackModal = () => {
        setIsFeedbackModalOpen(false);
    };

    const getTimeFromSlot = (slot) => {
        const slotToTime = {
            1: "08:00 - 09:00",
            2: "09:00 - 10:00",
            3: "10:00 - 11:00",
            4: "11:00 - 12:00",
            5: "13:00 - 14:00",
            6: "14:00 - 15:00",
            7: "15:00 - 16:00",
            8: "16:00 - 17:00"
        };
        return slotToTime[slot] || "Unknown Time";
    };

    return (
        <div className="appointment-detail-page">
            <Sidebar
                onInboxClick={handleOpenFeedbackModal}
                handleOpenDoctorsPage={() => navigate('/doctors')}
                handleOpenPatientsPage={() => navigate('/patients')}
                handleOpenAppointmentsPage={() => navigate('/appointments')}
                handleOpenStaffPage={() => navigate('/staff')}
            />
            <div className="content">
                <div className="header">
                    <h2>Appointment Details</h2>
                    <button className="back-button" onClick={handleBack}>Back to Appointments Page</button>
                </div>
                {appointment ? (
                    <div className="appointment-info">
                        <h3><strong>Appointment ID:</strong> {appointment.appointment_id}</h3>
                        <div>
                            <p><strong>Date:</strong> {new Date(appointment.medical_day).toLocaleDateString()}</p>
                            <p><strong>Time:</strong> {getTimeFromSlot(appointment.slot)}</p>
                            <p><strong>Status:</strong> {appointment.status}</p>
                            <p><strong>Price:</strong> {appointment.price}</p>
                        </div>
                        <div>
                            <p><strong>Department:</strong> {departmentData.department_name}</p>
                            <p><strong>Doctor:</strong> {appointment.doctor[0].doctor_name}</p>
                        </div>
                        <div>
                            <p><strong>Patient Name:</strong> {appointment.patient[0].patient_name}</p>
                            <p><strong>Email:</strong> {appointment.patient[0].patient_email}</p>
                            <p><strong>Phone:</strong> {appointment.patient[0].patient_phone}</p>
                            <p><strong>Address:</strong> {appointment.patient[0].patient_address}</p>
                        </div>
                    </div>
                ) : (
                    <p>Loading appointment details...</p>
                )}
                {isFeedbackModalOpen && (
                    <div className="feedback-modal">
                        <FeedbackListWithReply onClose={handleCloseFeedbackModal}/>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AppointmentDetailPage;
