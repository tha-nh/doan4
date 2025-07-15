import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useParams, useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar';
import FeedbackListWithReply from './FeedbackListWithReply';
import './AppointmentDetailPage.css';

const AppointmentDetailPageC1 = () => {
    const { appointmentId } = useParams();
    const [appointment, setAppointment] = useState(null);
    const [isFeedbackModalOpen, setIsFeedbackModalOpen] = useState(false);
    const [departmentData, setDepartmentData] = useState({});
    const navigate = useNavigate();

    useEffect(() => {
        const fetchAppointmentDetails = async () => {
            try {
                const response = await axios.get(`http://localhost:8081/api/v1/appointments/${appointmentId}`);
                setAppointment(response.data);

                // Fetch department data for the first doctor
                if (response.data?.doctor?.[0]?.department_id) {
                    const deptResponse = await axios.get(`http://localhost:8081/api/v1/departments/search?department_id=${response.data.doctor[0].department_id}`);
                    setDepartmentData(deptResponse.data[0] || {});
                }
            } catch (error) {
                console.error('Error fetching appointment details', error);
            }
        };
        fetchAppointmentDetails();
    }, [appointmentId]);

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
        <div className="appointment-detail-pageC1">
            <Sidebar
                onInboxClick={handleOpenFeedbackModal}
                handleOpenDoctorsPage={() => navigate('/doctors')}
                handleOpenPatientsPage={() => navigate('/patients')}
                handleOpenAppointmentsPage={() => navigate('/appointments')}
                handleOpenStaffPage={() => navigate('/staff')}
                className="sidebarC1"
            />
            <div className="contentC1">
                <div className="headerC1">
                    <h2>Appointment Details</h2>
                    <button className="back-buttonC1" onClick={handleBack}>Back to Appointments</button>
                </div>
                {appointment ? (
                    <div className="appointment-infoC1">
                        <h3>Appointment ID: {appointment.appointment_id}</h3>
                        <div>
                            <p><strong>Date:</strong> {new Date(appointment.medical_day).toLocaleDateString()}</p>
                            <p><strong>Time:</strong> {getTimeFromSlot(appointment.slot)}</p>
                            <p><strong>Status:</strong> {appointment.status}</p>
                            <p><strong>Price:</strong> {appointment.price}</p>
                        </div>
                        <div>
                            <p><strong>Department:</strong> {departmentData.department_name || 'N/A'}</p>
                            <p><strong>Doctor:</strong> {appointment.doctor?.[0]?.doctor_name || 'N/A'}</p>
                        </div>
                        <div>
                            <p><strong>Patient Name:</strong> {appointment.patient?.[0]?.patient_name || 'N/A'}</p>
                            <p><strong>Email:</strong> {appointment.patient?.[0]?.patient_email || 'N/A'}</p>
                            <p><strong>Phone:</strong> {appointment.patient?.[0]?.patient_phone || 'N/A'}</p>
                            <p><strong>Address:</strong> {appointment.patient?.[0]?.patient_address || 'N/A'}</p>
                        </div>
                    </div>
                ) : (
                    <p>Loading appointment details...</p>
                )}
                {isFeedbackModalOpen && (
                    <div className="feedback-modalC1">
                        <div className="overlay-contentC1">
                            <button onClick={handleCloseFeedbackModal} className="close-buttonC1">×</button>
                            <FeedbackListWithReply onClose={handleCloseFeedbackModal} />
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AppointmentDetailPageC1;