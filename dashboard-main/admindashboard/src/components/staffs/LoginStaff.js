import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import './LoginStaff.css';

const LoginStaff = () => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleLogin = async (e) => {
        e.preventDefault();
        try {
            const response = await axios.post('http://localhost:8080/api/v1/staffs/loginStaff', { username, password });
            if (response.status === 200 && response.data.staff_type === 'staff') {
                localStorage.setItem('isLoggedIn', 'true');
                localStorage.setItem('role', 'staff');
                localStorage.setItem('staffId', response.data.staff_id);
                console.log('Logged in staffId:', response.data.staff_id); // Kiểm tra giá trị của staffId
                navigate('/staffdashboard');
            } else {
                setError('You do not have access');
            }
        } catch (error) {
            if (error.response && error.response.status === 401) {
                setError('Username or password incorrect');
            } else if (error.response && error.response.status === 403) {
                setError('You do not have access');
            } else {
                setError('An error occurred, please try again later');
            }
        }
    };

    return (
        <div className="login-container">
            <div className="login-form">
                <h2>Staff Login</h2>
                <form onSubmit={handleLogin}>
                    <div className="form-group">
                        <label>Username:</label>
                        <input
                            type="text"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            required
                        />
                    </div>
                    <div className="form-group">
                        <label>Password:</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>
                    {error && <p className="error-message">{error}</p>}
                    <button type="submit" className="login-button">Login</button>
                </form>
            </div>
        </div>
    );
};

export default LoginStaff;
