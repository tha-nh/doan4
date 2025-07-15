import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { useParams, useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar';
import FeedbackListWithReply from './FeedbackListWithReply';
import './DoctorDetailPage.css';

const DoctorDetailPage = () => {
    const { doctorId } = useParams();
    const [doctor, setDoctor] = useState(null);
    const [todayAppointments, setTodayAppointments] = useState([]);
    const [monthlyAppointments, setMonthlyAppointments] = useState([]);
    const [isFeedbackModalOpen, setIsFeedbackModalOpen] = useState(false);
    const [loading, setLoading] = useState(true);
    const [departments, setDepartments] = useState([]);

    const [stats, setStats] = useState({
        totalToday: 0,
        totalMonthly: 0,
        completedToday: 0,
        pendingToday: 0
    });
    const navigate = useNavigate();

    useEffect(() => {
        fetchAllData();
    }, [doctorId]);

    const fetchAllData = async () => {
        setLoading(true);
        try {
            await Promise.all([
                fetchDoctorDetails(),
                fetchTodayAppointments(),
                fetchMonthlyAppointments(),
                fetchDepartments()
            ]);
        } catch (error) {
            console.error('Error fetching data:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchDepartments = async () => {
        try {
            const response = await axios.get('http://localhost:8081/api/v1/departments/list');
            setDepartments(response.data);
        } catch (error) {
            console.error('Error fetching departments', error);
        }
    };


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

            // Calculate today's stats
            const completed = response.data.filter(apt => apt.status === 'completed').length;
            const pending = response.data.filter(apt => apt.status === 'pending').length;

            setStats(prev => ({
                ...prev,
                totalToday: response.data.length,
                completedToday: completed,
                pendingToday: pending
            }));
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

            setStats(prev => ({
                ...prev,
                totalMonthly: response.data.length
            }));
        } catch (error) {
            console.error('Error fetching monthly appointments', error);
        }
    };

    const getDepartmentNameById = (id) => {
        const dept = departments.find(d => d.department_id === id);
        return dept ? dept.department_name : 'Unknown Department';
    };


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

    const getStatusClass = (status) => {
        switch (status?.toLowerCase()) {
            case 'confirmed':
                return 'status-v123 confirmed-v123';
            case 'pending':
                return 'status-v123 pending-v123';
            case 'cancelled':
                return 'status-v123 cancelled-v123';
            case 'completed':
                return 'status-v123 completed-v123';
            default:
                return 'status-v123';
        }
    };

    const formatDate = (dateString) => {
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });
    };

    const renderEmptyState = (message) => (
        <div className="empty-state-v123">
            <div className="empty-state-icon-v123">
                <svg fill="currentColor" viewBox="0 0 24 24">
                    <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/>
                </svg>
            </div>
            <div className="empty-state-text-v123">{message}</div>
        </div>
    );

    if (loading) {
        return (
            <div className="doctor-detail-page-v123">
                <Sidebar
                    onInboxClick={handleOpenFeedbackModal}
                    handleOpenDoctorsPage={() => navigate('/doctors')}
                    handleOpenPatientsPage={() => navigate('/patients')}
                    handleOpenAppointmentsPage={() => navigate('/appointments')}
                    handleOpenStaffPage={() => navigate('/staff')}
                />
                <div className="content-v123">
                    <div className="loading-spinner-v123">
                        <div className="spinner-v123"></div>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="doctor-detail-page-v123">
            <Sidebar
                onInboxClick={handleOpenFeedbackModal}
                handleOpenDoctorsPage={() => navigate('/doctors')}
                handleOpenPatientsPage={() => navigate('/patients')}
                handleOpenAppointmentsPage={() => navigate('/appointments')}
                handleOpenStaffPage={() => navigate('/staff')}
            />
            <div className="content-v123">
                <div className="header-v123">
                    <h22>Doctor Details</h22>
                    <button className="back-button-v123" onClick={handleBack}>
                        ← Back to Doctors List
                    </button>
                </div>

                {doctor && (
                    <div className="doctor-info-v123">
                        <div className="doctor-info-header-v123">

                                <img src={doctor.doctor_image}
                                     className="doctor-avatar-v123"
                                     alt="doctor"
                                />

                            <div className="doctor-name-section-v123">
                                <h5>{doctor.doctor_name}</h5>
                                <div
                                    className="doctor-specialty-v123">{getDepartmentNameById(doctor.department_id)}</div>

                            </div>
                        </div>
                        <div className="doctor-details-grid-v123">
                            <div className="detail-item-v123">
                                <div className="detail-icon-v123">
                                    <svg fill="currentColor" viewBox="0 0 24 24">
                                        <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
                                    </svg>
                                </div>
                                <div className="detail-content-v123">
                                    <div className="detail-label-v123">Email</div>
                                    <div className="detail-value-v123">{doctor.doctor_email}</div>
                                </div>
                            </div>
                            <div className="detail-item-v123">
                                <div className="detail-icon-v123">
                                    <svg fill="currentColor" viewBox="0 0 24 24">
                                        <path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/>
                                    </svg>
                                </div>
                                <div className="detail-content-v123">
                                    <div className="detail-label-v123">Phone</div>
                                    <div className="detail-value-v123">{doctor.doctor_phone}</div>
                                </div>
                            </div>
                            <div className="detail-item-v123">
                                <div className="detail-icon-v123">
                                    <svg fill="currentColor" viewBox="0 0 24 24">
                                        <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/>
                                    </svg>
                                </div>
                                <div className="detail-content-v123">
                                    <div className="detail-label-v123">Address</div>
                                    <div className="detail-value-v123">{doctor.doctor_address}</div>
                                </div>
                            </div>
                            <div className="detail-item-v123">
                                <div className="detail-icon-v123">
                                    <svg fill="currentColor" viewBox="0 0 24 24">
                                        <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                                    </svg>
                                </div>
                                <div className="detail-content-v123">
                                    <div className="detail-label-v123">Status</div>
                                    <div className="detail-value-v123">
                                        <span className={`working-status-v123 ${doctor.working_status === 'active' ? 'active-v123' : 'inactive-v123'}`}>
                                            {doctor.working_status === 'active' ? 'Active' : 'Inactive'}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )}

                <div className="stats-overview-v123">
                    <div className="stat-card-v123">
                        <div className="stat-value-v123">{stats.totalToday}</div>
                        <div className="stat-label-v123">Today's Appointments</div>
                    </div>
                    <div className="stat-card-v123">
                        <div className="stat-value-v123">{stats.completedToday}</div>
                        <div className="stat-label-v123">Completed</div>
                    </div>
                    <div className="stat-card-v123">
                        <div className="stat-value-v123">{stats.pendingToday}</div>
                        <div className="stat-label-v123">Pending</div>
                    </div>
                    <div className="stat-card-v123">
                        <div className="stat-value-v123">{stats.totalMonthly}</div>
                        <div className="stat-label-v123">Total This Month</div>
                    </div>
                </div>

                <div className="appointments-container-v123">
                    <div className="appointments-card-v123">
                        <div className="appointments-card-header-v123">
                            <h6>Today's Appointments</h6>
                            <div className="appointment-count-v123">{todayAppointments.length}</div>
                        </div>
                        <div className="table-container-v123">
                            {todayAppointments.length > 0 ? (
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
                                                <td>
                                                    <span className="time-slot-v123">
                                                        {getTimeFromSlot(appointment.slot)}
                                                    </span>
                                                </td>
                                                <td>
                                                    <span className="patient-name-v123">
                                                        {appointment.patient?.[0]?.patient_name || 'N/A'}
                                                    </span>
                                                </td>
                                                <td>
                                                    <span className={getStatusClass(appointment.status)}>
                                                        {appointment.status}
                                                    </span>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            ) : (
                                renderEmptyState('No appointments today')
                            )}
                        </div>
                    </div>

                    <div className="appointments-card-v123">
                        <div className="appointments-card-header-v123">
                            <h6>This Month's Appointments</h6>
                            <div className="appointment-count-v123">{monthlyAppointments.length}</div>
                        </div>
                        <div className="table-container-v123">
                            {monthlyAppointments.length > 0 ? (
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
                                                <td>{formatDate(appointment.medical_day)}</td>
                                                <td>
                                                    <span className="time-slot-v123">
                                                        {getTimeFromSlot(appointment.slot)}
                                                    </span>
                                                </td>
                                                <td>
                                                    <span className="patient-name-v123">
                                                        {appointment.patient?.[0]?.patient_name || 'N/A'}
                                                    </span>
                                                </td>
                                                <td>
                                                    <span className={getStatusClass(appointment.status)}>
                                                        {appointment.status}
                                                    </span>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            ) : (
                                renderEmptyState('No appointments this month')
                            )}
                        </div>
                    </div>
                </div>

                {isFeedbackModalOpen && (
                    <div className="feedback-modal-v123">
                        <FeedbackListWithReply onClose={handleCloseFeedbackModal} />
                    </div>
                )}
            </div>
        </div>
    );
};

export default DoctorDetailPage;