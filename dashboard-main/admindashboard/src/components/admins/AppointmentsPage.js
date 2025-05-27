import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar';
import FeedbackListWithReply from './FeedbackListWithReply';
import './AppointmentsPage.css';

const AppointmentsPage = () => {
    const [appointments, setAppointments] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [status, setStatus] = useState('');
    const [isFeedbackModalOpen, setIsFeedbackModalOpen] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchAppointments = async () => {
            try {
                const response = await axios.get('http://localhost:8080/api/v1/appointments/list');
                const sortedData = response.data.sort((a, b) => new Date(b.medical_day) - new Date(a.medical_day));
                setAppointments(sortedData);
            } catch (error) {
                console.error('Error fetching appointments', error);
            }
        };
        fetchAppointments();
    }, []);

    const convertSlotToTime = (slot) => {
        const slotMapping = {
            1: '08:00 AM - 09:00 AM',
            2: '09:00 AM - 10:00 AM',
            3: '10:00 AM - 11:00 AM',
            4: '11:00 AM - 12:00 PM',
            5: '01:00 PM - 02:00 PM',
            6: '02:00 PM - 03:00 PM',
            7: '03:00 PM - 04:00 PM',
            8: '04:00 PM - 05:00 PM'
        };
        return slotMapping[slot] || 'N/A';
    };

    const handleBack = () => {
        navigate('/admindashboard');
    };

    const handleOpenFeedbackModal = () => {
        setIsFeedbackModalOpen(true);
    };

    const handleCloseFeedbackModal = () => {
        setIsFeedbackModalOpen(false);
    };

    const handleOpenDoctorsPage = () => {
        navigate('/doctors');
    };

    const handleOpenPatientsPage = () => {
        navigate('/patients');
    };

    const handleOpenAppointmentsPage = () => {
        navigate('/appointments');
    };

    const handleOpenStaffPage = () => {
        navigate('/staff');
    };

    const handleSearchChange = (e) => {
        setSearchQuery(e.target.value);
    };

    const handleStartDateChange = (e) => {
        setStartDate(e.target.value);
    };

    const handleEndDateChange = (e) => {
        setEndDate(e.target.value);
    };

    const handleStatusChange = (e) => {
        setStatus(e.target.value);
    };

    const handleSearch = async () => {
        try {
            const response = await axios.get('http://localhost:8080/api/v1/appointments/search-new', {
                params: {
                    start_date: startDate,
                    end_date: endDate,
                    status: status
                }
            });
            setAppointments(response.data);
        } catch (error) {
            console.error('Error searching appointments', error);
        }
    };

    const handleAppointmentClick = (appointmentId) => {
        navigate(`/appointments/${appointmentId}`);
    };

    return (
        <div className="appointments-page">
            <Sidebar
                onInboxClick={handleOpenFeedbackModal}
                handleOpenDoctorsPage={handleOpenDoctorsPage}
                handleOpenPatientsPage={handleOpenPatientsPage}
                handleOpenAppointmentsPage={handleOpenAppointmentsPage}
                handleOpenStaffPage={handleOpenStaffPage}
            />
            <div className="content">
                <div className="header">
                    <h2>Appointments List</h2>
                    <div className="search">
                        <div className="input-container">
                            <input
                                type="date"
                                placeholder="Start Date"
                                value={startDate}
                                onChange={handleStartDateChange}
                            />
                            <label>Start Date</label>
                        </div>
                        <div className="input-container">
                            <input
                                type="date"
                                placeholder="End Date"
                                value={endDate}
                                onChange={handleEndDateChange}
                            />
                            <label>End Date</label>
                        </div>
                        <div className="input-container">
                            <select value={status} onChange={handleStatusChange}>
                                <option value="Pending">Pending</option>
                                <option value="Completed">Completed</option>
                                <option value="Cancelled">Cancelled</option>
                            </select>
                            <label>Status</label>
                        </div>
                        <button onClick={handleSearch}>Search</button>
                    </div>
                </div>
                <div className="table-container">
                    <table>
                        <thead>
                        <tr>
                            <th>ID</th>
                            <th>Patient</th>
                            <th>Doctor</th>
                            <th>Date</th>
                            <th>Time</th>
                            <th>Status</th>
                            <th>Price</th>
                        </tr>
                        </thead>
                        <tbody>
                        {appointments.length > 0 ? (
                            appointments.map((appointment, index) => (
                                <tr key={index} onClick={() => handleAppointmentClick(appointment.appointment_id)}>
                                    <td>{appointment.appointment_id}</td>
                                    <td>{appointment.patient && appointment.patient[0] ? appointment.patient[0].patient_name : 'N/A'}</td>
                                    <td>{appointment.doctor && appointment.doctor[0] ? appointment.doctor[0].doctor_name : 'N/A'}</td>
                                    <td>{new Date(appointment.medical_day).toLocaleDateString()}</td>
                                    <td>{convertSlotToTime(appointment.slot)}</td>
                                    <td>{appointment.status}</td>
                                    <td>{appointment.price}</td>
                                </tr>
                            ))
                        ) : (
                            <tr>
                                <td colSpan={7} align="center">No appointments found</td>
                            </tr>
                        )}
                        </tbody>
                    </table>
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

export default AppointmentsPage;
