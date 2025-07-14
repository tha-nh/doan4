import React from 'react';
import './HealthTips.css';
import logo from "../img/fpt-health-high-resolution-logo-transparent-white.png";

function HealthTips() {
    return (
        <main className="health-tips-container">
            {/* Banner Section */}
            <section className="health-tips-banner">
                <img alt="health-tips-banner" src="https://res.cloudinary.com/dccblgqdw/image/upload/v1737927575/ElbowBump_Masks_1280x720_jpg1737927575250.jpg" />
            </section>

            {/* Nutrition Section */}
            <section className="health-topics nutrition-section fade-in">
                <div className="topics-img">
                    <img src="https://images.unsplash.com/photo-1498837167922-ddd27525d352?q=80&w=1000&auto=format&fit=crop" alt="nutrition" />
                </div>
                <div className="topics-content">
                    <h2>Nutrition <span>for Wellness</span></h2>
                    <div className="topic-item">
                        <h3>Balanced Nutrition</h3>
                        <p>A balanced diet provides essential nutrients for optimal health. Include whole grains, lean proteins, healthy fats, and a variety of fruits and vegetables. The World Health Organization states that a healthy diet can reduce chronic disease risk by up to 80%.</p>
                        <ul>
                            <li>Choose whole grains like oats and brown rice.</li>
                            <li>Incorporate lean proteins such as chicken or tofu.</li>
                            <li>Eat colorful vegetables for diverse nutrients.</li>
                        </ul>
                    </div>
                    <div className="topic-item">
                        <h3>Young Adults</h3>
                        <p>Young adults need nutrient-dense foods to fuel active lifestyles. High-protein foods like eggs, legumes, and Greek yogurt support muscle growth, while complex carbs like quinoa provide sustained energy. Aim for 5-7 servings of fruits and vegetables daily.</p>
                        <ul>
                            <li>Snack on nuts and seeds for energy boosts.</li>
                            <li>Hydrate with 2-3 liters of water daily.</li>
                            <li>Limit sugary drinks to maintain energy balance.</li>
                        </ul>
                    </div>
                    <div className="topic-item">
                        <h3>Seniors</h3>
                        <p>Seniors benefit from nutrient-rich foods to support bone health and immunity. Calcium-rich foods like dairy or fortified plant milk, and vitamin D from sunlight or supplements, are essential. Fiber from whole grains aids digestion and heart health.</p>
                        <ul>
                            <li>Include leafy greens like kale for bone strength.</li>
                            <li>Choose soft fruits like bananas for easy digestion.</li>
                            <li>Consult a dietitian for personalized needs.</li>
                        </ul>
                    </div>
                    <div className="topic-item">
                        <h3>Medical Conditions</h3>
                        <p>Tailored diets are crucial for managing conditions like diabetes or hypertension. Low-sodium and low-sugar diets, combined with whole foods, help control symptoms. The American Diabetes Association recommends monitoring carb intake for blood sugar control.</p>
                        <ul>
                            <li>Choose heart-healthy fats like avocados and olive oil.</li>
                            <li>Avoid processed foods high in sodium.</li>
                            <li>Work with a healthcare provider for dietary plans.</li>
                        </ul>
                    </div>
                </div>
            </section>

            {/* Exercise Section */}
            <section className="health-topics exercise-section fade-in">
                <div className="topics-img">
                    <img src="https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1000&auto=format&fit=crop" alt="exercise" />
                </div>
                <div className="topics-content">
                    <h2>Exercise <span>for Vitality</span></h2>
                    <div className="topic-item">
                        <h3>Fitness for All</h3>
                        <p>Regular physical activity improves cardiovascular health, strength, and mood. The CDC recommends 150 minutes of moderate aerobic activity weekly, plus muscle-strengthening exercises twice a week. Start with activities you enjoy to build consistency.</p>
                        <ul>
                            <li>Walk briskly for 30 minutes daily.</li>
                            <li>Incorporate bodyweight exercises like squats.</li>
                            <li>Stretch daily to improve flexibility.</li>
                        </ul>
                    </div>
                    <div className="topic-item">
                        <h3>Young Adults</h3>
                        <p>High-energy workouts like HIIT, running, or weightlifting are ideal for young adults. Focus on proper form to prevent injuries, and include stretching or yoga for flexibility. Aim for 30-45 minutes of exercise, 5 days a week.</p>
                        <ul>
                            <li>Try circuit training for full-body fitness.</li>
                            <li>Join group classes for motivation and community.</li>
                            <li>Prioritize rest days to avoid overtraining.</li>
                        </ul>
                    </div>
                    <div className="topic-item">
                        <h3>Seniors</h3>
                        <p>Low-impact exercises like walking, yoga, or water aerobics enhance mobility and balance. These activities protect joints while improving strength. Always consult a physician before starting a new routine, especially with existing health conditions.</p>
                        <ul>
                            <li>Practice chair yoga for joint flexibility.</li>
                            <li>Walk 20-30 minutes daily for heart health.</li>
                            <li>Use resistance bands for gentle strength training.</li>
                        </ul>
                    </div>
                    <div className="topic-item">
                        <h3>Medical Conditions</h3>
                        <p>Tailored exercise plans support chronic condition management. Low-impact activities like swimming or cycling are ideal for heart conditions, while guided physical therapy aids mobility issues. Always follow medical guidance for safety.</p>
                        <ul>
                            <li>Work with a physiotherapist for customized plans.</li>
                            <li>Monitor heart rate during physical activity.</li>
                            <li>Avoid high-intensity exercises without approval.</li>
                        </ul>
                    </div>
                </div>
            </section>

            {/* Mental Health Section */}
            <section className="health-topics mental-health-section fade-in">
                <div className="topics-img">
                    <img src="https://d4804za1f1gw.cloudfront.net/wp-content/uploads/sites/106/2025/05/Mental-Health-Awareness-Resources-1780x890-1.png" alt="mental-health" />
                </div>
                <div className="topics-content">
                    <h2>Mental Health <span>for Balance</span></h2>
                    <div className="topic-item">
                        <h3>Emotional Wellness</h3>
                        <p>Mental health is vital for overall well-being. Practices like mindfulness, journaling, and social connections reduce stress and build resilience, as supported by the American Psychological Association. Small daily habits can make a big difference.</p>
                        <ul>
                            <li>Practice 5 minutes of deep breathing daily.</li>
                            <li>Keep a gratitude journal to boost positivity.</li>
                            <li>Connect with loved ones regularly.</li>
                        </ul>
                    </div>
                    <div className="topic-item">
                        <h3>Young Adults</h3>
                        <p>Young adults face stressors like academic pressure and career goals. Mindfulness apps, consistent sleep (7-9 hours), and hobbies like art or music can reduce anxiety and improve focus. Social support is key to mental resilience.</p>
                        <ul>
                            <li>Use apps like Headspace for guided meditation.</li>
                            <li>Maintain a regular sleep schedule.</li>
                            <li>Engage in creative outlets to relieve stress.</li>
                        </ul>
                        <a href="#mental-young">Explore Tips</a>
                    </div>
                    <div className="topic-item">
                        <h3>Seniors</h3>
                        <p>Seniors can maintain mental health through social activities, cognitive exercises, and relaxation techniques. Activities like reading, puzzles, or group classes combat loneliness and keep the mind sharp. Professional support is valuable when needed.</p>
                        <ul>
                            <li>Join community groups for social engagement.</li>
                            <li>Practice daily mindfulness or light meditation.</li>
                            <li>Consult a therapist for emotional support.</li>
                        </ul>
                    </div>
                    <div className="topic-item">
                        <h3>Medical Conditions</h3>
                        <p>Chronic conditions can impact mental health. Cognitive behavioral therapy (CBT), support groups, and stress management techniques help manage anxiety and depression. Always seek professional guidance for tailored mental health plans.</p>
                        <ul>
                            <li>Join condition-specific support groups.</li>
                            <li>Practice progressive muscle relaxation.</li>
                            <li>Work with a therapist for personalized strategies.</li>
                        </ul>
                    </div>
                </div>
            </section>

            {/* Community Q&A Section */}
            <section className="community-qa fade-in">
                <div className="qa-img">
                    <img src="https://images.unsplash.com/photo-1529156069898-49953e39b3ac?q=80&w=1000&auto=format&fit=crop" alt="community" />
                </div>
                <div className="qa-content">
                    <h2>Join Our <span>Health Community</span></h2>
                    <p>Connect with others, share experiences, and ask questions in our supportive health community. Our moderated Q&A platform ensures reliable, expert-reviewed answers to your health queries.</p>
                    <p>All submissions are reviewed by our health experts for accuracy. Your privacy is protected under our <a href="#privacy">Privacy Policy</a>.</p>
                </div>
            </section>

            {/* Trusted Resources Section */}
            <section className="health-resources fade-in">
                <div className="resources-img">
                    <img src="https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=1000&auto=format&fit=crop" alt="resources" />
                </div>
                <div className="resources-content">
                    <h2>Trusted <span>Resources</span></h2>
                    <p>Our health tips are sourced from reputable organizations like the World Health Organization (WHO), Centers for Disease Control and Prevention (CDC), and peer-reviewed medical journals. Explore our curated resources for reliable, science-based information.</p>
                </div>
            </section>

            {/* Legal Disclaimer Section */}
            <section className="legal-disclaimer fade-in">
                <h2>Important <span>Information</span></h2>
                <div className="disclaimer-content">
                    <h3>Legal Disclaimer</h3>
                    <p>The health tips provided on this page are for informational purposes only and are not a substitute for professional medical advice, diagnosis, or treatment. Always consult a qualified healthcare provider before making changes to your diet, exercise, or mental health practices. FPT Health complies with all applicable regulations regarding medical advertising and data protection, including GDPR and local laws. Your personal information is protected under our <a href="#privacy">Privacy Policy</a>.</p>
                </div>
            </section>

            {/* Footer Section */}
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

export default HealthTips;