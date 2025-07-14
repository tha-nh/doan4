import React, {useState, useEffect, useRef} from 'react';
import introImg from '../img/pexels-thirdman-7659573.jpg';
import bannerVideo from '../img/banner-video.mp4';
import aboutImg from '../img/dayne.png';
import logo from '../img/fpt-health-high-resolution-logo-transparent-white.png';
import Slider from 'react-slick';
import 'slick-carousel/slick/slick.css';
import 'slick-carousel/slick/slick-theme.css';
import './Home.css';
import {NavLink} from "react-router-dom";

const NumberCounter = ({targetValue, duration = 3000}) => {
    const [count, setCount] = useState(0);
    const ref = useRef(null);
    const [isVisible, setIsVisible] = useState(false);

    const handleScroll = () => {
        if (ref.current) {
            const rect = ref.current.getBoundingClientRect();
            if (rect.top >= 0 && rect.bottom <= window.innerHeight) {
                setIsVisible(true);
                window.removeEventListener('scroll', handleScroll);
            }
        }
    };

    useEffect(() => {
        window.addEventListener('scroll', handleScroll);
        return () => {
            window.removeEventListener('scroll', handleScroll);
        };
    }, []);

    useEffect(() => {
        if (isVisible) {
            let start = 0;
            const incrementValue = targetValue / (duration / 20);

            const counter = setInterval(() => {
                start += incrementValue;
                if (start >= targetValue) {
                    setCount(targetValue);
                    clearInterval(counter);
                } else {
                    setCount(Math.floor(start));
                }
            }, 10);

            return () => clearInterval(counter);
        }
    }, [isVisible, targetValue]);

    return (
        <div className="number" ref={ref}>
            {count}
        </div>
    );
};


