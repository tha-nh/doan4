import React, { useState } from 'react';
import axios from 'axios';

const DiagnoseComponent = () => {
    const [selectedFile, setSelectedFile] = useState(null);
    const [diagnosis, setDiagnosis] = useState('');
    const [error, setError] = useState('');

    const handleFileChange = (event) => {
        setSelectedFile(event.target.files[0]);
        setError(''); // Clear any previous errors
    };

    const handleSubmit = async () => {
        if (!selectedFile) {
            setError('Please select a file first.');
            return;
        }

        const formData = new FormData();
        formData.append('file', selectedFile);

        try {
            const response = await axios.post('http://localhost:8081/api/v1/diagnose/search', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            });
            console.log('Response:', response);
            setDiagnosis(response.data);
            setError('');
        } catch (error) {
            console.error('Error uploading file:', error);
            setError('Error uploading file');
        }
    };

    return (
        <div>
            <input
                type="file"
                onChange={handleFileChange}
                style={{ display: 'block', margin: '20px 0' }}
            />
            <button onClick={handleSubmit}>Submit</button>
            {diagnosis && <div>Diagnosis: {diagnosis}</div>}
            {error && <div style={{ color: 'red' }}>{error}</div>}
        </div>
    );
};

export default DiagnoseComponent;
