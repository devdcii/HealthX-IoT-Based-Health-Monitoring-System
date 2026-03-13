// Critical Alerts Page JavaScript

// Sidebar Toggle (reuse from dashboard)
const sidebar = document.getElementById('sidebar');
const sidebarToggle = document.getElementById('sidebarToggle');
const menuToggle = document.getElementById('menuToggle');

if(window.innerWidth > 768) {
    if(localStorage.getItem('sidebarCollapsed') === 'true') {
        sidebar.classList.add('collapsed');
    }
}

if(sidebarToggle) {
    sidebarToggle.addEventListener('click', () => {
        sidebar.classList.toggle('collapsed');
        localStorage.setItem('sidebarCollapsed', sidebar.classList.contains('collapsed'));
    });
}

if(menuToggle) {
    menuToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        sidebar.classList.toggle('mobile-active');
        document.body.classList.toggle('sidebar-open');
    });
}

document.addEventListener('click', (e) => {
    if (window.innerWidth <= 768) {
        if (sidebar.classList.contains('mobile-active') && 
            !sidebar.contains(e.target) && 
            !menuToggle.contains(e.target)) {
            sidebar.classList.remove('mobile-active');
            document.body.classList.remove('sidebar-open');
        }
    }
});

if(sidebar) {
    sidebar.addEventListener('click', (e) => {
        e.stopPropagation();
    });
}

let resizeTimer;
window.addEventListener('resize', () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
        if (window.innerWidth > 768) {
            sidebar.classList.remove('mobile-active');
            document.body.classList.remove('sidebar-open');
            if(localStorage.getItem('sidebarCollapsed') === 'true') {
                sidebar.classList.add('collapsed');
            }
        } else {
            sidebar.classList.remove('collapsed');
        }
    }, 250);
});

document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', () => {
        if (window.innerWidth <= 768) {
            sidebar.classList.remove('mobile-active');
            document.body.classList.remove('sidebar-open');
        }
    });
});

// Chart.js Configuration
Chart.defaults.font.family = "'Inter', sans-serif";
Chart.defaults.font.size = 12;
Chart.defaults.color = '#6b6b6b';
Chart.defaults.plugins.legend.display = false;

const commonOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
        legend: { display: false },
        tooltip: {
            backgroundColor: 'rgba(24, 72, 160, 0.95)',
            titleColor: '#fff',
            bodyColor: '#fff',
            titleFont: { size: 14, weight: 'bold' },
            bodyFont: { size: 13 },
            padding: 15,
            cornerRadius: 10,
            displayColors: true
        }
    }
};

// Alert Types Chart
if(typeof alertsData !== 'undefined') {
    const alertTypesCtx = document.getElementById('alertTypesChart');
    if(alertTypesCtx) {
        new Chart(alertTypesCtx.getContext('2d'), {
            type: 'doughnut',
            data: {
                labels: ['Temperature', 'Heart Rate', 'SpO2', 'Blood Pressure'],
                datasets: [{
                    data: [alertsData.temp, alertsData.hr, alertsData.spo2, alertsData.bp],
                    backgroundColor: ['#F59E0B', '#EF4444', '#3B82F6', '#8B5CF6'],
                    borderWidth: 0,
                    hoverOffset: 15,
                    spacing: 3
                }]
            },
            options: {
                ...commonOptions,
                cutout: '65%',
                plugins: {
                    ...commonOptions.plugins,
                    legend: {
                        display: true,
                        position: 'bottom',
                        labels: { padding: 15, font: { size: 11, weight: '600' }, color: '#0f2336', usePointStyle: true, pointStyle: 'circle', boxWidth: 8 }
                    },
                    tooltip: {
                        ...commonOptions.plugins.tooltip,
                        callbacks: {
                            label: function(context) {
                                const value = context.parsed;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0;
                                return context.label + ': ' + value + ' (' + percentage + '%)';
                            }
                        }
                    }
                }
            }
        });
    }
}

