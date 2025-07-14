import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useParams, useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar'; // Đảm bảo đường dẫn đúng đến component Sidebar
import FeedbackListWithReply from './FeedbackListWithReply'; // Import FeedbackListWithReply component
import './DoctorDetailPage.css'; // Đảm bảo đường dẫn đúng đến tệp CSS của bạn

const DoctorDetailPage = () => {
    const { doctorId } = useParams();
    const [doctor, setDoctor] = useState(null);
    const [todayAppointments, setTodayAppointments] = useState([]);
    const [monthlyAppointments, setMonthlyAppointments] = useState([]);
    const [isFeedbackModalOpen, setIsFeedbackModalOpen] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchDoctorDetails = async () => {
            try {
                const doctorResponse = await axios.get(`http://localhost:8081/api/v1/doctors/${doctorId}`);
                setDoctor(doctorResponse.data);
            } catch (error) {
                console.error('Error fetching doctor details', error);
            }
        };

        const fetchTodayAppointments = async () => {
            try {
                const today = new Date().toISOString().split('T')[0];
                const response = await axios.get(`http://localhost:8081/api/v1/appointments/search`, {
                    params: {
                        doctor_id: doctorId,
                        medical_day: today,
                    }
                });
                setTodayAppointments(response.data);
            } catch (error) {
                console.error("Error fetching today's appointments", error);
            }
        };

        const fetchMonthlyAppointments = async () => {
            try {
                const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0];
                const endOfMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).toISOString().split('T')[0];
                const response = await axios.get(`http://localhost:8081/api/v1/appointments/search`, {
                    params: {
                        doctor_id: doctorId,
                        start_date: startOfMonth,
                        end_date: endOfMonth,
                    }
                });
                setMonthlyAppointments(response.data);
            } catch (error) {
                console.error('Error fetching monthly appointments', error);
            }
        };

        fetchDoctorDetails();
        fetchTodayAppointments();
        fetchMonthlyAppointments();
    }, [doctorId]);

    const handleBack = () => {
        navigate('/doctors');
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
        <div className="doctor-detail-page">
            <Sidebar
                onInboxClick={handleOpenFeedbackModal}
                handleOpenDoctorsPage={() => navigate('/doctors')}
                handleOpenPatientsPage={() => navigate('/patients')}
                handleOpenAppointmentsPage={() => navigate('/appointments')}
                handleOpenStaffPage={() => navigate('/staff')}
            />
            <div className="content">
                <div className="header">
                    <h2>Doctor Details</h2>
                    <button className="back-button" onClick={handleBack}>Back to Doctors Page</button>
                </div>
                {doctor && (
                    <div className="doctor-info">
                        <h5>{doctor.doctor_name}</h5>
                        <p>Email: {doctor.doctor_email}</p>
                        <p>Phone: {doctor.doctor_phone}</p>
                        <p>Address: {doctor.doctor_address}</p>
                        <p>Working Status: {doctor.working_status}</p>
                    </div>
                )}
                <div className="appointments-container">
                    <div className="appointments-card">
                        <h6>Today's Appointments</h6>
                        <div className="table-container">
                            <table>
                                <thead>
                                <tr>
                                    <th>Time</th>
                                    <th>Patient</th>
                                    <th>Status</th>
                                </tr>
                                </thead>
                                <tbody>
                                {todayAppointments.map(appointment => (
                                    <tr key={appointment.appointment_id}>
                                        <td>{getTimeFromSlot(appointment.slot)}</td>
                                        <td>{appointment.patient?.[0]?.patient_name || 'N/A'}</td>
                                        <td>{appointment.status}</td>
                                    </tr>
                                ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div className="appointments-card">
                        <h6>Monthly Appointments</h6>
                        <div className="table-container">
                            <table>
                                <thead>
                                <tr>
                                    <th>Date</th>
                                    <th>Time</th>
                                    <th>Patient</th>
                                    <th>Status</th>
                                </tr>
                                </thead>
                                <tbody>
                                {monthlyAppointments.map(appointment => (
                                    <tr key={appointment.appointment_id}>
                                        <td>{new Date(appointment.medical_day).toLocaleDateString()}</td>
                                        <td>{getTimeFromSlot(appointment.slot)}</td>
                                        <td>{appointment.patient?.[0]?.patient_name || 'N/A'}</td>
                                        <td>{appointment.status}</td>
                                    </tr>
                                ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                {isFeedbackModalOpen && (
                    <div className="feedback-modal">
                        <FeedbackListWithReply onClose={handleCloseFeedbackModal} />
                    </div>
                )}
            </div>
        </div>
    );
};

export default DoctorDetailPage;
