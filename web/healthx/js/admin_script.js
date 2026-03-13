// HealthX Dashboard - Enhanced JavaScript with Modal and Fixed Charts

// ==================== SIDEBAR & MENU ====================
const sidebar = document.getElementById('sidebar');
const sidebarToggle = document.getElementById('sidebarToggle');
const menuToggle = document.getElementById('menuToggle');

// Check localStorage for sidebar state (desktop only)
if(window.innerWidth > 768) {
    if(localStorage.getItem('sidebarCollapsed') === 'true') {
        sidebar.classList.add('collapsed');
    }
}

// Desktop sidebar toggle
if(sidebarToggle) {
    sidebarToggle.addEventListener('click', () => {
        sidebar.classList.toggle('collapsed');
        localStorage.setItem('sidebarCollapsed', sidebar.classList.contains('collapsed'));
    });
}

// Mobile menu toggle
if(menuToggle) {
    menuToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        sidebar.classList.toggle('mobile-active');
        document.body.classList.toggle('sidebar-open');
    });
}

// Close sidebar on outside click (mobile)
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

// Prevent clicks inside sidebar from closing it
if(sidebar) {
    sidebar.addEventListener('click', (e) => {
        e.stopPropagation();
    });
}

// Handle window resize
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

// Close mobile menu when clicking nav items
document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', () => {
        if (window.innerWidth <= 768) {
            sidebar.classList.remove('mobile-active');
            document.body.classList.remove('sidebar-open');
        }
    });
});

// ==================== CHART.JS CONFIGURATION ====================
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

