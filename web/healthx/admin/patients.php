<?php
// patients.php - FIXED VERSION with proper timezone handling
require_once __DIR__ . '/admin_auth.php';
require_once('../config/dbcon.php');

// [Keep all helper functions - same as before]
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

// ✅ FIXED: Fetch All Patients with PH time conversion
$patients = [];
$patientsQuery = $conn->query(
    "SELECT u.id as id, u.email as email, u.name as name, 
            DATE_ADD(u.created_at, INTERVAL 8 HOUR) as registered_at,
            COUNT(hr.id) as total_readings,
            MAX(DATE_ADD(hr.timestamp, INTERVAL 8 HOUR)) as last_reading,
            MIN(DATE_ADD(hr.created_at, INTERVAL 8 HOUR)) as first_reading_at,
            AVG(hr.bmi) as avg_bmi,
            AVG(hr.heart_rate) as avg_heart_rate,
            AVG(hr.spo2) as avg_spo2
     FROM users u
     LEFT JOIN health_readings hr ON u.email = hr.user_email COLLATE utf8mb4_unicode_ci
     GROUP BY u.id, u.email, u.name, u.created_at
     ORDER BY u.name ASC"
);
while($row = $patientsQuery->fetch_assoc()) {
    $row['total_readings'] = intval($row['total_readings']);
    $row['avg_bmi'] = $row['avg_bmi'] !== null ? (float)$row['avg_bmi'] : 0.0;
    $row['avg_heart_rate'] = $row['avg_heart_rate'] !== null ? (float)$row['avg_heart_rate'] : 0;
    $row['avg_spo2'] = $row['avg_spo2'] !== null ? (float)$row['avg_spo2'] : 0.0;
    $patients[] = $row;
}

