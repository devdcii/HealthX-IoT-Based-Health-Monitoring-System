// Readings Page JavaScript - Matching dashboard.php design
const sidebar = document.getElementById('sidebar');
const sidebarToggle = document.getElementById('sidebarToggle');
const menuToggle = document.getElementById('menuToggle');

if(window.innerWidth > 768 && localStorage.getItem('sidebarCollapsed') === 'true') sidebar.classList.add('collapsed');

if(sidebarToggle) sidebarToggle.addEventListener('click', () => {
    sidebar.classList.toggle('collapsed');
    localStorage.setItem('sidebarCollapsed', sidebar.classList.contains('collapsed'));
});

if(menuToggle) menuToggle.addEventListener('click', (e) => {
    e.stopPropagation();
    sidebar.classList.toggle('mobile-active');
    document.body.classList.toggle('sidebar-open');
});

document.addEventListener('click', (e) => {
    if (window.innerWidth <= 768 && sidebar.classList.contains('mobile-active') && 
        !sidebar.contains(e.target) && !menuToggle.contains(e.target)) {
        sidebar.classList.remove('mobile-active');
        document.body.classList.remove('sidebar-open');
    }
});

if(sidebar) sidebar.addEventListener('click', (e) => e.stopPropagation());

// Modal Functions (matching dashboard.php)
function showPatientModal(button) {
    const patientData = JSON.parse(button.getAttribute('data-patient'));
    const modal = document.getElementById('patientModal');
    
    document.getElementById('modalAvatar').textContent = patientData.patient_name.charAt(0).toUpperCase();
    document.getElementById('modalPatientName').textContent = patientData.patient_name;
    document.getElementById('modalWorker').textContent = patientData.worker_email.split('@')[0];
    
    const timestamp = new Date(patientData.timestamp).toLocaleString('en-US', {
        month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit'
    });
    document.getElementById('modalTime').textContent = timestamp;
    
    function categorizeBMI(bmi) {
        if (bmi < 18.5) return { category: 'Underweight', class: 'low' };
        if (bmi < 25.0) return { category: 'Normal', class: 'normal' };
        if (bmi < 30.0) return { category: 'Overweight', class: 'elevated' };
        if (bmi < 35.0) return { category: 'Obesity Class I', class: 'high' };
        if (bmi < 40.0) return { category: 'Obesity Class II', class: 'critical' };
        return { category: 'Obesity Class III', class: 'critical' };
    }
    
    function categorizeTemp(temp) {
        if (temp < 35.0) return { category: 'Hypothermia', class: 'critical' };
        if (temp < 36.5) return { category: 'Slightly Low', class: 'low' };
        if (temp < 37.6) return { category: 'Normal', class: 'normal' };
        if (temp < 38.1) return { category: 'Low-grade Fever', class: 'elevated' };
        if (temp < 39.1) return { category: 'Fever', class: 'high' };
        return { category: 'High Fever', class: 'critical' };
    }
    
    function categorizeHR(hr) {
        if (hr < 50) return { category: 'Bradycardia', class: 'critical' };
        if (hr < 60) return { category: 'Low (Athletic)', class: 'low' };
        if (hr <= 100) return { category: 'Normal', class: 'normal' };
        if (hr <= 120) return { category: 'Elevated', class: 'elevated' };
        return { category: 'Tachycardia', class: 'critical' };
    }
    
    function categorizeSpO2(spo2) {
        if (spo2 < 90) return { category: 'Hypoxemia', class: 'critical' };
        if (spo2 < 93) return { category: 'Low', class: 'high' };
        if (spo2 < 95) return { category: 'Slightly Low', class: 'elevated' };
        return { category: 'Normal', class: 'normal' };
    }
    
    function categorizeBP(sys, dia) {
        if (sys > 180 || dia > 120) return { category: 'Hypertensive Crisis', class: 'critical' };
        if (sys >= 140 || dia >= 90) return { category: 'Stage 2 Hypertension', class: 'high' };
        if (sys >= 130 || dia >= 80) return { category: 'Stage 1 Hypertension', class: 'elevated' };
        if (sys >= 120 && dia < 80) return { category: 'Elevated', class: 'elevated' };
        return { category: 'Normal', class: 'normal' };
    }
    
    const vitalsHTML = `
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/body-mass-index.png" alt="BMI" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-weight" style="display: none;"></i> BMI
            </div>
            <div class="modal-vital-value">${parseFloat(patientData.bmi).toFixed(1)}</div>
            <span class="modal-vital-status ${categorizeBMI(patientData.bmi).class}">${categorizeBMI(patientData.bmi).category}</span>
        </div>
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/body-temperature.png" alt="Temperature" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-thermometer-half" style="display: none;"></i> Temperature
            </div>
            <div class="modal-vital-value">${parseFloat(patientData.temperature).toFixed(1)}°C</div>
            <span class="modal-vital-status ${categorizeTemp(patientData.temperature).class}">${categorizeTemp(patientData.temperature).category}</span>
        </div>
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/heart-rate.png" alt="Heart Rate" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-heartbeat" style="display: none;"></i> Heart Rate
            </div>
            <div class="modal-vital-value">${patientData.heart_rate} bpm</div>
            <span class="modal-vital-status ${categorizeHR(patientData.heart_rate).class}">${categorizeHR(patientData.heart_rate).category}</span>
        </div>
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/oxygen-saturation.png" alt="SpO2" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-lungs" style="display: none;"></i> SpO2
            </div>
            <div class="modal-vital-value">${patientData.spo2}%</div>
            <span class="modal-vital-status ${categorizeSpO2(patientData.spo2).class}">${categorizeSpO2(patientData.spo2).category}</span>
        </div>
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/blood-pressure.png" alt="BP" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-stethoscope" style="display: none;"></i> Blood Pressure
            </div>
            <div class="modal-vital-value">${patientData.systolic}/${patientData.diastolic}</div>
            <span class="modal-vital-status ${categorizeBP(patientData.systolic, patientData.diastolic).class}">${categorizeBP(patientData.systolic, patientData.diastolic).category}</span>
        </div>
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/height.png" alt="Height" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-ruler-vertical" style="display: none;"></i> Height
            </div>
            <div class="modal-vital-value">${parseFloat(patientData.height).toFixed(2)} cm</div>
            <span class="modal-vital-status normal">Recorded</span>
        </div>
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/weight.png" alt="Weight" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-weight-scale" style="display: none;"></i> Weight
            </div>
            <div class="modal-vital-value">${parseFloat(patientData.weight).toFixed(1)} kg</div>
            <span class="modal-vital-status normal">Recorded</span>
        </div>
    `;
    
    document.getElementById('modalVitals').innerHTML = vitalsHTML;
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeModal() {
    document.getElementById('patientModal').classList.remove('active');
    document.body.style.overflow = '';
}

document.addEventListener('click', (e) => {
    if (e.target.id === 'patientModal') closeModal();
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
});

const currentPage = window.location.pathname.split('/').pop().split('?')[0];
document.querySelectorAll('.nav-item').forEach(item => {
    const href = item.getAttribute('href');
    if(href === currentPage || (href && href.includes('readings.php') && currentPage.includes('readings.php'))) {
        item.classList.add('active');
    }
});

const observerOptions = { threshold: 0.1, rootMargin: '0px 0px -50px 0px' };
const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

document.addEventListener('DOMContentLoaded', function() {
    const animatedElements = document.querySelectorAll('.stat-card, .vital-card, .modal-vital-card');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});