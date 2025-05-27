import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Sidebar from './Sidebar';
import './DoctorDashboard.css';

const DoctorDashboard = () => {
    const [activeView, setActiveView] = useState(null); // 'today', 'month', 'records', or null
    const [doctor, setDoctor] = useState(null);
    const [todayAppointments, setTodayAppointments] = useState([]);
    const [monthAppointments, setMonthAppointments] = useState([]);
    const [appointments, setAppointments] = useState([]); // Added for search results
    const [medicalRecords, setMedicalRecords] = useState([]);
    const [error, setError] = useState('');
    const [selectedAppointment, setSelectedAppointment] = useState(null);
    const [newStatus, setNewStatus] = useState('');
    const [openEditDialog, setOpenEditDialog] = useState(false);
    const [openMedicalRecordsDialog, setOpenMedicalRecordsDialog] = useState(false);
    const [openAddMedicalRecordDialog, setOpenAddMedicalRecordDialog] = useState(false);
    const [patientMedicalRecords, setPatientMedicalRecords] = useState([]);
    const [showTodayAppointments, setShowTodayAppointments] = useState(false);
    const [showMonthAppointments, setShowMonthAppointments] = useState(false);
    const [showMedicalRecords, setShowMedicalRecords] = useState(false);
    const [patientName, setPatientName] = useState('');
    const [patientEmail, setPatientEmail] = useState('');
    const [newMedicalRecord, setNewMedicalRecord] = useState({
        symptoms: '',
        diagnosis: '',
        treatment: '',
        test_urine: '',
        test_blood: '',
        x_ray: ''
    });
    const [editData, setEditData] = useState({
        doctor_email: '',
        doctor_address: '',
        current_password: '',
        new_password: '',
        confirm_new_password: '',
    });
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');
    const [status, setStatus] = useState('');
    const [searchType, setSearchType] = useState('appointments');
    const [searchQuery, setSearchQuery] = useState('');

    const navigate = useNavigate();

    useEffect(() => {
        const storedDoctorId = localStorage.getItem('doctor_id');
        if (storedDoctorId) {
            axios.get(`http://localhost:8080/api/v1/doctors/${storedDoctorId}`)
                .then(response => {
                    setDoctor(response.data);
                    setEditData({
                        doctor_email: response.data.doctor_email,
                        doctor_address: response.data.doctor_address,
                        current_password: '',
                        new_password: '',
                        confirm_new_password: '',
                    });
                })
                .catch(error => {
                    console.error('Lỗi khi lấy thông tin bác sĩ', error);
                    setError('Lỗi khi lấy thông tin bác sĩ');
                });

            const today = new Date().toISOString().split('T')[0];
            axios.get('http://localhost:8080/api/v1/appointments/search', {
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
                    setError('Lỗi khi lấy lịch khám hôm nay');
                });

            const firstDayOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0];
            const lastDayOfMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).toISOString().split('T')[0];
            axios.get('http://localhost:8080/api/v1/appointments/search', {
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
                    setError('Lỗi khi lấy lịch khám trong tháng');
                });

            axios.get(`http://localhost:8080/api/v1/medicalrecords/doctor/${storedDoctorId}`)
                .then(response => {
                    setMedicalRecords(response.data);
                })
                .catch(error => {
                    console.error('Lỗi khi lấy bệnh án', error);
                    setError('Lỗi khi lấy bệnh án');
                });
        }
    }, []);

    const handleSearch = () => {
        const storedDoctorId = localStorage.getItem('doctor_id');
        if (storedDoctorId) {
            let url = '';
            let params = {};

            if (searchType === 'appointments') {
                url = 'http://localhost:8080/api/v1/appointments/searchByCriteriaAndDoctor';
                params = {
                    start_date: startDate,
                    end_date: endDate,
                    status: status,
                    doctor_id: storedDoctorId
                };
            } else if (searchType === 'medicalrecords') {
                url = 'http://localhost:8080/api/v1/medicalrecords/search';
                params = {
                    keyword: searchQuery,
                    doctor_id: storedDoctorId
                };
            }

            axios.get(url, { params })
                .then(response => {
                    if (searchType === 'appointments') {
                        setAppointments(response.data);
                    } else if (searchType === 'medicalrecords') {
                        setPatientMedicalRecords(response.data);
                    }
                })
                .catch(error => {
                    console.error('Lỗi khi tìm kiếm', error);
                    setError('Lỗi khi tìm kiếm');
                });
        }
    };

    const handleEditOpen = () => {
        setOpenEditDialog(true);
    };

    const handleEditClose = () => {
        setOpenEditDialog(false);
    };

    const handleEditChange = (e) => {
        const { name, value } = e.target;
        setEditData((prevData) => ({
            ...prevData,
            [name]: value,
        }));
    };

    const handleEditSubmit = () => {
        const storedDoctorId = localStorage.getItem('doctor_id');
        if (storedDoctorId) {
            const updateData = {
                doctor_id: storedDoctorId,
                doctor_email: editData.doctor_email,
                doctor_address: editData.doctor_address,
            };

            if (editData.new_password) {
                updateData.doctor_password = editData.new_password;
            }

            axios.put('http://localhost:8080/api/v1/doctors/update', updateData)
                .then(response => {
                    console.log('Cập nhật thông tin bác sĩ thành công:', response.data);
                    setDoctor((prevDoctor) => ({
                        ...prevDoctor,
                        doctor_email: editData.doctor_email,
                        doctor_address: editData.doctor_address,
                    }));
                    setOpenEditDialog(false);
                })
                .catch(error => {
                    console.error('Lỗi khi cập nhật thông tin bác sĩ', error);
                    setError('Lỗi khi cập nhật thông tin bác sĩ');
                });
        }
    };

    const handleLogout = () => {
        localStorage.removeItem('isLoggedIn');
        localStorage.removeItem('role');
        localStorage.removeItem('doctorId');
        navigate('/doctorlogin');
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


    return (
        <div className="doctor-dashboard">
            <Sidebar
                handleOpenTodayAppointments={handleOpenTodayAppointments}
                handleOpenMonthlyAppointments={handleOpenMonthlyAppointments}
                handleOpenMedicalRecords={handleOpenMedicalRecords}
            />
            <div className="main-content">
                <div className="topbar">
                    <div className="search">
                        <div className="input-container">
                            <select value={searchType} onChange={(e) => setSearchType(e.target.value)}>
                                <option value="appointments">Appointments</option>
                                <option value="medicalrecords">Medical Records</option>
                            </select>
                            <label>Search Type</label>
                        </div>
                        {searchType === 'appointments' ? (
                            <>
                                <div className="input-container">
                                    <input
                                        type="date"
                                        placeholder="Start Date"
                                        value={startDate}
                                        onChange={(e) => setStartDate(e.target.value)}
                                    />
                                    <label>Start Date</label>
                                </div>
                                <div className="input-container">
                                    <input
                                        type="date"
                                        placeholder="End Date"
                                        value={endDate}
                                        onChange={(e) => setEndDate(e.target.value)}
                                    />
                                    <label>End Date</label>
                                </div>
                                <div className="input-container">
                                    <select value={status} onChange={(e) => setStatus(e.target.value)}>
                                        <option value="">Select Status</option>
                                        <option value="Pending">Pending</option>
                                        <option value="Completed">Completed</option>
                                        <option value="Cancelled">Cancelled</option>
                                    </select>
                                    <label>Status</label>
                                </div>
                            </>
                        ) : (
                            <input
                                type="text"
                                placeholder="Search by Patient Name or Email"
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                            />
                        )}
                        <button onClick={handleSearch}>Search</button>
                    </div>
                    <div className="profile">
                        <button onClick={handleLogout}>Logout <img width="20" height="20"
                                                                   src="https://img.icons8.com/ios/50/FFFFFF/exit--v1.png"
                                                                   alt="exit--v1"/></button>
                    </div>
                </div>
                <div className="content">

                    {doctor && (
                        <div className="doctor-info">
                            <h2>Welcome, {doctor.doctor_name}</h2>
                            <p>Email: {doctor.doctor_email}</p>
                            <p>Address: {doctor.doctor_address}</p>
                            <p>Working status: {doctor.working_status}</p>
                            <button className="btn btn-primary" onClick={handleEditOpen}>Edit Profile</button>
                        </div>
                    )}
                    <div className="stats">
                        <div className="card">
                            <div className="card-content">
                                <h4>Today's Appointment Schedule</h4>
                                <h3>{todayAppointments.length}</h3>
                                <button className="btn btn-primary" onClick={() => navigate('/todayappointments')}>
                                    View today's appointments
                                </button>
                            </div>
                        </div>
                        <div className="card">
                            <div className="card-content">
                                <h4>Monthly Appointments</h4>
                                <h3>{monthAppointments.length}</h3>
                                <button className="btn btn-primary" onClick={() => navigate('/monthlyappointments')}>
                                    View monthly appointments
                                </button>
                            </div>
                        </div>
                        <div className="card">
                            <div className="card-content">
                                <h4>Medical Records</h4>
                                <h3>{medicalRecords.length}</h3>
                                <button className="btn btn-primary" onClick={() => navigate('/medicalrecords')}>
                                    View medical records
                                </button>
                            </div>
                        </div>
                    </div>
                    {searchType === 'appointments' && (
                        <div className="appointments-list">
                            <h3>Appointments</h3>
                            <ul>
                                {appointments.map((appointment, index) => (
                                    <li key={index}>
                                        <p>Patient: {appointment.patient?.[0]?.patient_name || 'N/A'}</p>
                                        <p>Date: {new Date(appointment.medical_day).toLocaleDateString()}</p>
                                        <p>Time: {appointment.slot}</p>
                                        <p>Status: {appointment.status}</p>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    )}
                    {searchType === 'medicalrecords' && (
                        <div className="medical-records-list">
                            <h3>Medical Records</h3>
                            <ul>
                                {patientMedicalRecords.map((record, index) => (
                                    <li key={index}>
                                        <p>Patient Name: {record.patients[0]?.patient_name || 'N/A'}</p>
                                        <p>Patient Email: {record.patients[0]?.patient_email || 'N/A'}</p>
                                        <p>Symptoms: {record.symptoms}</p>
                                        <p>Diagnosis: {record.diagnosis}</p>
                                        <p>Treatment: {record.treatment}</p>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    )}
                </div>
                {openEditDialog && (
                    <div className="dialog">
                        <div className="dialog-title">Edit Personal Information</div>
                        <div className="dialog-content">
                            <input
                                type="email"
                                name="doctor_email"
                                placeholder="Email"
                                value={editData.doctor_email}
                                onChange={handleEditChange}
                            />
                            <input
                                type="text"
                                name="doctor_address"
                                placeholder="Address"
                                value={editData.doctor_address}
                                onChange={handleEditChange}
                            />
                            <input
                                type="password"
                                name="current_password"
                                placeholder="Current Password"
                                value={editData.current_password}
                                onChange={handleEditChange}
                            />
                            <input
                                type="password"
                                name="new_password"
                                placeholder="New Password"
                                value={editData.new_password}
                                onChange={handleEditChange}
                            />
                            <input
                                type="password"
                                name="confirm_new_password"
                                placeholder="Confirm New Password"
                                value={editData.confirm_new_password}
                                onChange={handleEditChange}
                            />
                        </div>
                        <div className="dialog-actions">
                            <button onClick={handleEditClose} className="btn btn-danger">Cancel</button>
                            <button onClick={handleEditSubmit} className="btn btn-primary">Save</button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default DoctorDashboard;
