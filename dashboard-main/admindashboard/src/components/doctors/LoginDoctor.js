import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import './LoginDoctor.css'; // Import CSS file

const LoginDoctor = () => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleLogin = async (e) => {
        e.preventDefault();
        try {
            const response = await axios.post('http://localhost:8080/api/v1/doctors/login', { username, password });
            console.log('Response from server:', response.data); // Log response from server
            if (response.status === 200 && response.data.doctor_id) {
                localStorage.setItem('isLoggedIn', 'true');
                localStorage.setItem('role', 'doctor');
                localStorage.setItem('doctor_id', response.data.doctor_id); // Lưu doctor_id vào localStorage
                navigate('/doctordashboard'); // Chuyển hướng đến doctor dashboard sau khi đăng nhập thành công
            } else {
                setError('You do not have access');
            }
        } catch (error) {
            console.log('Error response:', error); // Log error response
            if (error.response && error.response.status === 401) {
                setError('Username or password incorrect');
            } else {
                setError('An error occurred, please try again later');
            }
        }
    };

    return (
        <div className="login-container">
            <h2>Doctor Login</h2>
            <form onSubmit={handleLogin} className="login-form">
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
    );
};

export default LoginDoctor;
