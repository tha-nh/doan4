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

/* Đảm bảo các phần tử cha chiếm toàn bộ chiều cao và chiều rộng của màn hình */
html, body, #root {
height: 100%;
width: 100%;
margin: 0;
padding: 0;
display: flex;
font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

/* Container chính cho trang DoctorDetailPage */
.doctor-detail-page-v123 {
display: flex;
height: 100%;
width: 100%;
background-color: #f8f9fa;
}

/* Container cho nội dung chính */
.content-v123 {
padding: 30px;
flex-grow: 1;
overflow-y: auto;
display: flex;
flex-direction: column;
gap: 24px;
}

.header-v123 {
display: flex;
justify-content: space-between;
align-items: center;
background: #004B91;
color: white;
padding: 24px;
border-radius: 5px;
box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
margin-bottom: 8px;
}

.header-v123 h2 {
margin: 0;
font-size: 28px;
font-weight: 600;
text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.back-button-v123 {
padding: 12px 24px;
background-color: rgba(255, 255, 255, 0.2);
color: white;
border: 2px solid rgba(255, 255, 255, 0.3);
border-radius: 5px;
cursor: pointer;
font-weight: 500;
transition: all 0.3s ease;
backdrop-filter: blur(10px);
}

.back-button-v123:hover {
background-color: rgba(255, 255, 255, 0.3);
border-color: rgba(255, 255, 255, 0.5);

    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.doctor-info-v123 {
background: white;
border-radius: 5px;
padding: 50px;
box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
border: 1px solid #e9ecef;
position: relative;
overflow: hidden;
}

.doctor-info-v123::before {
content: '';
position: absolute;
top: 0;
left: 0;
right: 0;
height: 4px;
background: #004B91;
}

.doctor-info-header-v123 {
display: flex;
align-items: center;
gap: 20px;
margin-bottom: 24px;
margin-top: -34px;
}

.doctor-avatar-v123 {
width: 80px;
height: 80px;
border-radius: 50%;
background: #004B91;
display: flex;
align-items: center;
justify-content: center;
color: white;
font-size: 32px;
font-weight: bold;
box-shadow: 0 4px 16px rgba(0, 75, 145, 0.3);
}

.doctor-name-section-v123 h5 {
margin: 0 0 8px 0;
font-size: 24px;
font-weight: 600;
color: #2c3e50;
}

.doctor-specialty-v123 {
color: #004B91;
font-weight: 500;
font-size: 16px;
}

.doctor-details-grid-v123 {
display: grid;
grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
gap: 20px;
margin-top: 24px;
}

.detail-item-v123 {
display: flex;
align-items: center;
gap: 12px;
padding: 16px;
background: #f8f9fa;
border-radius: 5px;
border-left: 4px solid #004B91;
}

.detail-icon-v123 {
width: 24px;
height: 24px;
color: #004B91;
}

.detail-content-v123 {
flex: 1;
}

.detail-label-v123 {
font-size: 12px;
color: #6c757d;
text-transform: uppercase;
font-weight: 600;
margin-bottom: 4px;
}

.detail-value-v123 {
font-size: 14px;
color: #2c3e50;
font-weight: 500;
}

.working-status-v123 {
display: inline-block;
padding: 4px 12px;
border-radius: 5px;
font-size: 12px;
font-weight: 600;
text-transform: uppercase;
}

.working-status-v123.active-v123 {
background-color: #d4edda;
color: #155724;
border: 1px solid #c3e6cb;
}

.working-status-v123.inactive-v123 {
background-color: #f8d7da;
color: #721c24;
border: 1px solid #f5c6cb;
}

.appointments-container-v123 {
display: grid;
grid-template-columns: 1fr 1fr;
gap: 24px;
margin-bottom: 32px;
}

.appointments-card-v123 {
background: white;
border-radius: 5px;
box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
overflow: hidden;
border: 1px solid #e9ecef;
}

.appointments-card-header-v123 {
background: #004B91;
color: white;
padding: 20px 24px;
position: relative;
}

.appointments-card-header-v123 h6 {
margin: 0;
font-size: 18px;
font-weight: 600;
}

.appointment-count-v123 {
position: absolute;
top: 50%;
right: 24px;
transform: translateY(-50%);
background: rgba(255, 255, 255, 0.2);
padding: 8px 16px;
border-radius: 5px;
font-size: 14px;
font-weight: 600;
backdrop-filter: blur(10px);
}

.table-container-v123 {
max-height: 400px;
overflow-y: auto;
position: relative;
}

.table-container-v123::-webkit-scrollbar {
width: 6px;
}

.table-container-v123::-webkit-scrollbar-track {
background: #f1f1f1;
}

.table-container-v123::-webkit-scrollbar-thumb {
background: #c1c1c1;
border-radius: 3px;
}

.table-container-v123::-webkit-scrollbar-thumb:hover {
background: #a8a8a8;
}

table {
width: 100%;
border-collapse: collapse;
font-size: 14px;
}

.table-container-v123 table thead th {
position: sticky;
top: 0;
background: #004B91;
color: white;
padding: 16px 12px;
text-align: left;
z-index: 1;
font-weight: 600;
font-size: 13px;
text-transform: uppercase;
letter-spacing: 0.5px;
}

tbody tr {
transition: all 0.2s ease;
}

tbody tr:hover {
background-color: #f8f9ff;
transform: translateY(-1px);
}

tbody tr:nth-child(even) {
background-color: #fafafa;
}

tbody tr:nth-child(even):hover {
background-color: #f8f9ff;
}

td {
padding: 16px 12px;
text-align: left;
border-bottom: 1px solid #e9ecef;
vertical-align: middle;
}

.time-slot-v123 {
font-weight: 600;
color: #004B91;
background: #e8f0fe;
padding: 6px 12px;
border-radius: 5px;
display: inline-block;
font-size: 12px;
}

.patient-name-v123 {
font-weight: 500;
color: #2c3e50;
}

.status-v123 {
padding: 6px 12px;
border-radius: 5px;
font-size: 12px;
font-weight: 600;
text-transform: uppercase;
display: inline-block;
}

.status-v123.confirmed-v123 {
background-color: #d4edda;
color: #155724;
}

.status-v123.pending-v123 {
background-color: #fff3cd;
color: #856404;
}

.status-v123.cancelled-v123 {
background-color: #f8d7da;
color: #721c24;
}

.status-v123.completed-v123 {
background-color: #d1ecf1;
color: #0c5460;
}

.empty-state-v123 {
text-align: center;
padding: 40px 20px;
color: #6c757d;
}

.empty-state-icon-v123 {
width: 64px;
height: 64px;
margin: 0 auto 16px;
opacity: 0.3;
}

.empty-state-text-v123 {
font-size: 16px;
font-weight: 500;
}

.feedback-modal-v123 {
position: fixed;
top: 0;
left: 0;
right: 0;
bottom: 0;
background: rgba(0, 0, 0, 0.5);
display: flex;
align-items: center;
justify-content: center;
z-index: 1000;
backdrop-filter: blur(4px);
}

.stats-overview-v123 {
display: grid;
grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
gap: 16px;
margin-bottom: 24px;
}

.stat-card-v123 {
background: #004B91;
padding: 24px;
border-radius: 5px;
box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
text-align: center;
border: 1px solid #e9ecef;
}

.stat-value-v123 {
font-size: 32px;
font-weight: 700;
margin-bottom: 8px;
color: #ffffff;
}

.stat-label-v123 {
font-size: 14px;
color: #ffffff;
font-weight: 500;
text-transform: uppercase;
letter-spacing: 0.5px;
}

.loading-spinner-v123 {
display: flex;
justify-content: center;
align-items: center;
height: 200px;
}

.spinner-v123 {
width: 40px;
height: 40px;
border: 4px solid #f3f3f3;
border-top: 4px solid #004B91;
border-radius: 50%;
animation: spin-v123 1s linear infinite;
}

@keyframes spin-v123 {
0% { transform: rotate(0deg); }
100% { transform: rotate(360deg); }
}

/* Responsive Design */
@media (max-width: 768px) {
.content-v123 {
padding: 20px;
}

    .header-v123 {
        flex-direction: column;
        gap: 16px;
        text-align: center;
    }
    
    .doctor-info-header-v123 {
        flex-direction: column;
        text-align: center;
    }
    
    .doctor-details-grid-v123 {
        grid-template-columns: 1fr;
    }
    
    .appointments-container-v123 {
        grid-template-columns: 1fr;
    }
    
    .stats-overview-v123 {
        grid-template-columns: repeat(2, 1fr);
    }
    
    .table-container-v123 {
        max-height: 300px;
    }
    
    table {
        font-size: 12px;
    }
    
    td, th {
        padding: 12px 8px;
    }
}