import React, {useState} from 'react';
import './Contact.css';
import axios from "axios";
import logo from "../img/fpt-health-high-resolution-logo-transparent-white.png";
import bannerImg from '../img/pexels-karolina-grabowska-7195369.jpg';

function Contact() {
    const [name, setName] = useState('');
    const [phone, setPhone] = useState('');
    const [email, setEmail] = useState('');
    const [subject, setSubject] = useState('');
    const [message, setMessage] = useState('');
    const [responseMessage, setResponseMessage] = useState('');

    const handleSubmit = (e) => {
        e.preventDefault();

        const feedbackData = {
            name,
            phone,
            email,
            subject,
            message,
        };

        axios.post('http://localhost:8081/api/v1/feedback/submit', feedbackData)
            .then(response => {
                setName('');
                setPhone('');
                setEmail('');
                setSubject('');
                setMessage('');
                setResponseMessage('Feedback has been sent successfully.');

                setTimeout(() => {
                    setResponseMessage('');
                }, 5000); // 5 giây sau ẩn đi
            })
            .catch(error => {
                setResponseMessage('❌ Có lỗi xảy ra khi gửi phản hồi. Vui lòng thử lại!');

                setTimeout(() => {
                    setResponseMessage('');
                }, 5000); // 5 giây sau ẩn đi

                console.error('There was an error submitting the feedback!', error);
            });
    };
    return (
        <main className="contact-container">
            <section className="contact-banner">
                <h4>Contact Us</h4>
                <img className="contact-img" src={bannerImg} alt="contact-img"/>
                <div className="contact-overlay"></div>
            </section>
            <section className="contact-content">
                <div className="contact-form">
                    <h4>Send <span>Feedback</span></h4>
                    <p>Please fill out the form below and send your comments and questions to FPT Health. We will
                        respond
                        to your email as soon as possible.</p>
                    <form onSubmit={handleSubmit}>
                        <div className="input-list">
                            <div className={`input-area ${name ? 'has-value' : ''}`}>
                                <input
                                    required
                                    type="text"
                                    value={name}
                                    id="name"
                                    onChange={(e) => setName(e.target.value)}
                                />
                                <label htmlFor="name">Full Name</label>
                            </div>
                            <div className={`input-area ${phone ? 'has-value' : ''}`}>
                                <input
                                    required
                                    type="number"
                                    value={phone}
                                    id="phone"
                                    onChange={(e) => setPhone(e.target.value)}
                                />
                                <label htmlFor="phone">Phone Number</label>
                            </div>
                            <div className={`input-area ${email ? 'has-value' : ''}`}>
                                <input
                                    required
                                    type="email"
                                    value={email}
                                    id="email"
                                    onChange={(e) => setEmail(e.target.value)}
                                />
                                <label htmlFor="email">Email Address</label>
                            </div>
                            <div className={`input-area ${subject ? 'has-value' : ''}`}>
                                <input
                                    required
                                    type="text"
                                    value={subject}
                                    id="subject"
                                    onChange={(e) => setSubject(e.target.value)}
                                />
                                <label htmlFor="subject">Subject</label>
                            </div>
                            <div className={`input-area ${message ? 'has-value' : ''}`}>
                            <textarea
                                cols="30"
                                required
                                rows="8"
                                value={message}
                                id="message"
                                onChange={(e) => setMessage(e.target.value)}
                            />
                                <label htmlFor="message">Message</label>
                            </div>
                            <button type='submit'>Send</button>
                        </div>
                    </form>
                    {responseMessage && (
                        <div className="toast-container">
                            <div className="toast-message">
                                {responseMessage}
                                <div className="toast-progress"></div>
                            </div>
                        </div>
                    )}
                </div>
                    <iframe
                        src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3724.096609417892!2d105.77972177486252!3d21.028820080620516!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3135ab00954decbf%3A0xdb4ee23b49ad50c8!2zRlBUIEFwdGVjaCBIw6AgTuG7mWkgLSBI4buHIHRo4buRbmcgxJHDoG8gdOG6oW8gbOG6rXAgdHLDrG5oIHZpw6puIHF14buRYyB04bq_!5e0!3m2!1svi!2s!4v1724667130201!5m2!1svi!2s"
                         allowFullScreen="" loading="lazy"
                        referrerPolicy="no-referrer-when-downgrade"></iframe>
            </section>
            <footer>
                <div className="footer-container-top">
                    <div className="footer-logo">
                        <img src={logo} alt="fpt-health" style={{width: 140 + 'px', height: 40 + 'px'}}/>
                    </div>
                    <div className="footer-social">
                        <div className="fb-icon">
                            <img width="30" height="30"
                                 src="https://img.icons8.com/ios-filled/50/FFFFFF/facebook--v1.png"
                                 alt="facebook--v1"/>
                        </div>
                        <div className="zl-icon">
                            <img width="30" height="30" src="https://img.icons8.com/ios-filled/50/FFFFFF/zalo.png"
                                 alt="zalo"/>
                        </div>
                        <div className="ms-icon">
                            <img width="30" height="30"
                                 src="https://img.icons8.com/ios-filled/50/FFFFFF/facebook-messenger.png"
                                 alt="facebook-messenger"/>
                        </div>
                    </div>
                </div>
                <div className="footer-container-middle">
                    <div className="footer-content">
                        <h4>FPT Health</h4>
                        <p>FPT Health Hospital is committed to providing you and your family with the highest quality
                            medical services, featuring a team of professional doctors and state-of-the-art facilities.
                            Your health is our responsibility.</p>
                    </div>
                    <div className="footer-hours-content">
                        <h4>Opening Hours</h4>
                        <div className="footer-hours">
                            <div className="footer-content-item"><span>Monday - Friday:</span>
                                <span>7:00 AM - 8:00 PM</span></div>
                            <div className="footer-content-item"><span>Saturday:</span> <span>7:00 AM - 6:00 PM</span>
                            </div>
                            <div className="footer-content-item"><span>Sunday:</span> <span>7:30 AM - 6:00 PM</span>
                            </div>
                        </div>
                    </div>
                    <div className="footer-content">
                        <h4>Contact</h4>
                        <div className="footer-contact">
                            <div className="footer-contact-item">
                                <div>
                                    <img width="20" height="20"
                                         src="https://img.icons8.com/ios-filled/50/FFFFFF/marker.png" alt="marker"/>
                                </div>
                                <p>8 Ton That Thuyet, My Dinh Ward, Nam Tu Liem District, Ha Noi</p>
                            </div>
                            <div className="footer-contact-item">
                                <div>
                                    <img width="20" height="20"
                                         src="https://img.icons8.com/ios-filled/50/FFFFFF/phone.png" alt="phone"/>
                                </div>
                                <p>+84 987 654 321</p>
                            </div>
                            <div className="footer-contact-item">
                                <div>
                                    <img width="20" height="20"
                                         src="https://img.icons8.com/ios-filled/50/FFFFFF/new-post.png" alt="new-post"/>
                                </div>
                                <p>fpthealth@gmail.com</p>
                            </div>
                        </div>
                    </div>
                </div>
                <div className="footer-container-bottom">
                    <div>© 2024 FPT Health. All rights reserved.</div>
                    <div><a>Terms of use</a> | <a>Privacy Policy</a></div>
                </div>
            </footer>
        </main>

    );
}

export default Contact;