// ✅ FIXED: Get selected patient details with PH time
$selectedPatient = null;
$patientReadings = [];
if(isset($_GET['patient_email'])) {
    $patient_email = $_GET['patient_email'];
    
    // Get patient from readings first
    $stmt = $conn->prepare("
        SELECT user_email as email, patient_name as name, 
               MIN(DATE_ADD(created_at, INTERVAL 8 HOUR)) as created_at
        FROM health_readings 
        WHERE user_email = ? 
        GROUP BY user_email, patient_name
    ");
    $stmt->bind_param("s", $patient_email);
    $stmt->execute();
    $result = $stmt->get_result();
    $selectedPatient = $result->fetch_assoc();
    $stmt->close();
    
    // Fallback to users table
    if(!$selectedPatient) {
        $stmt = $conn->prepare("
            SELECT email, name, DATE_ADD(created_at, INTERVAL 8 HOUR) as created_at 
            FROM users 
            WHERE email = ? 
            LIMIT 1
        ");
        $stmt->bind_param("s", $patient_email);
        $stmt->execute();
        $result = $stmt->get_result();
        $selectedPatient = $result->fetch_assoc();
        $stmt->close();
    }
    
    // Fetch readings with PH time
    $stmt = $conn->prepare("
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
        WHERE user_email = ?
        ORDER BY timestamp DESC
    ");
    $stmt->bind_param("s", $patient_email);
    $stmt->execute();
    $result = $stmt->get_result();
    while($row = $result->fetch_assoc()) {
        $row['bmi_cat'] = categorizeBMI($row['bmi']);
        $row['temp_cat'] = categorizeTemperature($row['temperature']);
        $row['hr_cat'] = categorizeHeartRate($row['heart_rate']);
        $row['spo2_cat'] = categorizeSpO2($row['spo2']);
        $row['bp_cat'] = categorizeBP($row['systolic'], $row['diastolic']);
        $patientReadings[] = $row;
    }
    $stmt->close();
}

// Statistics (no changes needed)
$activeThisMonth = 0;
$totalReadings = 0;
foreach($patients as $p) {
    $totalReadings += $p['total_readings'];
    if($p['last_reading'] && strtotime($p['last_reading']) >= strtotime('-30 days')) {
        $activeThisMonth++;
    }
}

$atRiskPatients = $conn->query("
    SELECT COUNT(DISTINCT user_email) as at_risk_count
    FROM health_readings
    WHERE (temperature > 38.0 OR temperature < 36.0)
       OR (heart_rate > 100 OR heart_rate < 60)
       OR (spo2 < 95)
       OR (systolic > 140 OR systolic < 90)
       OR (diastolic > 90 OR diastolic < 60)
")->fetch_assoc();
$atRiskCount = $atRiskPatients['at_risk_count'] ?? 0;

// Critical Vital Distribution (no changes needed)
$criticalVitalStats = $conn->query("
    SELECT 
        SUM(CASE WHEN systolic > 140 OR systolic < 90 OR diastolic > 90 OR diastolic < 60 THEN 1 ELSE 0 END) as bp_critical,
        SUM(CASE WHEN spo2 < 95 THEN 1 ELSE 0 END) as spo2_critical,
        SUM(CASE WHEN heart_rate > 100 OR heart_rate < 60 THEN 1 ELSE 0 END) as hr_critical,
        SUM(CASE WHEN temperature > 38.0 OR temperature < 36.0 THEN 1 ELSE 0 END) as temp_critical
    FROM health_readings
")->fetch_assoc();

$bpCritical = $criticalVitalStats['bp_critical'] ?? 0;
$spo2Critical = $criticalVitalStats['spo2_critical'] ?? 0;
$hrCritical = $criticalVitalStats['hr_critical'] ?? 0;
$tempCritical = $criticalVitalStats['temp_critical'] ?? 0;

// Ensure notification column exists
$colResult = $conn->query("SHOW COLUMNS FROM users LIKE 'notification_viewed'");
if(!$colResult || $colResult->num_rows === 0) {
    @$conn->query("ALTER TABLE users ADD COLUMN notification_viewed TINYINT(1) NOT NULL DEFAULT 0");
}

// Handle AJAX for notification viewing (no changes needed)
if(isset($_POST['mark_viewed']) && isset($_POST['notification_ids'])) {
    $ids = json_decode($_POST['notification_ids'], true);
    if(is_array($ids) && count($ids) > 0) {
        $placeholders = str_repeat('?,', count($ids) - 1) . '?';
        $stmt = $conn->prepare("UPDATE users SET notification_viewed = 1 WHERE id IN ($placeholders)");
        $types = str_repeat('i', count($ids));
        $stmt->bind_param($types, ...$ids);
        $stmt->execute();
        $stmt->close();
    }
    echo json_encode(['success' => true]);
    exit;
}

// ✅ FIXED: Get notifications with PH time
$notifications_result = $conn->query("
    SELECT id, name, email, 
           DATE_ADD(created_at, INTERVAL 8 HOUR) as created_at, 
           notification_viewed 
    FROM users 
    WHERE notification_viewed = 0 
    ORDER BY created_at DESC
");
$notifications = [];
while($row = $notifications_result->fetch_assoc()) {
    $notifications[] = $row;
}

$unviewedCount = $conn->query("SELECT COUNT(*) as count FROM users WHERE notification_viewed = 0")->fetch_assoc()['count'];
$admin_username = $_SESSION['admin_username'] ?? 'Admin';
?>

<!-- Keep ALL your existing HTML code exactly as is - no changes needed -->

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthX - Patients</title>
    <link rel="icon" type="image/png" href="../images/logo.png">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../css/admin_style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <!-- Sidebar -->
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
                <a href="patients.php" class="nav-item active">
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
                <a href="readings.php" class="nav-item">
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
                    <h1>Patients</h1>
                    <p class="subtitle">Monitor and manage patient health records</p>
                </div>
            </div>
            <div class="top-bar-right">
                <div class="quick-stats">
                    <div class="quick-stat">
                        <i class="fas fa-clock"></i>
                        <span><?php echo date('l, F j, Y'); ?></span>
                    </div>
                </div>

                <!-- Patient Notifications -->
                <button class="notification-btn" id="patientNotificationBtn" aria-label="Patient Notifications">
                    <i class="fas fa-user-plus"></i>
                    <?php if(!empty($unviewedCount) && $unviewedCount > 0): ?>
                        <span class="badge"><?php echo $unviewedCount; ?></span>
                    <?php endif; ?>
                </button>

                <!-- Notifications Dropdown -->
                <div class="notifications-dropdown" id="patientNotificationsDropdown">
                    <div class="notifications-header">
                        <h3>New Patients</h3>
                        <button class="close-notifications" id="closePatientNotifications" aria-label="Close notifications"><i class="fas fa-times"></i></button>
                    </div>
                    <div class="notifications-body">
                        <?php if(count($notifications) > 0): ?>
                            <?php foreach($notifications as $notif): ?>
                                <div class="notification-item <?php echo $notif['notification_viewed'] ? 'viewed' : 'unviewed'; ?>" data-id="<?php echo $notif['id']; ?>">
                                    <div class="notification-icon"><i class="fas fa-user"></i></div>
                                    <div class="notification-content">
                                        <h4><?php echo htmlspecialchars($notif['name']); ?></h4>
                                        <p><?php echo htmlspecialchars($notif['email']); ?></p>
                                        <span class="notification-time"><?php echo date('M d, g:i A', strtotime($notif['created_at'])); ?></span>
                                    </div>
                                    <?php if(!$notif['notification_viewed']): ?>
                                        <div class="notification-badge-dot"></div>
                                    <?php endif; ?>
                                </div>
                            <?php endforeach; ?>
                        <?php else: ?>
                            <div class="notification-empty">
                                <i class="fas fa-check-circle"></i>
                                <p>No new patients</p>
                            </div>
                        <?php endif; ?>
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

            <!-- Statistics Cards -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <img src="../images/team.png" alt="Patients" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-users" style="display: none;"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Total Patients</h3>
                        <div class="stat-value"><?php echo number_format(count($patients)); ?></div>
                        <p class="stat-description">Registered patients</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#patients-table">View all <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-user-check"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Active This Month</h3>
                        <div class="stat-value"><?php echo number_format($activeThisMonth); ?></div>
                        <p class="stat-description">Last 30 days</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#patients-table">View details <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-heartbeat"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Total Readings</h3>
                        <div class="stat-value"><?php echo number_format($totalReadings); ?></div>
                        <p class="stat-description">All patients</p>
                    </div>
                    <div class="stat-footer">
                        <a href="readings.php">View data <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-user-injured"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>At-Risk Patients</h3>
                        <div class="stat-value"><?php echo number_format($atRiskCount); ?></div>
                        <p class="stat-description">Require attention</p>
                    </div>
                    <div class="stat-footer">
                        <a href="alerts.php">View alerts <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>
            </div>

            <!-- Charts Section -->
            <div class="charts-container">
                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-chart-pie"></i> Critical Vital Distribution</h2>
                                <p>Most frequent critical vital signs</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="criticalVitalsChart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-chart-bar"></i> Activity Status</h2>
                                <p>Last 30 days</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="activityChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Patients Table -->
            <div class="table-section" id="patients-table">
                <div class="section-header">
                    <h2><i class="fas fa-users"></i> All Patients</h2>
                </div>
                <div class="table-container">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Patient</th>
                                <th>Email</th>
                                <th>Total Readings</th>
                                <th>Avg BMI</th>
                                <th>Avg HR</th>
                                <th>Avg SpO2</th>
                                <th>Last Reading</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($patients as $patient): ?>
                            <tr>
                                <td>
                                    <div class="patient-cell">
                                        <div class="patient-avatar"><?php echo strtoupper(substr($patient['name'], 0, 1)); ?></div>
                                        <strong><?php echo htmlspecialchars($patient['name']); ?></strong>
                                    </div>
                                </td>
                                <td><?php echo htmlspecialchars($patient['email']); ?></td>
                                <td><strong><?php echo number_format($patient['total_readings']); ?></strong></td>
                                <td><?php echo number_format((float)$patient['avg_bmi'], 1); ?></td>
                                <td><?php echo number_format((int)$patient['avg_heart_rate'], 0); ?> bpm</td>
                                <td><?php echo number_format((float)$patient['avg_spo2'], 1); ?>%</td>
                                <td><?php echo $patient['last_reading'] ? date('M d, Y', strtotime($patient['last_reading'])) : 'Never'; ?></td>
                                <td>
                                    <div class="action-buttons" style="display:flex;gap:0.5rem;align-items:center;justify-content:flex-end;">
                                        <a href="?patient_email=<?php echo urlencode($patient['email']); ?>" class="icon-btn btn-view" title="View patient" aria-label="View patient">
                                            <i class="fas fa-eye"></i>
                                        </a>
                                        <button type="button" class="icon-btn btn-edit btn-edit-patient" data-user-id="<?php echo $patient['id']; ?>" data-user-name="<?php echo htmlspecialchars($patient['name'], ENT_QUOTES); ?>" data-user-email="<?php echo htmlspecialchars($patient['email'], ENT_QUOTES); ?>" title="Edit patient" aria-label="Edit patient">
                                            <i class="fas fa-edit"></i>
                                        </button>
                                        <button type="button" class="icon-btn btn-delete btn-delete-patient" data-user-id="<?php echo $patient['id']; ?>" data-user-name="<?php echo htmlspecialchars($patient['name'], ENT_QUOTES); ?>" data-user-email="<?php echo htmlspecialchars($patient['email'], ENT_QUOTES); ?>" title="Delete patient" aria-label="Delete patient">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>

    <?php if($selectedPatient): ?>
    <!-- Patient Details Modal -->
    <div class="modal-overlay active" id="patientModal">
        <div class="modal-container" style="max-width: 900px; max-height: 90vh; overflow-y: auto;">
            <div class="modal-header">
                <h2><i class="fas fa-user-circle"></i> Patient: <?php echo htmlspecialchars($selectedPatient['name']); ?></h2>
                <a href="patients.php" class="modal-close" style="text-decoration: none; color: white;">
                    <i class="fas fa-times"></i>
                </a>
            </div>
            <div class="modal-body">
                <div class="modal-patient-info">
                    <div class="modal-patient-header">
                        <div class="modal-patient-avatar"><?php echo strtoupper(substr($selectedPatient['name'], 0, 1)); ?></div>
                        <div class="modal-patient-details">
                            <h3><?php echo htmlspecialchars($selectedPatient['name']); ?></h3>
                            <div class="modal-patient-meta">
                                <span><i class="fas fa-envelope"></i> <?php echo htmlspecialchars($selectedPatient['email']); ?></span>
                                <span><i class="fas fa-calendar"></i> Registered: <?php echo date('M d, Y', strtotime($selectedPatient['created_at'])); ?></span>
                                <span><i class="fas fa-heartbeat"></i> Total Readings: <?php echo count($patientReadings); ?></span>
                            </div>
                        </div>
                    </div>
                </div>

                <h3 style="margin: 1.5rem 0 1rem 0;"><i class="fas fa-history"></i> Reading History</h3>
                
                <?php if(count($patientReadings) > 0): ?>
                    <?php foreach($patientReadings as $reading): ?>
                    <div style="background: white; border: 2px solid var(--gray-200); border-radius: 12px; padding: 1.5rem; margin-bottom: 1rem;">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; flex-wrap: wrap; gap: 0.5rem;">
                            <div>
                                <strong style="font-size: 1.1rem;"><?php echo date('F d, Y', strtotime($reading['timestamp'])); ?></strong><br>
                                <small style="color: var(--muted);"><?php echo date('h:i A', strtotime($reading['timestamp'])); ?></small>
                            </div>
                            <span style="background: var(--primary); color: white; padding: 0.5rem 1rem; border-radius: 20px; font-size: 0.85rem;">
                                <i class="fas fa-user-md"></i> <?php echo htmlspecialchars(explode('@', $reading['worker_email'])[0]); ?>
                            </span>
                        </div>
                        
                        <div class="modal-vitals-grid">
                            <div class="modal-vital-card">
                                <div class="modal-vital-label">
                                    <img src="../images/body-mass-index.png" alt="BMI" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                                    <i class="fas fa-weight" style="display: none;"></i>
                                    BMI
                                </div>
                                <div class="modal-vital-value"><?php echo number_format($reading['bmi'], 1); ?></div>
                                <span class="modal-vital-status <?php echo $reading['bmi_cat']['class']; ?>">
                                    <?php echo $reading['bmi_cat']['category']; ?>
                                </span>
                                <small style="font-size: 0.75rem; color: var(--muted); margin-top: 0.5rem;">
                                    <?php echo number_format($reading['weight'], 1); ?>kg / <?php echo number_format($reading['height'], 0); ?>cm
                                </small>
                            </div>

                            <div class="modal-vital-card">
                                <div class="modal-vital-label">
                                    <img src="../images/heart-rate.png" alt="Heart Rate" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                                    <i class="fas fa-heartbeat" style="display: none;"></i>
                                    Heart Rate
                                </div>
                                <div class="modal-vital-value"><?php echo $reading['heart_rate']; ?> bpm</div>
                                <span class="modal-vital-status <?php echo $reading['hr_cat']['class']; ?>">
                                    <?php echo $reading['hr_cat']['category']; ?>
                                </span>
                            </div>

                            <div class="modal-vital-card">
                                <div class="modal-vital-label">
                                    <img src="../images/oxygen-saturation.png" alt="SpO2" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                                    <i class="fas fa-lungs" style="display: none;"></i>
                                    SpO2
                                </div>
                                <div class="modal-vital-value"><?php echo $reading['spo2']; ?>%</div>
                                <span class="modal-vital-status <?php echo $reading['spo2_cat']['class']; ?>">
                                    <?php echo $reading['spo2_cat']['category']; ?>
                                </span>
                            </div>

                            <div class="modal-vital-card">
                                <div class="modal-vital-label">
                                    <img src="../images/body-temperature.png" alt="Temperature" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                                    <i class="fas fa-thermometer-half" style="display: none;"></i>
                                    Temperature
                                </div>
                                <div class="modal-vital-value"><?php echo number_format($reading['temperature'], 1); ?>°C</div>
                                <span class="modal-vital-status <?php echo $reading['temp_cat']['class']; ?>">
                                    <?php echo $reading['temp_cat']['category']; ?>
                                </span>
                            </div>

                            <div class="modal-vital-card">
                                <div class="modal-vital-label">
                                    <img src="../images/blood-pressure.png" alt="Blood Pressure" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-block';">
                                    <i class="fas fa-stethoscope" style="display: none;"></i>
                                    Blood Pressure
                                </div>
                                <div class="modal-vital-value"><?php echo $reading['systolic']; ?>/<?php echo $reading['diastolic']; ?></div>
                                <span class="modal-vital-status <?php echo $reading['bp_cat']['class']; ?>">
                                    <?php echo $reading['bp_cat']['category']; ?>
                                </span>
                            </div>
                        </div>
                    </div>
                    <?php endforeach; ?>
                <?php else: ?>
                    <p style="text-align: center; padding: 2rem; color: var(--muted);">No readings recorded yet</p>
                <?php endif; ?>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <!-- Edit Patient Modal -->
    <div class="modal-overlay" id="editPatientModal" style="display:none;">
        <div class="modal-container" style="max-width:480px;">
            <div class="modal-header">
                <h2><i class="fas fa-user-edit"></i> Edit Patient</h2>
                <button class="modal-close" id="closeEditPatient" aria-label="Close" style="border:none;background:transparent;color:white;font-size:1.1rem;"><i class="fas fa-times"></i></button>
            </div>
            <div class="modal-body">
                <form id="editPatientForm">
                    <input type="hidden" name="user_id" id="edit_user_id" value="">
                    <input type="hidden" name="old_email" id="edit_old_email" value="">
                    <div style="margin-bottom:0.75rem;">
                        <label for="edit_name" style="display:block;font-weight:600;margin-bottom:6px;">Full Name</label>
                        <input type="text" id="edit_name" name="name" class="input-field" style="width:100%;padding:0.6rem;border-radius:8px;border:1px solid var(--gray-200);">
                    </div>
                    <div style="margin-bottom:0.75rem;">
                        <label for="edit_email" style="display:block;font-weight:600;margin-bottom:6px;">Email</label>
                        <input type="email" id="edit_email" name="email" class="input-field" style="width:100%;padding:0.6rem;border-radius:8px;border:1px solid var(--gray-200);">
                    </div>
                    <div style="display:flex;gap:0.5rem;justify-content:flex-end;margin-top:1rem;">
                        <button type="button" id="cancelEditPatient" class="btn btn-secondary" style="padding:0.5rem 0.9rem;border-radius:8px;background:var(--gray-200);border:none;color:#0f2336;">Cancel</button>
                        <button type="submit" id="saveEditPatient" class="btn btn-primary" style="padding:0.5rem 0.9rem;border-radius:8px;background:var(--primary);border:none;color:white;">Save Changes</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        const criticalVitalsData = {
            bp: <?php echo $bpCritical; ?>,
            spo2: <?php echo $spo2Critical; ?>,
            hr: <?php echo $hrCritical; ?>,
            temp: <?php echo $tempCritical; ?>
        };
        const activeCount = <?php echo $activeThisMonth; ?>;
        const inactiveCount = <?php echo count($patients) - $activeThisMonth; ?>;
    </script>
    <script src="../js/patients_notifications.js"></script>
    <script src="../js/patients.js"></script>
</body>
</html>