// ==================== HOURLY ACTIVITY CHART (7AM - 5PM) ====================
if(typeof hourlyData !== 'undefined') {
    const hourlyCtx = document.getElementById('hourlyChart');
    if(hourlyCtx) {
        // Filter for 7AM to 5PM only
        const workHours = [];
        for(let i = 7; i <= 17; i++) {
            const found = hourlyData.find(d => parseInt(d.hour) === i);
            workHours.push({ hour: i, count: found ? parseInt(found.count) : 0 });
        }

        const gradient = hourlyCtx.getContext('2d').createLinearGradient(0, 0, 0, 300);
        gradient.addColorStop(0, 'rgba(24, 72, 160, 0.3)');
        gradient.addColorStop(1, 'rgba(24, 72, 160, 0.01)');

        new Chart(hourlyCtx.getContext('2d'), {
            type: 'line',
            data: {
                labels: workHours.map(d => {
                    const hour = d.hour;
                    const ampm = hour >= 12 ? 'PM' : 'AM';
                    const displayHour = hour % 12 || 12;
                    return `${displayHour} ${ampm}`;
                }),
                datasets: [{
                    label: 'Readings',
                    data: workHours.map(d => d.count),
                    borderColor: '#1848a0',
                    backgroundColor: gradient,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 4,
                    pointBackgroundColor: '#1848a0',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointHoverRadius: 6
                }]
            },
            options: {
                ...commonOptions,
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(24, 72, 160, 0.08)', drawBorder: false },
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
}

// ==================== WEEKLY TREND CHART (FIXED) ====================
if(typeof weeklyData !== 'undefined' && weeklyData.length > 0) {
    const weeklyCtx = document.getElementById('weeklyChart');
    if(weeklyCtx) {
        const gradient = weeklyCtx.getContext('2d').createLinearGradient(0, 0, 0, 200);
        gradient.addColorStop(0, 'rgba(16, 185, 129, 0.3)');
        gradient.addColorStop(1, 'rgba(16, 185, 129, 0.01)');

        new Chart(weeklyCtx.getContext('2d'), {
            type: 'line',
            data: {
                labels: weeklyData.map(item => {
                    const date = new Date(item.date);
                    return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
                }),
                datasets: [{
                    label: 'Readings',
                    data: weeklyData.map(item => parseInt(item.count)),
                    borderColor: '#10b981',
                    backgroundColor: gradient,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 5,
                    pointBackgroundColor: '#10b981',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointHoverRadius: 7
                }]
            },
            options: {
                ...commonOptions,
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(16, 185, 129, 0.08)', drawBorder: false },
                        ticks: { font: { size: 11, weight: '600' }, color: '#0f2336', stepSize: 1 }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { font: { size: 10, weight: '600' }, color: '#0f2336' }
                    }
                }
            }
        });
    }
}

// ==================== BMI DISTRIBUTION CHART ====================
if(typeof bmiDistribution !== 'undefined') {
    const bmiCtx = document.getElementById('bmiChart');
    if(bmiCtx) {
        new Chart(bmiCtx.getContext('2d'), {
            type: 'doughnut',
            data: {
                labels: ['Underweight', 'Normal', 'Overweight', 'Obese'],
                datasets: [{
                    data: [bmiDistribution.underweight, bmiDistribution.normal, bmiDistribution.overweight, bmiDistribution.obese],
                    backgroundColor: ['#06b6d4', '#10b981', '#f59e0b', '#ef4444'],
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

// ==================== BLOOD PRESSURE CHART ====================
if(typeof bpDistribution !== 'undefined') {
    const bpCtx = document.getElementById('bpChart');
    if(bpCtx) {
        new Chart(bpCtx.getContext('2d'), {
            type: 'bar',
            data: {
                labels: ['Normal', 'Elevated', 'Stage 1', 'Stage 2', 'Crisis'],
                datasets: [{
                    label: 'Patients',
                    data: [bpDistribution.normal, bpDistribution.elevated, bpDistribution.stage1, bpDistribution.stage2, bpDistribution.crisis],
                    backgroundColor: ['rgba(16,185,129,0.8)', 'rgba(245,158,11,0.8)', 'rgba(249,115,22,0.8)', 'rgba(239,68,68,0.8)', 'rgba(153,27,27,0.8)'],
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
                        ticks: { font: { size: 11, weight: '600' }, color: '#0f2336', stepSize: 1 }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { font: { size: 10, weight: '600' }, color: '#0f2336' }
                    }
                }
            }
        });
    }
}

// ==================== TEMPERATURE DISTRIBUTION (POLAR AREA) ====================
if(typeof tempDistribution !== 'undefined') {
    const tempCtx = document.getElementById('tempChart');
    if(tempCtx) {
        new Chart(tempCtx.getContext('2d'), {
            type: 'polarArea',
            data: {
                labels: ['Hypothermia', 'Low', 'Normal', 'Fever', 'High Fever'],
                datasets: [{
                    data: [tempDistribution.hypothermia, tempDistribution.low, tempDistribution.normal, tempDistribution.fever, tempDistribution.high_fever],
                    backgroundColor: ['rgba(59,130,246,0.7)', 'rgba(6,182,212,0.7)', 'rgba(16,185,129,0.7)', 'rgba(245,158,11,0.7)', 'rgba(239,68,68,0.7)'],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                ...commonOptions,
                plugins: {
                    ...commonOptions.plugins,
                    legend: {
                        display: true,
                        position: 'bottom',
                        labels: { padding: 10, font: { size: 9, weight: '600' }, color: '#0f2336', boxWidth: 12 }
                    }
                },
                scales: {
                    r: { ticks: { display: false }, grid: { color: 'rgba(24,72,160,0.1)' } }
                }
            }
        });
    }
}

// ==================== HEART RATE DISTRIBUTION (POLAR AREA - LIKE TEMPERATURE) ====================
if(typeof hrDistribution !== 'undefined') {
    const hrCtx = document.getElementById('hrChart');
    if(hrCtx) {
        new Chart(hrCtx.getContext('2d'), {
            type: 'polarArea',
            data: {
                labels: ['Bradycardia', 'Low', 'Normal', 'Elevated', 'Tachycardia'],
                datasets: [{
                    data: [hrDistribution.bradycardia, hrDistribution.low, hrDistribution.normal, hrDistribution.elevated, hrDistribution.tachycardia],
                    backgroundColor: ['rgba(59,130,246,0.7)', 'rgba(6,182,212,0.7)', 'rgba(16,185,129,0.7)', 'rgba(245,158,11,0.7)', 'rgba(239,68,68,0.7)'],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                ...commonOptions,
                plugins: {
                    ...commonOptions.plugins,
                    legend: {
                        display: true,
                        position: 'bottom',
                        labels: { padding: 10, font: { size: 9, weight: '600' }, color: '#0f2336', boxWidth: 12 }
                    }
                },
                scales: {
                    r: { ticks: { display: false }, grid: { color: 'rgba(239,68,68,0.1)' } }
                }
            }
        });
    }
}

// ==================== SPO2 DISTRIBUTION ====================
if(typeof spo2Distribution !== 'undefined') {
    const spo2Ctx = document.getElementById('spo2Chart');
    if(spo2Ctx) {
        new Chart(spo2Ctx.getContext('2d'), {
            type: 'pie',
            data: {
                labels: ['Hypoxemia', 'Low', 'Slightly Low', 'Normal'],
                datasets: [{
                    data: [spo2Distribution.hypoxemia, spo2Distribution.low, spo2Distribution.slightly_low, spo2Distribution.normal],
                    backgroundColor: ['#ef4444', '#f97316', '#f59e0b', '#10b981'],
                    borderWidth: 2,
                    borderColor: '#fff',
                    hoverOffset: 10
                }]
            },
            options: {
                ...commonOptions,
                plugins: {
                    ...commonOptions.plugins,
                    legend: {
                        display: true,
                        position: 'bottom',
                        labels: { padding: 10, font: { size: 9, weight: '600' }, color: '#0f2336', boxWidth: 12 }
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

// ==================== MONTHLY TREND ====================
if(typeof monthlyData !== 'undefined' && monthlyData.length > 0) {
    const monthlyCtx = document.getElementById('monthlyChart');
    if(monthlyCtx) {
        const gradient = monthlyCtx.getContext('2d').createLinearGradient(0, 0, 0, 200);
        gradient.addColorStop(0, 'rgba(139, 92, 246, 0.3)');
        gradient.addColorStop(1, 'rgba(139, 92, 246, 0.01)');

        new Chart(monthlyCtx.getContext('2d'), {
            type: 'line',
            data: {
                labels: monthlyData.map(item => {
                    const date = new Date(item.month + '-01');
                    return date.toLocaleDateString('en-US', { month: 'short' });
                }),
                datasets: [{
                    label: 'Readings',
                    data: monthlyData.map(item => parseInt(item.count)),
                    borderColor: '#8b5cf6',
                    backgroundColor: gradient,
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 4,
                    pointBackgroundColor: '#8b5cf6',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2
                }]
            },
            options: {
                ...commonOptions,
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(139,92,246,0.08)', drawBorder: false },
                        ticks: { font: { size: 10, weight: '600' }, color: '#0f2336', stepSize: 1 }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { font: { size: 9, weight: '600' }, color: '#0f2336' }
                    }
                }
            }
        });
    }
}

// ==================== ACTIVE NAV HIGHLIGHTING ====================
const currentPage = window.location.pathname.split('/').pop();
document.querySelectorAll('.nav-item').forEach(item => {
    const href = item.getAttribute('href');
    if(href === currentPage || (currentPage === '' && href === 'dashboard.php')) {
        item.classList.add('active');
    }
});

// ==================== SMOOTH ANIMATIONS ====================
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

// ==================== MODAL FUNCTIONS ====================
function showPatientModal(button) {
    const patientData = JSON.parse(button.getAttribute('data-patient'));
    const modal = document.getElementById('patientModal');
    
    // Populate modal data
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
    
    // Helper functions
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
    
// Build vitals HTML
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
    
    // Show modal
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeModal() {
    const modal = document.getElementById('patientModal');
    modal.classList.remove('active');
    modal.classList.remove('printing');
    document.body.style.overflow = '';
}

// Close modal on overlay click
document.addEventListener('click', (e) => {
    const modal = document.getElementById('patientModal');
    if (e.target === modal) {
        closeModal();
    }
});

// Close modal on ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeModal();
    }
});

// ==================== REAL-TIME CLOCK ====================
function updateClock() {
    const now = new Date();
    const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    const clockElement = document.querySelector('.quick-stat span');
    if(clockElement) {
        clockElement.textContent = now.toLocaleDateString('en-US', options);
    }
}
setInterval(updateClock, 60000);
updateClock();

// ==================== STAT COUNTER ANIMATION ====================
function animateValue(element, start, end, duration) {
    const range = end - start;
    const increment = range / (duration / 16);
    let current = start;
    
    const timer = setInterval(() => {
        current += increment;
        if ((increment > 0 && current >= end) || (increment < 0 && current <= end)) {
            element.textContent = end.toLocaleString();
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(current).toLocaleString();
        }
    }, 16);
}

document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.stat-value').forEach(stat => {
        const finalValue = parseInt(stat.textContent.replace(/,/g, ''));
        if(!isNaN(finalValue)) {
            stat.textContent = '0';
            setTimeout(() => { animateValue(stat, 0, finalValue, 1500); }, 300);
        }
    });
});

// ==================== TABLE ROW CLICK ====================
document.querySelectorAll('.data-table tbody tr').forEach(row => {
    row.style.cursor = 'pointer';
    row.addEventListener('click', function(e) {
        // Ignore clicks on controls (buttons or links)
        if(!e.target.closest('button, a')) {
            const patientName = this.querySelector('.patient-cell strong').textContent;
            console.log('Viewing details for:', patientName);
        }
    });
});

// ==================== NOTIFICATION SYSTEM ====================
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 100px;
        right: 20px;
        background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#1848a0'};
        color: white;
        padding: 1rem 1.5rem;
        border-radius: 10px;
        box-shadow: 0 10px 25px rgba(0,0,0,0.2);
        z-index: 10000;
        animation: slideInRight 0.3s ease;
    `;
    document.body.appendChild(notification);
    setTimeout(() => {
        notification.style.animation = 'slideOutRight 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from { transform: translateX(400px); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
    @keyframes slideOutRight {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(400px); opacity: 0; }
    }
`;
document.head.appendChild(style);

// ==================== RESPONSIVE CHART RESIZE ====================
window.addEventListener('resize', () => {
    if(typeof Chart !== 'undefined' && Chart.instances) {
        Object.values(Chart.instances).forEach(chart => { 
            if(chart && chart.resize) chart.resize(); 
        });
    }
});

// ==================== CONSOLE INFO ====================
console.log('%c HealthX Monitoring System ', 'background: #1848a0; color: white; font-size: 16px; font-weight: bold; padding: 10px;');

