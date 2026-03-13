// Patients Notifications - toggle dropdown and mark new patients as viewed

const patientNotificationBtn = document.getElementById('patientNotificationBtn');
const patientNotificationsDropdown = document.getElementById('patientNotificationsDropdown');
const closePatientNotifications = document.getElementById('closePatientNotifications');

if (patientNotificationBtn) {
    patientNotificationBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        patientNotificationsDropdown.classList.toggle('active');

        // If opened, mark unviewed notifications as viewed
        if (patientNotificationsDropdown.classList.contains('active')) {
            const unviewedNotifs = document.querySelectorAll('.notification-item.unviewed');
            if (unviewedNotifs.length > 0) {
                const ids = Array.from(unviewedNotifs).map(el => el.dataset.id);

                fetch('patients.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: 'mark_viewed=1&notification_ids=' + encodeURIComponent(JSON.stringify(ids))
                }).then(() => {
                    unviewedNotifs.forEach(el => {
                        el.classList.remove('unviewed');
                        el.classList.add('viewed');
                        const dot = el.querySelector('.notification-badge-dot');
                        if (dot) dot.remove();
                    });

                    // Remove badge on button
                    const badgeEl = document.querySelector('.notification-btn .badge');
                    if (badgeEl) badgeEl.remove();

                    // Remove any sidebar nav badges for patients
                    document.querySelectorAll('.nav-item .nav-badge').forEach(b => b.remove());
                }).catch(err => {
                    console.error('Failed to mark patient notifications viewed', err);
                });
            }
        }
    });
}

if (closePatientNotifications) {
    closePatientNotifications.addEventListener('click', function(e) {
        e.stopPropagation();
        patientNotificationsDropdown.classList.remove('active');
    });
}

// Close when clicking outside
document.addEventListener('click', function(e) {
    if (patientNotificationsDropdown && patientNotificationBtn) {
        if (!patientNotificationsDropdown.contains(e.target) && !patientNotificationBtn.contains(e.target)) {
            patientNotificationsDropdown.classList.remove('active');
        }
    }
});