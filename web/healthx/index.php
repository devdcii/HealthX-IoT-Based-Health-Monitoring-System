<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthX - IoT Health Monitoring System</title>
    <link rel="icon" type="image/png" href="images/logo.png">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <!-- Navigation -->
    <nav>
        <div class="logo">
            <img src="images/logo.png" alt="HealthX Logo" class="logo-img">
            <span class="logo-text">HealthX</span>
        </div>
        <ul class="nav-links">
            <li><a href="#home" class="active">Home</a></li>
            <li><a href="#about">About</a></li>
            <li><a href="#features">Features</a></li>
            <li><a href="#parameters">Parameters</a></li>
            <li><a href="#team">Team</a></li>
            <li><a href="#contact">Contact</a></li>
        </ul>
        <button class="login-btn" onclick="openModal()">
            <i class="fas fa-user"></i> Get Started
        </button>
    </nav>

    <!-- Hero Section -->
    <section id="home" class="hero">
        <div class="hero-content">
            <h1>HealthX<br><span class="highlight">IoT-Based Health</span><br>Monitoring System</h1>
            <p class="hero-subtitle">Bridging Healthcare Gaps in Remote Communities</p>
            <p>A low-cost, portable IoT solution designed to provide comprehensive health monitoring through real-time tracking of vital signs including SpO2, heart rate, body temperature, blood pressure, and BMI.</p>
            <div class="hero-buttons">
                <button class="btn-primary" onclick="scrollToSection('about')">
                    <i class="fas fa-heartbeat"></i> Learn More
                </button>
                <button class="btn-secondary" onclick="scrollToSection('contact')">
                    <i class="fas fa-phone-alt"></i> Contact Us
                </button>
            </div>
        </div>
        <div class="hero-image">
            <img src="images/logo.png" alt="IoT Health Monitoring Device">
        </div>
    </section>

    <!-- Features Section -->
    <section id="features" class="features">
        <h2 class="section-title">System Features</h2>
        <p class="section-subtitle">Comprehensive health monitoring solution powered by IoT technology</p>
        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon"><i class="fas fa-dollar-sign"></i></div>
                <h3>Affordable & Accessible</h3>
                <p>Low-cost solution designed specifically for underserved remote communities with limited healthcare access.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fas fa-wifi"></i></div>
                <h3>Real-Time Monitoring</h3>
                <p>ESP32 microcontroller enables continuous wireless data transmission and instant health parameter updates.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fas fa-mobile-alt"></i></div>
                <h3>Mobile Integration</h3>
                <p>Flutter-based application provides seamless connectivity for both health workers and patients.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fas fa-database"></i></div>
                <h3>Data Analytics</h3>
                <p>PHP/MySQL web dashboard for comprehensive data analysis and historical trend tracking.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fas fa-shield-alt"></i></div>
                <h3>Reliable & Accurate</h3>
                <p>Precision sensors ensure accurate measurements validated against ISO/IEC 25010 and 25012 standards.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon"><i class="fas fa-hand-holding-heart"></i></div>
                <h3>Community-Centered</h3>
                <p>Designed with portability and ease of use for community health workers and rural settings.</p>
            </div>
        </div>
    </section>

    <!-- Health Parameters -->
    <section id="parameters" class="parameters">
        <h2 class="section-title">Monitored Health Parameters</h2>
        <p class="section-subtitle">Essential vital signs for comprehensive health assessment</p>
        <div class="parameters-grid">
            <div class="parameter-card">
                <div class="parameter-header">
                    <div class="parameter-icon"><i class="fas fa-thermometer-half"></i></div>
                    <h3>Body Temperature</h3>
                </div>
                <div class="parameter-value">36.5 - 37.5°C</div>
                <div class="parameter-range">Normal Range (WHO 2020)</div>
            </div>
            <div class="parameter-card">
                <div class="parameter-header">
                    <div class="parameter-icon"><i class="fas fa-heartbeat"></i></div>
                    <h3>Heart Rate</h3>
                </div>
                <div class="parameter-value">60 - 100 BPM</div>
                <div class="parameter-range">Normal Range (AHA 2021)</div>
            </div>
            <div class="parameter-card">
                <div class="parameter-header">
                    <div class="parameter-icon"><i class="fas fa-lungs"></i></div>
                    <h3>Oxygen Saturation</h3>
                </div>
                <div class="parameter-value">95 - 100%</div>
                <div class="parameter-range">Normal Range (CDC 2021)</div>
            </div>
            <div class="parameter-card">
                <div class="parameter-header">
                    <div class="parameter-icon"><i class="fas fa-tint"></i></div>
                    <h3>Blood Pressure</h3>
                </div>
                <div class="parameter-value">120/80 mmHg</div>
                <div class="parameter-range">Normal Range (AHA 2021)</div>
            </div>
            <div class="parameter-card">
                <div class="parameter-header">
                    <div class="parameter-icon"><i class="fas fa-weight"></i></div>
                    <h3>Body Mass Index</h3>
                </div>
                <div class="parameter-value">18.5 - 24.9</div>
                <div class="parameter-range">Healthy Range (WHO 2019)</div>
            </div>
        </div>
    </section>

    <!-- About Section -->
    <section id="about" class="about">
        <h2 class="section-title">About HealthX</h2>
        <div class="about-content">
            <div class="about-text">
                <h3>Advancing Healthcare Through Technology</h3>
                <p>HealthX is a low-cost IoT-based health monitoring system developed to address critical gaps in healthcare accessibility for remote communities. Unlike existing solutions, our system emphasizes affordability, portability, and comprehensive real-time monitoring.</p>
                <p>Utilizing an ESP32 microcontroller integrated with multiple precision sensors, HealthX monitors essential health parameters including oxygen saturation (SpO2), heart rate, body temperature, blood pressure, and body mass index (BMI). These parameters were specifically selected as they represent the most fundamental indicators of an individual's physiological condition.</p>
                <p>Our system operates through an integrated workflow combining hardware and software components, featuring a Flutter-based mobile application for dual user roles and a PHP/MySQL web dashboard for healthcare professionals to review information and provide timely medical guidance.</p>
            </div>
            <div class="about-image">
                <img src="images/healthhccx.png" alt="HealthX System">
            </div>
        </div>
    </section>

    <!-- Team Section -->
    <section id="team" class="team">
        <h2 class="section-title">Meet Our Team</h2>
        <p class="section-subtitle">The innovators behind HealthX</p>
        <div class="team-grid">
            <div class="team-card">
                <div class="team-image-wrapper">
                    <img src="images/team/deang.jpg" alt="Engr. Ronnel O. Deang" class="team-image-circle">
                    <div class="team-social-badge">
                        <i class="fas fa-link"></i>
                    </div>
                    <div class="team-social-popup">
                        <a href="https://www.linkedin.com/in/ronnel-deang-b10280399" class="team-social-link linkedin" target="_blank"><i class="fab fa-linkedin-in"></i></a>
                        <a href="https://github.com/ronnnn2003" class="team-social-link github" target="_blank"><i class="fab fa-github"></i></a>
                        <a href="mailto:ronneldeang1736@gmail.com" class="team-social-link email"><i class="fas fa-envelope"></i></a>
                    </div>
                </div>
                <div class="team-info">
                    <h3>Engr. Ronnel O. Deang</h3>
                    <p class="team-role">Lead Developer & Hardware Developer</p>
                    <p class="team-description">Leads hardware development and system architecture. Specializes in IoT integration, circuit design, and hardware-software connectivity.</p>
                </div>
            </div>

            <div class="team-card">
                <div class="team-image-wrapper">
                    <img src="images/team/paragas.jpg" alt="Engr. John Ian Joseph M. Paragas" class="team-image-circle">
                    <div class="team-social-badge">
                        <i class="fas fa-link"></i>
                    </div>
                    <div class="team-social-popup">
                        <a href="https://www.linkedin.com/in/john-ian-joseph-paragas-9662ba399" class="team-social-link linkedin" target="_blank"><i class="fab fa-linkedin-in"></i></a>
                        <a href="https://github.com/jijmparagas" class="team-social-link github" target="_blank"><i class="fab fa-github"></i></a>
                        <a href="mailto:paragasjohnian@gmail.com" class="team-social-link email"><i class="fas fa-envelope"></i></a>
                    </div>
                </div>
                <div class="team-info">
                    <h3>Engr. John Ian Joseph M. Paragas</h3>
                    <p class="team-role">Hardware & Embedded Systems Developer</p>
                    <p class="team-description">Handles embedded systems programming with Arduino/ESP modules, sensor integration, and IoT device communication for real-time monitoring.</p>
                </div>
            </div>

            <div class="team-card">
                <div class="team-image-wrapper">
                    <img src="images/team/digman.jpg" alt="Engr. Christian D. Digman" class="team-image-circle">
                    <div class="team-social-badge">
                        <i class="fas fa-link"></i>
                    </div>
                    <div class="team-social-popup">
                        <a href="https://www.linkedin.com/in/christian-digman-a6b202293/" class="team-social-link linkedin" target="_blank"><i class="fab fa-linkedin-in"></i></a>
                        <a href="https://github.com/psechan" class="team-social-link github" target="_blank"><i class="fab fa-github"></i></a>
                        <a href="mailto:digmanchristian0@gmail.com" class="team-social-link email"><i class="fas fa-envelope"></i></a>
                    </div>
                </div>
                <div class="team-info">
                    <h3>Engr. Christian D. Digman</h3>
                    <p class="team-role">Full-Stack Developer & IoT Systems Calibrator</p>
                    <p class="team-description">Develops frontend and backend web applications. Manages system calibration and hardware-software synchronization for accurate data transmission.</p>
                </div>
            </div>

            <div class="team-card">
                <div class="team-image-wrapper">
                    <img src="images/team/cayabyab.jpg" alt="Engr. Matt Julius M. Cayabyab" class="team-image-circle">
                    <div class="team-social-badge">
                        <i class="fas fa-link"></i>
                    </div>
                    <div class="team-social-popup">
                        <a href="https://www.linkedin.com/in/cayabyab-matt-julius-212571368?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app" class="team-social-link linkedin" target="_blank"><i class="fab fa-linkedin-in"></i></a>
                        <a href="https://github.com/mjcayabyab" class="team-social-link github" target="_blank"><i class="fab fa-github"></i></a>
                        <a href="mailto:cayabyabmattjulius@gmail.com" class="team-social-link email"><i class="fas fa-envelope"></i></a>
                    </div>
                </div>
                <div class="team-info">
                    <h3>Engr. Matt Julius M. Cayabyab</h3>
                    <p class="team-role">Mobile Application Developer & Documentation Lead</p>
                    <p class="team-description">Creates cross-platform mobile applications and maintains technical documentation, research papers, and system specifications.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Contact Section -->
    <section id="contact" class="contact">
        <h2 class="section-title">Contact Us</h2>
        <p class="section-subtitle">Get in touch with our team</p>
        <div class="contact-content">
            <div class="contact-info">
                <h3>Contact Information</h3>
                <div class="contact-item">
                    <div class="contact-icon"><i class="fas fa-map-marker-alt"></i></div>
                    <div>
                        <h4>Location</h4>
                        <p>Municipality of Santa Ana, Pampanga<br>Central Luzon, Philippines</p>
                    </div>
                </div>
                <div class="contact-item">
                    <div class="contact-icon"><i class="fas fa-envelope"></i></div>
                    <div>
                        <h4>Email</h4>
                        <p>healthxinnovation@gmail.com</p>
                    </div>
                </div>
                <div class="contact-item">
                    <div class="contact-icon"><i class="fas fa-phone-alt"></i></div>
                    <div>
                        <h4>Phone</h4>
                        <p>+63 999 392 1960</p>
                        <p>+63 933 819 7734</p>
                        <p>+63 908 968 8524</p>
                        <p>+63 999 187 0384</p>
                    </div>
                </div>
                <div class="contact-item">
                    <div class="contact-icon"><i class="fas fa-clock"></i></div>
                    <div>
                        <h4>Business Hours</h4>
                        <p>Monday - Friday: 7:00 AM - 5:00 PM</p>
                    </div>
                </div>
            </div>
            <div class="contact-form">
                <form id="contactForm">
                    <div class="form-group">
                        <label>Full Name</label>
                        <input type="text" name="full_name" placeholder="Enter your name" required>
                    </div>
                    <div class="form-group">
                        <label>Email Address</label>
                        <input type="email" name="email" placeholder="your.email@example.com" required>
                    </div>
                    <div class="form-group">
                        <label>Subject</label>
                        <input type="text" name="subject" placeholder="Subject" required>
                    </div>
                    <div class="form-group">
                        <label>Message</label>
                        <textarea name="message" placeholder="Your message..." required></textarea>
                    </div>
                    <button type="submit" class="btn-primary">
                        <i class="fas fa-paper-plane"></i> Send Message
                    </button>
                </form>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer>
        <div class="footer-content">
            <div class="footer-section">
                <div class="footer-logo">
                    <img src="images/logo.png" alt="HealthX Logo" class="footer-logo-img">
                    <h3>HealthX</h3>
                </div>
                <p>Empowering remote communities with accessible, affordable IoT-based health monitoring technology.</p>
                <div class="social-links">
                    <a href="https://www.facebook.com/profile.php?id=61583657859562" class="social-icon" target="_blank" rel="noopener noreferrer"><i class="fab fa-facebook-f"></i></a>
                    <a href="tel:+639993921960" class="social-icon"><i class="fas fa-phone"></i></a>
                    <a href="https://www.linkedin.com/in/christian-digman-a6b202293/" class="social-icon" target="_blank"><i class="fab fa-linkedin-in"></i></a>
                    <a href="mailto:healthxinnovation@gmail.com?subject=Inquiry about HealthX" class="social-icon"><i class="fas fa-envelope"></i></a>
                </div>
            </div>
            <div class="footer-section">
                <h3>Quick Links</h3>
                <ul>
                    <li><a href="#home">Home</a></li>
                    <li><a href="#about">About</a></li>
                    <li><a href="#features">Features</a></li>
                    <li><a href="#parameters">Parameters</a></li>
                    <li><a href="#team">Team</a></li>
                    <li><a href="#contact">Contact</a></li>
                </ul>
            </div>
            <div class="footer-section">
                <h3>Health Parameters</h3>
                <ul>
                    <li><a href="#">Body Temperature</a></li>
                    <li><a href="#">Heart Rate</a></li>
                    <li><a href="#">Oxygen Saturation</a></li>
                    <li><a href="#">Blood Pressure</a></li>
                    <li><a href="#">Body Mass Index</a></li>
                </ul>
            </div>
            <div class="footer-section">
                <h3>Resources</h3>
                <ul>
                    <li><a href="#">Documentation</a></li>
                    <li><a href="#">User Guide</a></li>
                    <li><a href="#">Technical Support</a></li>
                    <li><a href="#">Privacy Policy</a></li>
                    <li><a href="#">Terms of Service</a></li>
                </ul>
            </div>
        </div>
        <div class="footer-bottom">
            <p>&copy; 2025 HealthX - IoT-Based Health Monitoring System. All Rights Reserved.</p>
        </div>
    </footer>

    <!-- Login Modal -->
    <div id="loginModal" class="modal">
        <div class="modal-content">
            <span class="close-modal" onclick="closeModal()">&times;</span>
            <div class="modal-header">
                <h2>Admin Login</h2>
                <p>Access the HealthX monitoring system</p>
            </div>
            <form id="loginForm">
                <div class="form-group">
                    <label><i class="fas fa-user"></i> Username</label>
                    <input type="text" name="username" placeholder="Enter your username" required>
                </div>
                <div class="form-group">
                    <label><i class="fas fa-lock"></i> Password</label>
                    <input type="password" id="password" name="password" placeholder="Enter your password" required>
                    <i class="fas fa-eye password-toggle" id="togglePassword"></i>
                </div>
                <button type="submit" class="btn-primary">
                    <i class="fas fa-sign-in-alt"></i> Sign In
                </button>
            </form>
        </div>
    </div>

    <script src="js/script.js"></script>
</body>
</html>