import React from 'react';
import bannerImg from '../img/logoabout.jpg';
import introImg from '../img/young-doctors-with-cardiogram-hospital.jpg';
import coreImg from '../img/vision2_e481595219.jpg';
import diagramImg from '../img/sodobenhvien.png'
import './About.css';
import logo from "../img/fpt-health-high-resolution-logo-transparent-white.png";

function AboutUs() {
    return (
        <main className="about-us-container">
            <section className="about-banner">
                <h4>About Us</h4>
                <img alt="about-banner" src={bannerImg} className="about-img"/>
                <div className="about-overlay"></div>
            </section>
            <section className="introduction">
                <div className="introduction-img">
                    <img src={introImg}/>
                </div>
                <div className="introduction-content">
                    <div className="introduction-item">
                        <h4>About <span>FPT Health</span></h4>
                        <p>FPT Health is a non-profit healthcare system invested, with the vision of becoming an
                            international academic healthcare system through breakthrough research, aiming to provide
                            excellent treatment quality and perfect care services.</p>
                    </div>
                    <div className="introduction-item">
                        <h4>Our <span>Vision</span></h4>
                        <p>FPT Health is dedicated to academic healthcare for people at local and global scales through
                            innovation research and breakthroughs that lead to clinical excellence and value-based care
                            solutions.</p>
                    </div>
                    <div className="introduction-item">
                        <h4>Our <span>Mission</span></h4>
                        <p>We care with compassion, professionalism, and wisdom.</p>
                    </div>
                </div>
            </section>
            <section className="core-values">
                <div className="core-values-content">
                    <h1>Core Values - <span>H.E.A.L.T.H</span></h1>
                    <div className="core-values-items">
                        <div className="core-values-item">
                            <div className="item-content"><img width="30" height="30"
                                                               src="https://img.icons8.com/ios-filled/50/FFFFFF/heart-with-pulse--v1.png"
                                                               alt="heart-with-pulse--v1"/><h4>Healing</h4></div>
                            <p>Focus on treating and restoring patients' health, offering advanced medical services to
                                ensure an effective healing process.</p>
                        </div>
                        <div className="core-values-item">
                            <div className="item-content"><img width="30" height="30"
                                                               src="https://img.icons8.com/ios-filled/50/FFFFFF/empathy--v1.png"
                                                               alt="empathy--v1"/><h4>Empathy</h4></div>
                            <p>Committed to listening and understanding patients' needs, fostering a caring and
                                respectful environment.</p>
                        </div>
                        <div className="core-values-item">
                            <div className="item-content"><img width="30" height="30"
                                                               src="https://img.icons8.com/ios-filled/50/FFFFFF/accessibility2.png"
                                                               alt="accessibility2"/><h4>Accessibility</h4></div>
                            <p>Ensuring that everyone can easily access healthcare services, regardless of geographic
                                location or economic circumstances.</p>
                        </div>
                        <div className="core-values-item">
                            <div className="item-content"><img
                                width="30" height="30"
                                src="https://img.icons8.com/ios-filled/50/FFFFFF/medical-doctor.png"
                                alt="medical-doctor"/><h4>Leadership</h4></div>
                            <p>Leading in the adoption of new technologies and treatment methods, aiming to be a pioneer
                                in the healthcare field.</p>
                        </div>
                        <div className="core-values-item">
                            <div className="item-content"><img width="30" height="30"
                                                               src="https://img.icons8.com/ios-filled/50/FFFFFF/trust--v1.png"
                                                               alt="trust--v1"/><h4>Trust</h4></div>
                            <p>Building trust with patients by providing high-quality, transparent, and honest medical
                                services.</p>
                        </div>
                        <div className="core-values-item">
                            <div className="item-content">
                                <img width="30" height="30"
                                     src="https://img.icons8.com/ios-filled/50/FFFFFF/heart-health.png"
                                     alt="heart-health"/><h4>Hope</h4>
                            </div>
                            <p>Bringing hope to patients and their families, not just in treatment but in creating a
                                healthier future.</p>
                        </div>
                    </div>
                </div>
                <div className="core-values-img">
                    <img src={coreImg}/>
                </div>
            </section>
            <section className="diagram">
                <h1>Hospital <span>Diagram</span></h1>
                <img src={diagramImg}/>
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

export default AboutUs;