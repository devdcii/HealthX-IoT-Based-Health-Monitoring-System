// Inquiries Page JavaScript
// NOTE: sidebar, commonOptions, nav highlighting, and chart defaults
// are already handled by admin_script.js — do NOT redeclare them here.

// ==================== CHARTS ====================
if(typeof statusData !== 'undefined') {
    const statusCtx = document.getElementById('statusChart');
    if(statusCtx) {
        new Chart(statusCtx.getContext('2d'), {
            type: 'doughnut',
            data: {
                labels: ['New', 'Read', 'Responded'],
                datasets: [{
                    data: [statusData.new, statusData.read, statusData.responded],
                    backgroundColor: ['#F59E0B', '#3B82F6', '#10B981'],
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

    const responseCtx = document.getElementById('responseChart');
    if(responseCtx) {
        const total = statusData.new + statusData.read + statusData.responded;
        const responseRate = total > 0 ? ((statusData.responded / total) * 100).toFixed(1) : 0;
        new Chart(responseCtx.getContext('2d'), {
            type: 'bar',
            data: {
                labels: ['Response Rate'],
                datasets: [{
                    label: 'Percentage',
                    data: [responseRate],
                    backgroundColor: '#10b981',
                    borderRadius: 8
                }]
            },
            options: {
                ...commonOptions,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        ticks: { callback: v => v + '%', font: { size: 11, weight: '600' }, color: '#0f2336' },
                        grid: { color: 'rgba(24,72,160,0.08)', drawBorder: false }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { font: { size: 11, weight: '600' }, color: '#0f2336' }
                    }
                }
            }
        });
    }
}

// ==================== HELPER FUNCTIONS ====================
function escapeHtml(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
}

// ==================== VIEW INQUIRY MODAL ====================
function viewInquiry(button, event) {
    if(event) event.stopPropagation(); // Prevent row click
    const inquiry = JSON.parse(button.getAttribute('data-inquiry'));
    const modal = document.getElementById('viewModal');

    const formattedDate = new Date(inquiry.created_at).toLocaleDateString('en-US', {
        year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit'
    });

    document.getElementById('inquiryDetails').innerHTML = `
        <div class="modal-patient-info">
            <h3 style="margin-bottom: 1rem;">Contact Information</h3>
            <p><strong>Name:</strong> ${escapeHtml(inquiry.full_name)}</p>
            <p><strong>Email:</strong> ${escapeHtml(inquiry.email)}</p>
            <p><strong>Date:</strong> ${formattedDate}</p>
        </div>
        <div style="margin: 1.5rem 0;">
            <h3 style="margin-bottom: 0.5rem;">Subject</h3>
            <p>${escapeHtml(inquiry.subject)}</p>
        </div>
        <div>
            <h3 style="margin-bottom: 0.5rem;">Message</h3>
            <p style="line-height: 1.6; white-space: pre-wrap;">${escapeHtml(inquiry.message)}</p>
        </div>
    `;

    document.getElementById('inquiryActions').innerHTML = `
        <form method="POST" action="inquiries.php" style="display: flex; gap: 1rem; width: 100%;">
            <input type="hidden" name="inquiry_id" value="${parseInt(inquiry.id)}">
            <select name="status" style="flex: 1; padding: 0.7rem; border: 2px solid var(--gray-200); border-radius: 8px; font-weight: 600;" required>
                <option value="new" ${inquiry.status === 'new' ? 'selected' : ''}>New</option>
                <option value="read" ${inquiry.status === 'read' ? 'selected' : ''}>Read</option>
                <option value="responded" ${inquiry.status === 'responded' ? 'selected' : ''}>Responded</option>
            </select>
            <button type="submit" name="update_status" class="modal-btn modal-btn-primary">
                <i class="fas fa-save"></i> Update Status
            </button>
            <button type="button" onclick="closeInquiryModal()" class="modal-btn modal-btn-secondary">
                <i class="fas fa-times"></i> Close
            </button>
        </form>
    `;

    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeInquiryModal() {
    document.getElementById('viewModal').classList.remove('active');
    document.body.style.overflow = '';
}

// ==================== REPLY INQUIRY MODAL ====================
function replyInquiry(button, event) {
    if(event) event.stopPropagation(); // Prevent row click
    const inquiry = JSON.parse(button.getAttribute('data-inquiry'));
    const modal = document.getElementById('replyModal');
    
    document.getElementById('replyInquiryId').value = inquiry.id;
    document.getElementById('replyCustomerEmail').value = inquiry.email;
    document.getElementById('replyCustomerName').value = inquiry.full_name;
    document.getElementById('replyToInfo').textContent = `${inquiry.full_name} (${inquiry.email})`;
    document.getElementById('replySubject').value = 'Re: ' + inquiry.subject;
    document.getElementById('replyMessage').value = '';
    
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeReplyModal() {
    document.getElementById('replyModal').classList.remove('active');
    document.body.style.overflow = '';
}

// ==================== DELETE INQUIRY - SIMPLE BROWSER CONFIRM ====================
function deleteInquiry(button, event) {
    if(event) event.stopPropagation(); // Prevent row click
    const inquiry = JSON.parse(button.getAttribute('data-inquiry'));
    
    // Simple browser confirm dialog (localhost style)
    if(confirm('Are you sure you want to delete the inquiry from ' + inquiry.full_name + '? This action cannot be undone!')) {
        // Create and submit form
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = 'inquiries.php';
        
        const inquiryIdInput = document.createElement('input');
        inquiryIdInput.type = 'hidden';
        inquiryIdInput.name = 'inquiry_id';
        inquiryIdInput.value = inquiry.id;
        
        const deleteInput = document.createElement('input');
        deleteInput.type = 'hidden';
        deleteInput.name = 'delete_inquiry';
        deleteInput.value = '1';
        
        form.appendChild(inquiryIdInput);
        form.appendChild(deleteInput);
        document.body.appendChild(form);
        form.submit();
    }
}

// ==================== MODAL OVERLAY CLICK HANDLERS ====================
document.getElementById('viewModal').addEventListener('click', function(e) {
    if (e.target.id === 'viewModal') closeInquiryModal();
});

document.getElementById('replyModal').addEventListener('click', function(e) {
    if (e.target.id === 'replyModal') closeReplyModal();
});

// ==================== KEYBOARD HANDLERS ====================
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        if (document.getElementById('viewModal').classList.contains('active')) {
            closeInquiryModal();
        }
        if (document.getElementById('replyModal').classList.contains('active')) {
            closeReplyModal();
        }
    }
});

// ==================== FORM CONFIRMATION - SIMPLE BROWSER CONFIRM ====================
document.getElementById('replyForm').addEventListener('submit', function(e) {
    const email = document.getElementById('replyCustomerEmail').value;
    const name = document.getElementById('replyCustomerName').value;
    
    if(!confirm('Send reply to ' + name + ' (' + email + ')?')) {
        e.preventDefault();
    }
});

// ==================== NOTIFICATIONS ====================
const notificationBtn = document.getElementById('notificationBtn');
const notificationsDropdown = document.getElementById('notificationsDropdown');
const closeNotifications = document.getElementById('closeNotifications');

if (notificationBtn) {
    notificationBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        notificationsDropdown.classList.toggle('active');
        
        // Mark notifications as viewed when dropdown is opened
        if (notificationsDropdown.classList.contains('active')) {
            const unviewedNotifs = document.querySelectorAll('.notification-item.unviewed');
            if(unviewedNotifs.length > 0) {
                const ids = Array.from(unviewedNotifs).map(el => el.dataset.id);
                
                fetch('inquiries.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: 'mark_viewed=1&notification_ids=' + encodeURIComponent(JSON.stringify(ids))
                }).then(() => {
                    unviewedNotifs.forEach(el => {
                        el.classList.remove('unviewed');
                        el.classList.add('viewed');
                        const badge = el.querySelector('.notification-badge-dot');
                        if(badge) badge.remove();
                    });
                    
                    const badgeEl = document.querySelector('.notification-btn .badge');
                    if(badgeEl) {
                        badgeEl.remove();
                    }
                });
            }
        }
    });
}

if (closeNotifications) {
    closeNotifications.addEventListener('click', function(e) {
        e.stopPropagation();
        notificationsDropdown.classList.remove('active');
    });
}

// Close notifications when clicking outside
document.addEventListener('click', function(e) {
    if (!notificationsDropdown.contains(e.target) && !notificationBtn.contains(e.target)) {
        notificationsDropdown.classList.remove('active');
    }
});