import React, {useState} from 'react';
import { Routes, Route } from 'react-router-dom';
import Home from './components/Home/Home';
import AboutUs from './components/About/About';
import Contact from './components/Contact/Contact';
import Header from './components/Header/Header';
import Appointment from "./components/Appointment/Appointment";
import Dashboard from "./components/Dashboard/Dashboard";
import Diagnosis from "./components/Diagnosis/Diagnosis";
import News  from "./components/News/News";
import HealthTips from "./components/Tips/HealthTips";


function App() {
    return (
        <div style={{width: 100 + '%', height: 100 + '%'}}>
            <Header />
            <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/about" element={<AboutUs />} />
                <Route path="/contact" element={<Contact />} />
                <Route path='/appointment' element={<Appointment />} />
                <Route path='/dashboard' element={<Dashboard />} />
                <Route path='/diagnosis' element={<Diagnosis />} />
                <Route path='/News' element={<News />} />
                <Route path='/Health-Tips' element={<HealthTips />} />
            </Routes>
        </div>
    );
}

export default App;