function Home() {
    const introRef = useRef(null);
    const [articles, setArticles] = useState([]);

    const settings = {
        dots: true,
        infinite: true,
        speed: 5000,
        slidesToShow: 4,
        slidesToScroll: 1,
        autoplay: true,
        autoplaySpeed: 2000,

    };

    useEffect(() => {
        const fetchArticles = async () => {
            const storedArticles = localStorage.getItem('newsArticles');
            if (storedArticles) {
                setArticles(JSON.parse(storedArticles));
            }
            try {
                const response = await fetch('http://localhost:5000/news');
                const data = await response.json();
                setArticles(data);
                localStorage.setItem('newsArticles', JSON.stringify(data));
            } catch (error) {
                console.error('Error fetching data:', error);
            }
        };

        fetchArticles();
    }, []);

    useEffect(() => {
        const handleScroll = () => {
            if (introRef.current) {
                const rect = introRef.current.getBoundingClientRect();
                const triggerPoint = window.innerHeight * 0.9;
                if (rect.top <= triggerPoint && rect.bottom >= 0) {
                    const features = introRef.current.querySelectorAll('.feature');
                    const introText = introRef.current.querySelectorAll('.text-content h1');
                    const introImage = introRef.current.querySelectorAll('.image-content');
                    features.forEach((feature) => feature.classList.add('slide-to-top'));
                    introText.forEach((feature) => feature.classList.add('slide-to-top'));
                    introImage.forEach((feature) => feature.classList.add('slide-to-top'));
                    window.removeEventListener('scroll', handleScroll);
                }
            }
        };

        window.addEventListener('scroll', handleScroll);
        return () => {
            window.removeEventListener('scroll', handleScroll);
        };
    }, []);

    return (
        <main className="home-container">
            <section className="home-banner">
                <video autoPlay muted loop className="banner-video">
                    <source
                        src={bannerVideo}
                        type="video/mp4"/>
                </video>
                <div className="banner-text">
                    <h4>Your health is our top priority!</h4>
                    <p>Your Partner in Health, Combining World-Class Medical Expertise with Unwavering Compassion and
                        Support.</p>
                    <NavLink className="banner-book-btn" to="/appointment">
                        <div className="arrow-container">
                            <div className="arrow-line"></div>
                            <div className="arrow-right"></div>
                        </div>
                        Get Appointment
                    </NavLink>
                </div>
            </section>
            <section className="intro-container" ref={introRef}>
                <div className="text-content">
                    <h1>Take On The <span>Challenge</span> Of Health Care Delivery</h1>
                    <div className="feature">
                        <div className="feature-icon">
                            <img width="40" height="40"
                                 src="https://img.icons8.com/pastel-glyph/64/FFFFFF/doctor-skin-type-1.png"
                                 alt="doctor-skin-type-1"/>
                        </div>
                        <div className="feature-text">
                            <h3>Skilled Doctors</h3>
                            <p>Our team of highly skilled doctors is dedicated to providing exceptional medical care,
                                ensuring the best outcomes for our patients.</p>
                        </div>
                    </div>
                    <div className="feature">
                        <div className="feature-icon">
                            <img width="40" height="40" src="https://img.icons8.com/ios/50/FFFFFF/sphygmomanometer.png"
                                 alt="sphygmomanometer"/>
                        </div>
                        <div className="feature-text">
                            <h3>Modern Facilities</h3>
                            <p>Our state-of-the-art facilities are equipped with the latest technology to offer advanced
                                medical treatments and a comfortable environment.</p>
                        </div>
                    </div>
                    <div className="feature">
                        <div className="feature-icon">
                            <img width="40" height="40" src="https://img.icons8.com/laces/64/FFFFFF/workflow.png"
                                 alt="workflow"/>
                        </div>
                        <div className="feature-text">
                            <h3>Fast & Efficient Workflow</h3>
                            <p>We prioritize efficiency in our workflow to deliver timely and effective healthcare
                                services, minimizing wait times for our patients.</p>
                        </div>
                    </div>
                </div>
                <img className="image-content" src={introImg} alt="Health Care Delivery"/>
            </section>
            <section className="home-numbers-container">
                <div className="numbers-text">
                    <h1>We Provide Quality Care For <span>Your Health</span></h1>
                    <p>We are committed to delivering exceptional healthcare services to prioritize your well-being with
                        our experienced doctors strive to create an
                        environment that fosters healing and promotes a healthy lifestyle</p>
                </div>
                <div className="home-numbers">
                    <div className="counter-div">
                        <div className="counter-number">
                            <NumberCounter targetValue={50}/>+
                        </div>
                        <div className="counter-text">Year of development</div>
                    </div>
                    <div className="counter-div">
                        <div className="counter-number">
                            <NumberCounter targetValue={100}/>+
                        </div>
                        <div className="counter-text">Doctors & Employees</div>
                    </div>
                    <div className="counter-div">
                        <div className="counter-number">
                            <NumberCounter targetValue={1000}/>+
                        </div>
                        <div className="counter-text">Appointments / Month</div>
                    </div>
                    <div className="counter-div">
                        <div className="counter-number">
                            <NumberCounter targetValue={200}/>+
                        </div>
                        <div className="counter-text">Patients / Month</div>
                    </div>
                </div>
            </section>
            <section className="home-about">
                    <img className="home-about-img" src={aboutImg} alt="home-about-img"/>
                <div className="home-about-content">
                    <h4>Why <span>FPT Health?</span></h4>
                    <h5>Affirming its leading position in the field of health care not only in Vietnam but also
                        reaching the region and the world.</h5>
                    <p>FPT Health is a leading healthcare institution dedicated to providing high-quality medical
                        services. With a commitment to innovation and patient-centered care, FPT Health combines
                        advanced technology with a team of highly skilled professionals to deliver comprehensive
                        healthcare solutions. The hospital offers a wide range of services, including specialized
                        medical treatments, preventive care, and personalized health management programs. FPT Health's
                        state-of-the-art facilities and commitment to continuous improvement make it a trusted choice
                        for individuals seeking exceptional healthcare.</p>
                </div>
            </section>
            <section className="partners-container">
                <h4>Our <span>Partners</span></h4>
                <Slider {...settings} className="carousel">
                    <div className="card carousel-item card-1">
                        <img src="https://yteco.vn/Data/Sites/1/News/2736/welbutech-1.png" alt="Scigen"/>
                    </div>
                    <div className="card carousel-item card-2">
                        <img src="https://yteco.vn/Data/Sites/1/News/2742/urgo-1.png" alt="Dr. Med"/>
                    </div>
                    <div className="card carousel-item card-3">
                        <img src="https://yteco.vn/Data/Sites/1/News/2735/ge-healthcare-1.png"
                             alt="Allegens"/>
                    </div>
                    <div className="card carousel-item card-4">
                        <img src="https://yteco.vn/Data/Sites/1/News/2705/d-tek1.png"
                             alt="Allegens"/>
                    </div>
                    <div className="card carousel-item card-5">
                        <img src="https://yteco.vn/Data/Sites/1/News/2702/and-3.png"
                             alt="Allegens"/>
                    </div>
                    <div className="card carousel-item card-6">
                        <img src="https://yteco.vn/Data/Sites/1/News/2552/scigen-1.png"
                             alt="Allegens"/>
                    </div>
                </Slider>
            </section>
            <section className="news-container">
                <h4>Latest <span>News</span></h4>
                <div className="news-content">
                    {articles.map((article, i) => (
                        <div key={i} className="news-item">
                            {article.image && <img src={article.image} alt={article.title} width="300"/>}
                            <a href={article.link} target="_blank" rel="noopener noreferrer" className="news-title">
                                {article.title}
                            </a>
                            <p className="news-description">{article.description}</p>
                            <a href={article.link} target="_blank" rel="noopener noreferrer"
                               className="readMore">Read more <div className="arrow-right"></div></a>
                        </div>
                    ))}
                </div>
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

export default Home;