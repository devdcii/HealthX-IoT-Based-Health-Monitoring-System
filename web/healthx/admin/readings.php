<?php
// readings.php - FIXED VERSION with proper timezone handling
require_once __DIR__ . '/admin_auth.php';
require_once('../config/dbcon.php');

// Handle delete request (no changes needed)
if(isset($_POST['delete_reading'])) {
    $id = intval($_POST['reading_id']);
    $stmt = $conn->prepare("DELETE FROM health_readings WHERE id = ?");
    $stmt->bind_param("i", $id);
    if($stmt->execute()) {
        $_SESSION['success_message'] = "Reading deleted successfully";
    } else {
        $_SESSION['error_message'] = "Failed to delete reading";
    }
    $stmt->close();
    header('Location: readings.php');
    exit;
}

// [Keep all your helper functions - same as dashboard.php]
function categorizeBMI($bmi) {
    if ($bmi < 18.5) return ['category' => 'Underweight', 'class' => 'low'];
    if ($bmi < 25.0) return ['category' => 'Normal', 'class' => 'normal'];
    if ($bmi < 30.0) return ['category' => 'Overweight', 'class' => 'elevated'];
    if ($bmi < 35.0) return ['category' => 'Obesity Class I', 'class' => 'high'];
    if ($bmi < 40.0) return ['category' => 'Obesity Class II', 'class' => 'critical'];
    return ['category' => 'Obesity Class III', 'class' => 'critical'];
}

function categorizeTemperature($temp) {
    if ($temp < 35.0) return ['category' => 'Hypothermia', 'class' => 'critical'];
    if ($temp < 36.5) return ['category' => 'Slightly Low', 'class' => 'low'];
    if ($temp < 37.6) return ['category' => 'Normal', 'class' => 'normal'];
    if ($temp < 38.1) return ['category' => 'Low-grade Fever', 'class' => 'elevated'];
    if ($temp < 39.1) return ['category' => 'Fever', 'class' => 'high'];
    return ['category' => 'High Fever', 'class' => 'critical'];
}

function categorizeHeartRate($hr) {
    if ($hr < 50) return ['category' => 'Bradycardia', 'class' => 'critical'];
    if ($hr < 60) return ['category' => 'Low (Athletic)', 'class' => 'low'];
    if ($hr <= 100) return ['category' => 'Normal', 'class' => 'normal'];
    if ($hr <= 120) return ['category' => 'Elevated', 'class' => 'elevated'];
    return ['category' => 'Tachycardia', 'class' => 'critical'];
}

function categorizeSpO2($spo2) {
    if ($spo2 < 90) return ['category' => 'Hypoxemia', 'class' => 'critical'];
    if ($spo2 < 93) return ['category' => 'Low', 'class' => 'high'];
    if ($spo2 < 95) return ['category' => 'Slightly Low', 'class' => 'elevated'];
    return ['category' => 'Normal', 'class' => 'normal'];
}

function categorizeBP($systolic, $diastolic) {
    if ($systolic > 180 || $diastolic > 120) return ['category' => 'Hypertensive Crisis', 'class' => 'critical'];
    if ($systolic >= 140 || $diastolic >= 90) return ['category' => 'Stage 2 Hypertension', 'class' => 'high'];
    if ($systolic >= 130 || $diastolic >= 80) return ['category' => 'Stage 1 Hypertension', 'class' => 'elevated'];
    if ($systolic >= 120 && $diastolic < 80) return ['category' => 'Elevated', 'class' => 'elevated'];
    return ['category' => 'Normal', 'class' => 'normal'];
}

// Pagination
$page = isset($_GET['page_num']) ? intval($_GET['page_num']) : 1;
$perPage = 20;
$offset = ($page - 1) * $perPage;

$totalReadings = $conn->query("SELECT COUNT(*) FROM health_readings")->fetch_row()[0];
$totalPages = ceil($totalReadings / $perPage);

