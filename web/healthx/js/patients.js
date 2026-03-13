// ===================================
// PATIENTS.JS - WITH SIMPLE BROWSER CONFIRMS (LOCALHOST STYLE)
// ===================================

const sidebar = document.getElementById('sidebar');
const sidebarToggle = document.getElementById('sidebarToggle');
const menuToggle = document.getElementById('menuToggle');

// Sidebar state
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

// ==================== CHARTS ====================
if(typeof Chart !== 'undefined') {
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

    // Critical Vital Distribution Chart
    if(typeof criticalVitalsData !== 'undefined') {
        const criticalVitalsCtx = document.getElementById('criticalVitalsChart');
        if(criticalVitalsCtx) {
            const total = criticalVitalsData.bp + criticalVitalsData.spo2 + criticalVitalsData.hr + criticalVitalsData.temp;
            
            new Chart(criticalVitalsCtx.getContext('2d'), {
                type: 'doughnut',
                data: {
                    labels: ['Blood Pressure', 'SpO2', 'Heart Rate', 'Temperature'],
                    datasets: [{
                        data: [
                            criticalVitalsData.bp,
                            criticalVitalsData.spo2,
                            criticalVitalsData.hr,
                            criticalVitalsData.temp
                        ],
                        backgroundColor: ['#8B5CF6', '#3B82F6', '#EF4444', '#F59E0B'],
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
                            labels: { 
                                padding: 15, 
                                font: { size: 11, weight: '600' }, 
                                color: '#0f2336', 
                                usePointStyle: true, 
                                pointStyle: 'circle', 
                                boxWidth: 8 
                            }
                        },
                        tooltip: {
                            ...commonOptions.plugins.tooltip,
                            callbacks: {
                                label: function(context) {
                                    const value = context.parsed;
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

    // Activity Status Chart
    if(typeof activeCount !== 'undefined' && typeof inactiveCount !== 'undefined') {
        const activityCtx = document.getElementById('activityChart');
        if(activityCtx) {
            new Chart(activityCtx.getContext('2d'), {
                type: 'doughnut',
                data: {
                    labels: ['Active (Last 30 days)', 'Inactive'],
                    datasets: [{
                        data: [activeCount, inactiveCount],
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
                            labels: { 
                                padding: 15, 
                                font: { size: 11, weight: '600' }, 
                                color: '#0f2336', 
                                usePointStyle: true, 
                                pointStyle: 'circle', 
                                boxWidth: 8 
                            }
                        }
                    }
                }
            });
        }
    }
}

// ==================== EDIT MODAL FUNCTIONS ====================
function openEditModal(id, name, email) {
    console.log('✅ Opening edit modal:', { id, name, email });
    document.getElementById('edit_user_id').value = id;
    document.getElementById('edit_old_email').value = email;
    document.getElementById('edit_name').value = name;
    document.getElementById('edit_email').value = email;
    const modal = document.getElementById('editPatientModal');
    modal.style.display = 'flex';
    modal.classList.add('active');
}

function closeEditModal() {
    const modal = document.getElementById('editPatientModal');
    modal.style.display = 'none';
    modal.classList.remove('active');
    document.getElementById('editPatientForm').reset();
}

// ==================== DELETE FUNCTION - SIMPLE BROWSER CONFIRM ====================
function deletePatient(button, event) {
    if(event) event.stopPropagation(); // Prevent row click
    
    const userId = button.getAttribute('data-user-id');
    const userName = button.getAttribute('data-user-name');
    const userEmail = button.getAttribute('data-user-email');
    
    console.log('🗑️ Delete button clicked:', { userId, userName, userEmail });
    
    // Simple browser confirm dialog (localhost style)
    if(confirm('Are you sure you want to delete ' + userName + ' (' + userEmail + ')? This action cannot be undone!')) {
        console.log('🗑️ Deleting patient ID:', userId);
        
        // Disable button
        button.disabled = true;
        button.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
        
        // Send delete request
        fetch('../api/delete_patient.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ patient_id: parseInt(userId) })
        })
        .then(res => res.json())
        .then(json => {
            console.log('🗑️ Delete response:', json);
            
            if (json.success) {
                // Remove table row with animation
                const row = button.closest('tr');
                if (row) {
                    row.style.transition = 'opacity 0.3s ease';
                    row.style.opacity = '0';
                    setTimeout(() => row.remove(), 300);
                }
                
                // Show success alert
                alert(json.message || 'Patient deleted successfully!');
            } else {
                alert(json.message || 'Failed to delete patient');
                button.disabled = false;
                button.innerHTML = '<i class="fas fa-trash"></i>';
            }
        })
        .catch(err => {
            console.error('❌ Delete error:', err);
            alert('Error deleting patient');
            button.disabled = false;
            button.innerHTML = '<i class="fas fa-trash"></i>';
        });
    }
}

// ==================== INITIALIZE ON PAGE LOAD ====================
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 Patients.js loaded!');

    // ===== EDIT MODAL SETUP =====
    const editModal = document.getElementById('editPatientModal');
    const editForm = document.getElementById('editPatientForm');
    
    // Close buttons
    document.getElementById('closeEditPatient')?.addEventListener('click', closeEditModal);
    document.getElementById('cancelEditPatient')?.addEventListener('click', closeEditModal);

    // Edit form submission
    if (editForm) {
        editForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const user_id = document.getElementById('edit_user_id').value;
            const name = document.getElementById('edit_name').value.trim();
            const email = document.getElementById('edit_email').value.trim();
            const old_email = document.getElementById('edit_old_email').value;

            if (!name || !email) {
                alert('Name and email are required');
                return;
            }

            const saveBtn = document.getElementById('saveEditPatient');
            saveBtn.disabled = true;
            saveBtn.textContent = 'Saving...';

            try {
                const res = await fetch('../api/update_profile.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        action: 'update_profile',
                        user_id: parseInt(user_id),
                        name,
                        email,
                        old_email
                    })
                });

                const json = await res.json();
                console.log('📝 Update response:', json);

                if (json.success) {
                    // Update table row
                    const row = document.querySelector(`.btn-edit-patient[data-user-id="${user_id}"]`)?.closest('tr');
                    if (row) {
                        row.querySelector('.patient-cell strong').textContent = name;
                        row.querySelector('.patient-avatar').textContent = name.charAt(0).toUpperCase();
                        row.querySelector('td:nth-child(2)').textContent = email;
                        
                        row.querySelector('.btn-edit-patient').setAttribute('data-user-name', name);
                        row.querySelector('.btn-edit-patient').setAttribute('data-user-email', email);
                        row.querySelector('.btn-delete-patient').setAttribute('data-user-name', name);
                        row.querySelector('.btn-delete-patient').setAttribute('data-user-email', email);
                        
                        const viewLink = row.querySelector('a[href^="?patient_email="]');
                        if (viewLink) viewLink.setAttribute('href', '?patient_email=' + encodeURIComponent(email));
                    }

                    alert(json.message || 'Patient updated successfully!');
                    closeEditModal();
                } else {
                    alert(json.message || 'Failed to update patient');
                }
            } catch (err) {
                console.error('❌ Update error:', err);
                alert('Error updating patient');
            } finally {
                saveBtn.disabled = false;
                saveBtn.textContent = 'Save Changes';
            }
        });
    }

    // ===== CRITICAL: EVENT DELEGATION FOR BUTTONS =====
    document.addEventListener('click', function(e) {
        // Check if EDIT button was clicked
        const editBtn = e.target.closest('.btn-edit-patient');
        if (editBtn) {
            e.preventDefault();
            e.stopPropagation();
            
            const id = editBtn.getAttribute('data-user-id');
            const name = editBtn.getAttribute('data-user-name');
            const email = editBtn.getAttribute('data-user-email');
            
            console.log('🖊️ Edit button clicked:', { id, name, email });
            openEditModal(id, name, email);
            return false;
        }

        // Check if DELETE button was clicked
        const deleteBtn = e.target.closest('.btn-delete-patient');
        if (deleteBtn) {
            e.preventDefault();
            e.stopPropagation();
            
            deletePatient(deleteBtn, e);
            return false;
        }
    });

    // Close edit modal on overlay click
    if (editModal) {
        editModal.addEventListener('click', (e) => {
            if (e.target === editModal) {
                closeEditModal();
            }
        });
    }

    // Close modals on ESC key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeEditModal();
        }
    });

    // Animations
    const animatedElements = document.querySelectorAll('.stat-card, .chart-card');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        setTimeout(() => {
            el.style.opacity = '1';
            el.style.transform = 'translateY(0)';
        }, 100);
    });

    console.log('✅ Edit and Delete buttons are ready!');
});

console.log('✅ Patients.js fully initialized!');