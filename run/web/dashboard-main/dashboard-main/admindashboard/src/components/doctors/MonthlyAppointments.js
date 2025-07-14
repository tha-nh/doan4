import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Sidebar from './Sidebar'; // Import Sidebar
import './MonthlyAppointments.css';

const MonthlyAppointments = () => {
    const [monthAppointments, setMonthAppointments] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');

    const navigate = useNavigate(); // Define navigate

    useEffect(() => {
        const storedDoctorId = localStorage.getItem('doctor_id');
        if (storedDoctorId) {
            const firstDayOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0];
            const lastDayOfMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).toISOString().split('T')[0];
            axios.get('http://localhost:8081/api/v1/appointments/search', {
                params: {
                    start_date: firstDayOfMonth,
                    end_date: lastDayOfMonth,
                    doctor_id: storedDoctorId
                }
            })
                .then(response => {
                    setMonthAppointments(response.data);
                })
                .catch(error => {
                    console.error('Lỗi khi lấy lịch khám trong tháng', error);
                });
        }
    }, []);

    const formatTimeSlot = (slot) => {
        switch (slot) {
            case 1:
                return '8:00 AM - 9:00 AM';
            case 2:
                return '9:00 AM - 10:00 AM';
            case 3:
                return '10:00 AM - 11:00 AM';
            case 4:
                return '11:00 AM - 12:00 AM';
            case 5:
                return '01:00 PM - 02:00 PM';
            case 6:
                return '02:00 PM - 03:00 PM';
            case 7:
                return '03:00 PM - 04:00 PM';
            case 8:
                return '04:00 PM - 05:00 PM';
            default:
                return 'Slot Time Not Defined';
        }
    };

    const filteredMonthAppointments = monthAppointments.filter(appointment =>
        appointment.patient?.[0]?.patient_name.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const handleOpenTodayAppointments = () => {
        navigate('/todayappointments');
    };

    const handleOpenMonthlyAppointments = () => {
        navigate('/monthlyappointments');
    };

    const handleOpenMedicalRecords = () => {
        navigate('/medicalrecords');
    };

    return (
        <div className="monthly-appointments">
            <Sidebar
                handleOpenTodayAppointments={handleOpenTodayAppointments}
                handleOpenMonthlyAppointments={handleOpenMonthlyAppointments}
                handleOpenMedicalRecords={handleOpenMedicalRecords}
            />
            <div className="content">
                <input
                    type="text"
                    placeholder="Search Patient Name"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="search-bar"
                />
                <h3>Monthly Appointments Schedule</h3>
                <ul className="appointments-list">
                    {filteredMonthAppointments.map((appointment, index) => (
                        <li key={index}>
                            <p>Patient Name: {appointment.patient?.[0]?.patient_name || 'N/A'}</p>
                            <p>Email: {appointment.patient?.[0]?.patient_email || 'N/A'}</p>
                            <p>Date: {new Date(appointment.medical_day).toLocaleDateString()}</p>
                            <p>Time: {formatTimeSlot(appointment.slot)}</p>
                            <p>Status: {appointment.status}</p>
                        </li>
                    ))}
                </ul>
            </div>
        </div>
    );
};

export default MonthlyAppointments;
