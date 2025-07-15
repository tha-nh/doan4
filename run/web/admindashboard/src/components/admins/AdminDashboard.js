import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import AppointmentsChart from "./AppointmentsChart";
import FeedbackListWithReply from './FeedbackListWithReply';
import Sidebar from './Sidebar';
import './AdminDashboard.css'; // Import the CSS file

const AdminDashboard = () => {
    const [stats, setStats] = useState({
        doctors: 0,
        patients: 0,
        appointments: 0,
        staff: 0,
    });

    const [appointmentsRange, setAppointmentsRange] = useState([]);
    const [isFeedbackModalOpen, setIsFeedbackModalOpen] = useState(false);
    const [feedbacks, setFeedbacks] = useState([]);
    const [error, setError] = useState('');
    const [searchQuery, setSearchQuery] = useState('');
    const [searchType, setSearchType] = useState('patients');
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [status, setStatus] = useState('');
    const navigate = useNavigate();

    useEffect(() => {
        const isLoggedIn = localStorage.getItem('isLoggedIn');
        const role = localStorage.getItem('role');

        if (!isLoggedIn || role !== 'admin') {
            navigate('/adminlogin');
            return;
        }

        fetchStats();

        fetchAppointmentsRange();
        fetchFeedbacks();
    }, [navigate]);

    const fetchStats = async () => {
        try {
            const [doctorsRes, patientsRes, appointmentsRes, staffRes] = await Promise.all([
                axios.get('http://localhost:8081/api/v1/doctors/list'),
                axios.get('http://localhost:8081/api/v1/patients/list'),
                axios.get('http://localhost:8081/api/v1/appointments/list'),
                axios.get('http://localhost:8081/api/v1/staffs/list')
            ]);

            setStats({
                doctors: doctorsRes.data.length,
                patients: patientsRes.data.length,
                appointments: appointmentsRes.data.length,
                staff: staffRes.data.length,
            });
        } catch (error) {
            console.error('Error fetching statistics', error);
            setError('Error fetching statistics');
        }
    };


    const fetchAppointmentsRange = async () => {
        try {
            const today = new Date();
            const tenDaysAgo = new Date();
            tenDaysAgo.setDate(today.getDate() - 10);
            const threeDaysLater = new Date();
            threeDaysLater.setDate(today.getDate() + 3);

            const response = await axios.get('http://localhost:8081/api/v1/appointments/list');
            const allAppointments = response.data;

            const filteredAppointments = allAppointments.filter(appointment => {
                const medicalDay = new Date(appointment.medical_day);
                return medicalDay >= tenDaysAgo && medicalDay <= threeDaysLater;
            });

            setAppointmentsRange(filteredAppointments);
        } catch (error) {
            console.error('Error fetching appointments range', error);
            setError('Error fetching appointments range');
        }
    };

    const fetchFeedbacks = async () => {
        try {
            const response = await axios.get('http://localhost:8081/api/v1/feedbacks/list');
            setFeedbacks(response.data);
        } catch (error) {
            console.error('Error fetching feedbacks', error);
        }
    };

    const handleSearchTypeChange = (e) => {
        setSearchType(e.target.value);
    };

    const handleSearch = async () => {
        let url = '';
        let params = {};

        switch (searchType) {
            case 'patients':
                url = 'http://localhost:8081/api/v1/patients/search-new';
                params = { keyword: searchQuery };
                break;
            case 'staff':
                url = 'http://localhost:8081/api/v1/staffs/search-new';
                params = { keyword: searchQuery };
                break;
            case 'appointments':
                url = 'http://localhost:8081/api/v1/appointments/search-new';
                params = { start_date: startDate, end_date: endDate, status: status };
                break;
            case 'doctors':
                url = 'http://localhost:8081/api/v1/doctors/search-new';
                params = { keyword: searchQuery };
                break;
            default:
                return;
        }

        try {
            const response = await axios.get(url, { params });
            if (searchType === 'doctors') {
                navigate('/doctors', { state: { searchResults: response.data } });
            } else if (searchType === 'patients') {
                navigate('/patients', { state: { searchResults: response.data } });
            } else if (searchType === 'staff') {
                navigate('/staff', { state: { searchResults: response.data } });
            } else if (searchType === 'appointments') {
                navigate('/appointments', { state: { searchResults: response.data } });
            }
        } catch (error) {
            console.error('Error searching data', error);
            setError('Error searching data');
        }
    };

    const handleOpenFeedbackModal = () => {
        setIsFeedbackModalOpen(true);
    };

    const handleCloseFeedbackModal = () => {
        setIsFeedbackModalOpen(false);
    };


    const handleLogout = () => {
        localStorage.removeItem('isLoggedIn');
        localStorage.removeItem('role');
        localStorage.removeItem('adminId');
        navigate('/adminlogin');
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

    return (
        <div className="admin-dashboard">
            <Sidebar
                onInboxClick={handleOpenFeedbackModal}
                handleOpenDoctorsPage={handleOpenDoctorsPage}
                handleOpenPatientsPage={handleOpenPatientsPage}
                handleOpenAppointmentsPage={handleOpenAppointmentsPage}
                handleOpenStaffPage={handleOpenStaffPage}
            />
            <div className="main-content">
                <div className="topbar">
                    <div className="search">
                        <div className="input-container">
                            <select id="type-select" value={searchType} onChange={handleSearchTypeChange}>
                                <option value="patients">Patients</option>
                                <option value="staff">Staff</option>
                                <option value="appointments">Appointments</option>
                                <option value="doctors">Doctors</option>
                            </select>
                            <label htmlFor="type-select">Search Type</label>
                        </div>
                        <button onClick={handleSearch}>Search</button>
                    </div>
                    <div className="profile">
                        <button onClick={handleLogout}>Logout <img width="20" height="20"
                                                                   src="https://img.icons8.com/ios/50/FFFFFF/exit--v1.png"
                                                                   alt="exit--v1"/></button>
                    </div>
                </div>
                <div className="content">
                    <h2>Dashboard</h2>
                    {/*{error && <div className="error">{error}</div>}*/}
                    
                    <div className="stats">
                        <div className="card" onClick={handleOpenDoctorsPage}>
                            <h3>{stats.doctors}</h3>
                            <p>Doctors</p>
                        </div>
                        <div className="card" onClick={handleOpenPatientsPage}>
                            <h3>{stats.patients}</h3>
                            <p>Patients</p>
                        </div>
                        <div className="card" onClick={handleOpenAppointmentsPage}>
                            <h3>{stats.appointments}</h3>
                            <p>Appointments</p>
                        </div>
                        <div className="card" onClick={handleOpenStaffPage}>
                            <h3>{stats.staff}</h3>
                            <p>Staff</p>
                        </div>
                    </div>

                    <div className="charts">
                        <div className="chart">
                            <h2>Appointment Statistics</h2>
                            <AppointmentsChart appointments={appointmentsRange} />
                        </div>

                    </div>
                    {/* Removed searchResults handling */}
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

export default AdminDashboard;