// ✅ FIXED: Fetch readings with PH time conversion
$readings = [];
$readingsQuery = $conn->query("
    SELECT 
        id,
        worker_email,
        user_email,
        patient_name,
        weight,
        height,
        bmi,
        heart_rate,
        spo2,
        temperature,
        systolic,
        diastolic,
        DATE_ADD(timestamp, INTERVAL 8 HOUR) as timestamp,
        DATE_ADD(created_at, INTERVAL 8 HOUR) as created_at
    FROM health_readings
    ORDER BY timestamp DESC
    LIMIT $perPage OFFSET $offset
");
while($row = $readingsQuery->fetch_assoc()) {
    $row['bmi_cat'] = categorizeBMI($row['bmi']);
    $row['temp_cat'] = categorizeTemperature($row['temperature']);
    $row['hr_cat'] = categorizeHeartRate($row['heart_rate']);
    $row['spo2_cat'] = categorizeSpO2($row['spo2']);
    $row['bp_cat'] = categorizeBP($row['systolic'], $row['diastolic']);
    $readings[] = $row;
}

// Statistics (no changes needed - uses CURDATE() which is UTC)
$todayReadings = $conn->query("SELECT COUNT(*) FROM health_readings WHERE DATE(timestamp) = CURDATE()")->fetch_row()[0];
$weekReadings = $conn->query("SELECT COUNT(*) FROM health_readings WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)")->fetch_row()[0];
$monthReadings = $conn->query("SELECT COUNT(*) FROM health_readings WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)")->fetch_row()[0];

// Health Readings Summary (no changes needed - stat calculations)
$statusStats = $conn->query("
    SELECT
        SUM(
            temperature BETWEEN 36.5 AND 37.5
            AND heart_rate BETWEEN 60 AND 100
            AND spo2 >= 95
            AND systolic < 120 AND diastolic < 80
        ) AS normal_count,
        SUM(
            temperature >= 37.6 OR heart_rate > 100 OR spo2 < 95
            OR systolic >= 120 OR diastolic >= 80
        ) AS elevated_count,
        SUM(
            temperature >= 39 OR heart_rate >= 120 OR spo2 < 90
            OR systolic >= 140 OR diastolic >= 90
        ) AS critical_count,
        COUNT(*) AS total_count
    FROM health_readings
    WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)
")->fetch_assoc();

$admin_username = $_SESSION['admin_username'] ?? 'Admin';
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthX - Health Readings</title>
    <link rel="icon" type="image/png" href="../images/logo.png">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../css/admin_style.css">
</head>
<body>
    <!-- Sidebar (unchanged) -->
    <aside class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <div class="logo">
                <img src="../images/flogo.png" alt="HealthX Logo" class="logo-img" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                <div class="logo-icon" style="display: none;">
                    <i class="fas fa-heartbeat"></i>
                </div>
                <div class="logo-content">
                    <span class="logo-text">HealthX</span>
                </div>
            </div>
            <button class="sidebar-toggle" id="sidebarToggle">
                <i class="fas fa-angle-left"></i>
            </button>
        </div>
        
        <nav class="sidebar-nav">
            <div class="nav-section">
                <span class="nav-section-title">Main</span>
                <a href="dashboard.php" class="nav-item">
                    <div class="nav-icon"><i class="fas fa-chart-line"></i></div>
                    <span class="nav-text">Dashboard</span>
                </a>
                <a href="patients.php" class="nav-item">
                    <div class="nav-icon"><i class="fas fa-users"></i></div>
                    <span class="nav-text">Patients</span>
                </a>
                <a href="health_workers.php" class="nav-item">
                    <div class="nav-icon"><i class="fas fa-user-md"></i></div>
                    <span class="nav-text">Health Workers</span>
                </a>
            </div>
            
            <div class="nav-section">
                <span class="nav-section-title">Data</span>
                <a href="readings.php" class="nav-item active">
                    <div class="nav-icon"><i class="fas fa-heartbeat"></i></div>
                    <span class="nav-text">Health Readings</span>
                </a>
                <a href="alerts.php" class="nav-item">
                    <div class="nav-icon"><i class="fas fa-exclamation-triangle"></i></div>
                    <span class="nav-text">Critical Alerts</span>
                </a>
                <a href="inquiries.php" class="nav-item">
                    <div class="nav-icon"><i class="fas fa-inbox"></i></div>
                    <span class="nav-text">Inquiries</span>
                </a>
            </div>
        </nav>
        
        <div class="sidebar-footer">
            <a href="logout.php" class="logout-btn">
                <i class="fas fa-sign-out-alt"></i>
                <span class="logout-text">Logout</span>
            </a>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="main-content">
        <header class="top-bar">
            <div class="top-bar-left">
                <button class="mobile-toggle" id="menuToggle">
                    <i class="fas fa-bars"></i>
                </button>
                <div class="page-title">
                    <h1>Health Readings</h1>
                    <p class="subtitle">Complete health monitoring records</p>
                </div>
            </div>
            <div class="top-bar-right">
                <div class="quick-stats">
                    <div class="quick-stat">
                        <i class="fas fa-clock"></i>
                        <span><?php echo date('l, F j, Y'); ?></span>
                    </div>
                </div>
            </div>
        </header>

        <div class="dashboard-content">
            <!-- Success/Error Messages as JavaScript Alerts -->
            <?php if(isset($_SESSION['success_message'])): ?>
                <script>
                    alert('<?php echo addslashes($_SESSION['success_message']); ?>');
                </script>
                <?php unset($_SESSION['success_message']); ?>
            <?php endif; ?>
            
            <?php if(isset($_SESSION['error_message'])): ?>
                <script>
                    alert('<?php echo addslashes($_SESSION['error_message']); ?>');
                </script>
                <?php unset($_SESSION['error_message']); ?>
            <?php endif; ?>

            <!-- Statistics Cards (unchanged) -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-heartbeat"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Total Readings</h3>
                        <div class="stat-value"><?php echo number_format($totalReadings); ?></div>
                        <p class="stat-description">All time records</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#readings-table">View all <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-calendar-day"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Today's Readings</h3>
                        <div class="stat-value"><?php echo number_format($todayReadings); ?></div>
                        <p class="stat-description">Last 24 hours</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#readings-table">View details <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-calendar-week"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>This Week</h3>
                        <div class="stat-value"><?php echo number_format($weekReadings); ?></div>
                        <p class="stat-description">Last 7 days</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#readings-table">View data <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-calendar-alt"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>This Month</h3>
                        <div class="stat-value"><?php echo number_format($monthReadings); ?></div>
                        <p class="stat-description">Last 30 days</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#readings-table">Details <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>
            </div>

            <!-- Health Readings Summary (unchanged) -->
            <div class="vitals-overview">
                <div class="section-header">
                    <h2><i class="fas fa-chart-pie"></i> Health Readings Summary (Last 30 Days)</h2>
                </div>
                <div class="vitals-grid">
                    <div class="vital-card">
                        <div class="vital-icon" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">
                            <i class="fas fa-check-circle" style="color: white; font-size: 1.8rem;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Normal Readings</span>
                            <span class="vital-value"><?php echo number_format($statusStats['normal_count'] ?? 0); ?></span>
                            <span class="vital-status normal">Stable Condition</span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon" style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);">
                            <i class="fas fa-exclamation-circle" style="color: white; font-size: 1.8rem;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Elevated Readings</span>
                            <span class="vital-value"><?php echo number_format($statusStats['elevated_count'] ?? 0); ?></span>
                            <span class="vital-status elevated">Needs Attention</span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon" style="background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);">
                            <i class="fas fa-exclamation-triangle" style="color: white; font-size: 1.8rem;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Critical Readings</span>
                            <span class="vital-value"><?php echo number_format($statusStats['critical_count'] ?? 0); ?></span>
                            <span class="vital-status critical">High Risk</span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon" style="background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);">
                            <i class="fas fa-database" style="color: white; font-size: 1.8rem;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Total Monitored</span>
                            <span class="vital-value"><?php echo number_format($statusStats['total_count'] ?? 0); ?></span>
                            <span class="vital-status normal">Last 30 Days</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Readings Table with Delete Button -->
            <div class="table-section" id="readings-table">
                <div class="section-header">
                    <h2><i class="fas fa-list"></i> All Health Readings</h2>
                    <span style="color: var(--muted); font-weight: 600; font-size: 0.9rem;">
                        Page <?php echo $page; ?> of <?php echo $totalPages; ?>
                    </span>
                </div>
                <div class="table-container">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Patient</th>
                                <th>BMI</th>
                                <th>Temperature</th>
                                <th>Heart Rate</th>
                                <th>SpO2</th>
                                <th>Blood Pressure</th>
                                <th>Worker</th>
                                <th>Date</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($readings as $reading): ?>
                            <tr>
                                <td>
                                    <div class="patient-cell">
                                        <div class="patient-avatar"><?php echo strtoupper(substr($reading['patient_name'], 0, 1)); ?></div>
                                        <strong><?php echo htmlspecialchars($reading['patient_name']); ?></strong>
                                    </div>
                                </td>
                                <td>
                                    <div class="reading-cell">
                                        <span class="reading-value"><?php echo number_format($reading['bmi'], 1); ?></span>
                                        <span class="reading-category <?php echo $reading['bmi_cat']['class']; ?>">
                                            <?php echo $reading['bmi_cat']['category']; ?>
                                        </span>
                                    </div>
                                </td>
                                <td>
                                    <div class="reading-cell">
                                        <span class="reading-value"><?php echo number_format($reading['temperature'], 1); ?>°C</span>
                                        <span class="reading-category <?php echo $reading['temp_cat']['class']; ?>">
                                            <?php echo $reading['temp_cat']['category']; ?>
                                        </span>
                                    </div>
                                </td>
                                <td>
                                    <div class="reading-cell">
                                        <span class="reading-value"><?php echo $reading['heart_rate']; ?> bpm</span>
                                        <span class="reading-category <?php echo $reading['hr_cat']['class']; ?>">
                                            <?php echo $reading['hr_cat']['category']; ?>
                                        </span>
                                    </div>
                                </td>
                                <td>
                                    <div class="reading-cell">
                                        <span class="reading-value"><?php echo $reading['spo2']; ?>%</span>
                                        <span class="reading-category <?php echo $reading['spo2_cat']['class']; ?>">
                                            <?php echo $reading['spo2_cat']['category']; ?>
                                        </span>
                                    </div>
                                </td>
                                <td>
                                    <div class="reading-cell">
                                        <span class="reading-value"><?php echo $reading['systolic']; ?>/<?php echo $reading['diastolic']; ?></span>
                                        <span class="reading-category <?php echo $reading['bp_cat']['class']; ?>">
                                            <?php echo $reading['bp_cat']['category']; ?>
                                        </span>
                                    </div>
                                </td>
                                <td><?php echo htmlspecialchars(explode('@', $reading['worker_email'])[0]); ?></td>
                                <td><?php echo date('M d, H:i', strtotime($reading['timestamp'])); ?></td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="icon-btn btn-view" 
                                                data-patient='<?php echo json_encode($reading); ?>'
                                                onclick="showPatientModal(this)"
                                                title="View details"
                                                aria-label="View details">
                                            <i class="fas fa-eye"></i>
                                        </button>
                                        <button class="icon-btn btn-delete"
                                                data-reading-id="<?php echo $reading['id']; ?>"
                                                data-patient-name="<?php echo htmlspecialchars($reading['patient_name']); ?>"
                                                data-reading-date="<?php echo date('M d, Y H:i', strtotime($reading['timestamp'])); ?>"
                                                onclick="deleteReading(this)"
                                                title="Delete reading"
                                                aria-label="Delete reading">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>

                <!-- Pagination (unchanged) -->
                <?php if($totalPages > 1): ?>
                <div style="display: flex; gap: 0.5rem; justify-content: center; margin-top: 2rem; flex-wrap: wrap;">
                    <?php if($page > 1): ?>
                        <a href="?page_num=<?php echo $page - 1; ?>" style="padding: 0.6rem 1rem; border: 2px solid var(--gray-200); background: white; color: var(--text-dark); text-decoration: none; border-radius: 8px; transition: all 0.3s; font-weight: 600;">
                            <i class="fas fa-chevron-left"></i> Previous
                        </a>
                    <?php endif; ?>
                    
                    <?php for($i = max(1, $page - 2); $i <= min($totalPages, $page + 2); $i++): ?>
                        <a href="?page_num=<?php echo $i; ?>" style="padding: 0.6rem 1rem; border: 2px solid <?php echo $i === $page ? 'var(--primary)' : 'var(--gray-200)'; ?>; background: <?php echo $i === $page ? 'var(--primary)' : 'white'; ?>; color: <?php echo $i === $page ? 'white' : 'var(--text-dark)'; ?>; text-decoration: none; border-radius: 8px; transition: all 0.3s; font-weight: 600;">
                            <?php echo $i; ?>
                        </a>
                    <?php endfor; ?>
                    
                    <?php if($page < $totalPages): ?>
                        <a href="?page_num=<?php echo $page + 1; ?>" style="padding: 0.6rem 1rem; border: 2px solid var(--gray-200); background: white; color: var(--text-dark); text-decoration: none; border-radius: 8px; transition: all 0.3s; font-weight: 600;">
                            Next <i class="fas fa-chevron-right"></i>
                        </a>
                    <?php endif; ?>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </main>

    <!-- Modal for Reading Details (unchanged) -->
    <div class="modal-overlay" id="patientModal">
        <div class="modal-container">
            <div class="modal-header">
                <h2><i class="fas fa-user-injured"></i> Reading Details</h2>
                <button class="modal-close" onclick="closeModal()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="modal-body">
                <div class="modal-patient-info">
                    <div class="modal-patient-header">
                        <div class="modal-patient-avatar" id="modalAvatar">P</div>
                        <div class="modal-patient-details">
                            <h3 id="modalPatientName">Patient Name</h3>
                            <div class="modal-patient-meta">
                                <span><i class="fas fa-user-md"></i> <span id="modalWorker">Worker</span></span>
                                <span><i class="fas fa-clock"></i> <span id="modalTime">Time</span></span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal-vitals-grid" id="modalVitals">
                    <!-- Vitals populated by JavaScript -->
                </div>
            </div>
            <div class="modal-footer">
                <button class="modal-btn modal-btn-secondary" onclick="closeModal()">Close</button>
            </div>
        </div>
    </div>

    <script>
        const readingsData = <?php echo json_encode($readings); ?>;
        
        // Simple delete function with browser confirm (like inquiries.php)
        function deleteReading(button) {
            const readingId = button.getAttribute('data-reading-id');
            const patientName = button.getAttribute('data-patient-name');
            const readingDate = button.getAttribute('data-reading-date');
            
            // Simple browser confirm dialog (localhost style)
            if(confirm('Are you sure you want to delete the reading for ' + patientName + ' from ' + readingDate + '? This action cannot be undone!')) {
                // Create and submit form
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = 'readings.php';
                
                const readingIdInput = document.createElement('input');
                readingIdInput.type = 'hidden';
                readingIdInput.name = 'reading_id';
                readingIdInput.value = readingId;
                
                const deleteInput = document.createElement('input');
                deleteInput.type = 'hidden';
                deleteInput.name = 'delete_reading';
                deleteInput.value = '1';
                
                form.appendChild(readingIdInput);
                form.appendChild(deleteInput);
                document.body.appendChild(form);
                form.submit();
            }
        }
    </script>
    
    <!-- Your existing JavaScript (NO CHANGES NEEDED) -->
    <script src="../js/readings.js"></script>
</body>
</html>