// Severity Distribution Chart
const severityCtx = document.getElementById('severityChart');
if(severityCtx && typeof alertsData !== 'undefined') {
    const total = alertsData.temp + alertsData.hr + alertsData.spo2 + alertsData.bp;
    
    new Chart(severityCtx.getContext('2d'), {
        type: 'bar',
        data: {
            labels: ['Critical', 'Warning', 'Moderate'],
            datasets: [{
                label: 'Alert Count',
                data: [
                    Math.floor(total * 0.3),
                    Math.floor(total * 0.5),
                    Math.floor(total * 0.2)
                ],
                backgroundColor: ['rgba(239,68,68,0.8)', 'rgba(245,158,11,0.8)', 'rgba(59,130,246,0.8)'],
                borderRadius: 8,
                borderWidth: 0
            }]
        },
        options: {
            ...commonOptions,
            scales: {
                y: {
                    beginAtZero: true,
                    grid: { color: 'rgba(24,72,160,0.08)', drawBorder: false },
                    ticks: { font: { size: 11, weight: '600' }, color: '#0f2336', padding: 10, stepSize: 1 }
                },
                x: {
                    grid: { display: false, drawBorder: false },
                    ticks: { font: { size: 10, weight: '600' }, color: '#0f2336' }
                }
            }
        }
    });
}

// Modal Functions (matching dashboard.php)
function showPatientModal(button) {
    const patientData = JSON.parse(button.getAttribute('data-patient'));
    const modal = document.getElementById('patientModal');
    
    document.getElementById('modalAvatar').textContent = patientData.patient_name.charAt(0).toUpperCase();
    document.getElementById('modalPatientName').textContent = patientData.patient_name;
    document.getElementById('modalWorker').textContent = patientData.worker_email.split('@')[0];
    
    const timestamp = new Date(patientData.timestamp).toLocaleString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
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
                <i class="fas fa-weight" style="display: none;"></i>
                BMI
            </div>
            <div class="modal-vital-value">${parseFloat(patientData.bmi).toFixed(1)}</div>
            <span class="modal-vital-status ${categorizeBMI(patientData.bmi).class}">
                ${categorizeBMI(patientData.bmi).category}
            </span>
        </div>
        
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/body-temperature.png" alt="Temperature" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-thermometer-half" style="display: none;"></i>
                Temperature
            </div>
            <div class="modal-vital-value">${parseFloat(patientData.temperature).toFixed(1)}°C</div>
            <span class="modal-vital-status ${categorizeTemp(patientData.temperature).class}">
                ${categorizeTemp(patientData.temperature).category}
            </span>
        </div>
        
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/heart-rate.png" alt="Heart Rate" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-heartbeat" style="display: none;"></i>
                Heart Rate
            </div>
            <div class="modal-vital-value">${patientData.heart_rate} bpm</div>
            <span class="modal-vital-status ${categorizeHR(patientData.heart_rate).class}">
                ${categorizeHR(patientData.heart_rate).category}
            </span>
        </div>
        
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/oxygen-saturation.png" alt="SpO2" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-lungs" style="display: none;"></i>
                SpO2
            </div>
            <div class="modal-vital-value">${patientData.spo2}%</div>
            <span class="modal-vital-status ${categorizeSpO2(patientData.spo2).class}">
                ${categorizeSpO2(patientData.spo2).category}
            </span>
        </div>
        
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/blood-pressure.png" alt="Blood Pressure" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-stethoscope" style="display: none;"></i>
                Blood Pressure
            </div>
            <div class="modal-vital-value">${patientData.systolic}/${patientData.diastolic}</div>
            <span class="modal-vital-status ${categorizeBP(patientData.systolic, patientData.diastolic).class}">
                ${categorizeBP(patientData.systolic, patientData.diastolic).category}
            </span>
        </div>
        
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/height.png" alt="Height" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-ruler-vertical" style="display: none;"></i>
                Height
            </div>
            <div class="modal-vital-value">${parseFloat(patientData.height).toFixed(2)} cm</div>
            <span class="modal-vital-status normal">Recorded</span>
        </div>
        
        <div class="modal-vital-card">
            <div class="modal-vital-label">
                <img src="../images/weight.png" alt="Weight" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                <i class="fas fa-weight-scale" style="display: none;"></i>
                Weight
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
    const modal = document.getElementById('patientModal');
    modal.classList.remove('active');
    document.body.style.overflow = '';
}

document.addEventListener('click', (e) => {
    const modal = document.getElementById('patientModal');
    if (e.target === modal) {
        closeModal();
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeModal();
    }
});

// Active nav highlighting
const currentPage = window.location.pathname.split('/').pop();
document.querySelectorAll('.nav-item').forEach(item => {
    const href = item.getAttribute('href');
    if(href === currentPage || (currentPage === '' && href === 'alerts.php')) {
        item.classList.add('active');
    }
});

// Animation on scroll
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
    const animatedElements = document.querySelectorAll('.stat-card, .vital-card, .chart-card, .alert-card');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});