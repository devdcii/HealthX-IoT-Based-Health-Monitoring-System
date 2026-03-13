// Health Workers Page JavaScript - Matching dashboard.php design

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
    if (window.innerWidth <= 768 && sidebar.classList.contains('mobile-active') && 
        !sidebar.contains(e.target) && !menuToggle.contains(e.target)) {
        sidebar.classList.remove('mobile-active');
        document.body.classList.remove('sidebar-open');
    }
});

if(sidebar) sidebar.addEventListener('click', (e) => e.stopPropagation());

let resizeTimer;
window.addEventListener('resize', () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => {
        if (window.innerWidth > 768) {
            sidebar.classList.remove('mobile-active');
            document.body.classList.remove('sidebar-open');
            if(localStorage.getItem('sidebarCollapsed') === 'true') sidebar.classList.add('collapsed');
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

// ─── Chart.js Global Defaults ────────────────────────────────────────────────
Chart.defaults.font.family = "'Inter', sans-serif";
Chart.defaults.font.size = 12;
Chart.defaults.color = '#6b6b6b';

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
            cornerRadius: 10
        }
    }
};

// ─── Critical Alerts Handled (horizontal bar) ───────────────────────────────
if(typeof alertsData !== 'undefined' && alertsData.length > 0) {
    const alertsCtx = document.getElementById('alertsHandledChart');
    if(alertsCtx) {
        new Chart(alertsCtx.getContext('2d'), {
            type: 'bar',
            data: {
                labels: alertsData.map(w => w.email.split('@')[0].substring(0, 15)),
                datasets: [{
                    label: 'Critical Alerts',
                    data: alertsData.map(w => w.alerts_handled),
                    backgroundColor: '#e74c3c',
                    borderRadius: 8,
                    borderSkipped: false
                }]
            },
            options: {
                ...commonOptions,
                indexAxis: 'y',
                scales: {
                    x: {
                        beginAtZero: true,
                        grid: { color: 'rgba(231, 76, 60, 0.08)', drawBorder: false },
                        ticks: { font: { size: 11, weight: '600' }, color: '#0f2336' }
                    },
                    y: {
                        grid: { display: false, drawBorder: false },
                        ticks: { font: { size: 10, weight: '600' }, color: '#0f2336' }
                    }
                }
            }
        });
    }
}

// ─── Activity Status Doughnut ─────────────────────────────────────────────────
if(typeof activeWorkers !== 'undefined' && typeof inactiveWorkers !== 'undefined') {
    const activityCtx = document.getElementById('activityChart');
    if(activityCtx) {
        new Chart(activityCtx.getContext('2d'), {
            type: 'doughnut',
            data: {
                labels: ['Active', 'Inactive'],
                datasets: [{
                    data: [activeWorkers, inactiveWorkers],
                    backgroundColor: ['#10b981', '#64748B'],
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
                    }
                }
            }
        });
    }
}

// ─── Active Nav Item ─────────────────────────────────────────────────────────
const currentPage = window.location.pathname.split('/').pop();
document.querySelectorAll('.nav-item').forEach(item => {
    const href = item.getAttribute('href');
    if(href === currentPage) item.classList.add('active');
});

// ─── Scroll-in Animation ─────────────────────────────────────────────────────
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
    const animatedElements = document.querySelectorAll('.stat-card, .chart-card');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});