<?php
// dashboard.php - FIXED with proper timezone handling
require_once __DIR__ . '/admin_auth.php';
require_once('../config/dbcon.php');

// [Keep all your existing helper functions - categorizeBMI, categorizeTemperature, etc.]
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

// Ensure notification column exists
$colResult = $conn->query("SHOW COLUMNS FROM users LIKE 'notification_viewed'");
if(!$colResult || $colResult->num_rows === 0) {
    @$conn->query("ALTER TABLE users ADD COLUMN notification_viewed TINYINT(1) NOT NULL DEFAULT 0");
}

// ✅ FIXED: Get latest unviewed patient notifications with PH time
$dashboard_patient_notifications = [];
$patient_notifs_result = $conn->query("
    SELECT 
        id, 
        name, 
        email, 
        DATE_ADD(created_at, INTERVAL 8 HOUR) as created_at, 
        notification_viewed 
    FROM users 
    WHERE notification_viewed = 0 
    ORDER BY created_at DESC 
    LIMIT 6
");
while($row = $patient_notifs_result->fetch_assoc()) {
    $dashboard_patient_notifications[] = $row;
}
$dashboard_unviewed_count = $conn->query("SELECT COUNT(*) as count FROM users WHERE notification_viewed = 0")->fetch_assoc()['count'];

// ✅ FIXED: Fetch Statistics (queries use NOW() which is already in UTC due to dbcon.php)
$totalRegisteredPatients = $conn->query("SELECT COUNT(*) FROM users")->fetch_row()[0] ?? 0;
$totalActivePatients = $conn->query("SELECT COUNT(DISTINCT user_email) FROM health_readings")->fetch_row()[0] ?? 0;
$totalHealthWorkers = $conn->query("SELECT COUNT(DISTINCT worker_email) FROM health_readings")->fetch_row()[0] ?? 0;
$totalReadings = $conn->query("SELECT COUNT(*) FROM health_readings")->fetch_row()[0] ?? 0;

// ✅ FIXED: Today's readings - compare with CURDATE() (already in UTC)
$todayReadings = $conn->query("SELECT COUNT(*) FROM health_readings WHERE DATE(timestamp) = CURDATE()")->fetch_row()[0] ?? 0;

// ✅ FIXED: Critical Alerts Count (using UTC date comparison)
$criticalCount = $conn->query("
    SELECT COUNT(*) FROM health_readings hr
    WHERE (hr.temperature > 38.0 OR hr.temperature < 36.0)
       OR (hr.heart_rate > 100 OR hr.heart_rate < 60)
       OR (hr.spo2 < 95)
       OR (hr.systolic > 140 OR hr.systolic < 90)
       OR (hr.diastolic > 90 OR hr.diastolic < 60)
       AND DATE(hr.timestamp) = CURDATE()
")->fetch_row()[0] ?? 0;

// ✅ FIXED: Weekly statistics (no change needed - date grouping works in UTC)
$weeklyReadings = [];
$weeklyQuery = $conn->query("
    SELECT DATE(timestamp) as date, COUNT(*) as count
    FROM health_readings
    WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    GROUP BY DATE(timestamp)
    ORDER BY date ASC
");
while($row = $weeklyQuery->fetch_assoc()) {
    $weeklyReadings[] = $row;
}

// ✅ FIXED: Monthly statistics (no change needed)
$monthlyReadings = [];
$monthlyQuery = $conn->query("
    SELECT DATE_FORMAT(timestamp, '%Y-%m') as month, COUNT(*) as count
    FROM health_readings
    WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
    GROUP BY DATE_FORMAT(timestamp, '%Y-%m')
    ORDER BY month ASC
");
while($row = $monthlyQuery->fetch_assoc()) {
    $monthlyReadings[] = $row;
}

// [Keep all distribution queries - bmiDistribution, tempDistribution, etc. - NO CHANGES NEEDED]
$bmiDistribution = ['underweight' => 0, 'normal' => 0, 'overweight' => 0, 'obese' => 0];
$bmiQuery = $conn->query("SELECT bmi FROM health_readings WHERE bmi IS NOT NULL");
while($row = $bmiQuery->fetch_assoc()) {
    $bmi = $row['bmi'];
    if ($bmi < 18.5) $bmiDistribution['underweight']++;
    elseif ($bmi < 25.0) $bmiDistribution['normal']++;
    elseif ($bmi < 30.0) $bmiDistribution['overweight']++;
    else $bmiDistribution['obese']++;
}

$tempDistribution = ['hypothermia' => 0, 'low' => 0, 'normal' => 0, 'fever' => 0, 'high_fever' => 0];
$tempQuery = $conn->query("SELECT temperature FROM health_readings WHERE temperature IS NOT NULL");
while($row = $tempQuery->fetch_assoc()) {
    $temp = $row['temperature'];
    if ($temp < 35.0) $tempDistribution['hypothermia']++;
    elseif ($temp < 36.5) $tempDistribution['low']++;
    elseif ($temp < 37.6) $tempDistribution['normal']++;
    elseif ($temp < 39.1) $tempDistribution['fever']++;
    else $tempDistribution['high_fever']++;
}

$hrDistribution = ['bradycardia' => 0, 'low' => 0, 'normal' => 0, 'elevated' => 0, 'tachycardia' => 0];
$hrQuery = $conn->query("SELECT heart_rate FROM health_readings WHERE heart_rate IS NOT NULL");
while($row = $hrQuery->fetch_assoc()) {
    $hr = $row['heart_rate'];
    if ($hr < 50) $hrDistribution['bradycardia']++;
    elseif ($hr < 60) $hrDistribution['low']++;
    elseif ($hr <= 100) $hrDistribution['normal']++;
    elseif ($hr <= 120) $hrDistribution['elevated']++;
    else $hrDistribution['tachycardia']++;
}

$spo2Distribution = ['hypoxemia' => 0, 'low' => 0, 'slightly_low' => 0, 'normal' => 0];
$spo2Query = $conn->query("SELECT spo2 FROM health_readings WHERE spo2 IS NOT NULL");
while($row = $spo2Query->fetch_assoc()) {
    $spo2 = $row['spo2'];
    if ($spo2 < 90) $spo2Distribution['hypoxemia']++;
    elseif ($spo2 < 93) $spo2Distribution['low']++;
    elseif ($spo2 < 95) $spo2Distribution['slightly_low']++;
    else $spo2Distribution['normal']++;
}

$bpDistribution = ['normal' => 0, 'elevated' => 0, 'stage1' => 0, 'stage2' => 0, 'crisis' => 0];
$bpQuery = $conn->query("SELECT systolic, diastolic FROM health_readings WHERE systolic IS NOT NULL");
while($row = $bpQuery->fetch_assoc()) {
    $sys = $row['systolic'];
    $dia = $row['diastolic'];
    if ($sys > 180 || $dia > 120) $bpDistribution['crisis']++;
    elseif ($sys >= 140 || $dia >= 90) $bpDistribution['stage2']++;
    elseif ($sys >= 130 || $dia >= 80) $bpDistribution['stage1']++;
    elseif ($sys >= 120 && $dia < 80) $bpDistribution['elevated']++;
    else $bpDistribution['normal']++;
}

// ✅ FIXED: Latest Vital Signs Reading (no change needed - only reads values)
$vitalsToday = $conn->query("
    SELECT temperature, heart_rate, spo2, systolic, diastolic, bmi
    FROM health_readings
    ORDER BY timestamp DESC
    LIMIT 1
")->fetch_assoc();

// ✅ FIXED: Hourly readings (using UTC time - no change needed)
$hourlyReadings = [];
$hourlyQuery = $conn->query("
    SELECT HOUR(timestamp) as hour, COUNT(*) as count
    FROM health_readings
    WHERE DATE(timestamp) = CURDATE()
    GROUP BY HOUR(timestamp)
    ORDER BY hour ASC
");
while($row = $hourlyQuery->fetch_assoc()) {
    $hourlyReadings[] = $row;
}

// ✅ FIXED: Recent Readings with PH time conversion
$recentReadings = [];
$recentQuery = $conn->query("
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
    LIMIT 10
");
while($row = $recentQuery->fetch_assoc()) {
    $row['bmi_cat'] = categorizeBMI($row['bmi']);
    $row['temp_cat'] = categorizeTemperature($row['temperature']);
    $row['hr_cat'] = categorizeHeartRate($row['heart_rate']);
    $row['spo2_cat'] = categorizeSpO2($row['spo2']);
    $row['bp_cat'] = categorizeBP($row['systolic'], $row['diastolic']);
    $recentReadings[] = $row;
}

// ✅ FIXED: Critical Alerts with PH time conversion
$criticalAlerts = [];
$criticalQuery = $conn->query("
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
    WHERE (temperature > 38.0 OR temperature < 36.0)
       OR (heart_rate > 100 OR heart_rate < 60)
       OR (spo2 < 95)
       OR (systolic > 140 OR systolic < 90)
       OR (diastolic > 90 OR diastolic < 60)
    ORDER BY timestamp DESC
    LIMIT 5
");
while($row = $criticalQuery->fetch_assoc()) {
    $criticalAlerts[] = $row;
}

$admin_username = $_SESSION['admin_username'] ?? 'Admin';
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthX - Admin Dashboard</title>
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
                <a href="dashboard.php" class="nav-item active">
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
                    <h1>Dashboard Overview</h1>
                    <p class="subtitle">Real-time health monitoring insights</p>
                </div>
            </div>
            <div class="top-bar-right">
                <div class="quick-stats">
                    <div class="quick-stat">
                        <i class="fas fa-clock"></i>
                        <span><?php echo date('l, F j, Y'); ?></span>
                    </div>
                </div>

                <!-- Patient Notifications (Dashboard) -->
                <button class="notification-btn" id="patientNotificationBtn" aria-label="Patient Notifications">
                    <i class="fas fa-user-plus"></i>
                    <?php if(!empty($dashboard_unviewed_count) && $dashboard_unviewed_count > 0): ?>
                        <span class="badge"><?php echo $dashboard_unviewed_count; ?></span>
                    <?php endif; ?>
                </button>

                <div class="notifications-dropdown" id="patientNotificationsDropdown">
                    <div class="notifications-header">
                        <h3>New Patients</h3>
                        <button class="close-notifications" id="closePatientNotifications" aria-label="Close notifications"><i class="fas fa-times"></i></button>
                    </div>
                    <div class="notifications-body">
                        <?php if(count($dashboard_patient_notifications) > 0): ?>
                            <?php foreach($dashboard_patient_notifications as $notif): ?>
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
            <!-- Statistics Cards with Images -->
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
                        <div class="stat-value"><?php echo number_format($totalRegisteredPatients); ?></div>
                        <p class="stat-description">Registered in system • Active: <?php echo number_format($totalActivePatients); ?></p>
                    </div>
                    <div class="stat-footer">
                        <a href="patients.php">View all <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <img src="../images/healthccx.png" alt="Health Workers" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-user-md" style="display: none;"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Health Workers</h3>
                        <div class="stat-value"><?php echo number_format($totalHealthWorkers); ?></div>
                        <p class="stat-description">Active professionals</p>
                    </div>
                    <div class="stat-footer">
                        <a href="health_workers.php">Manage <i class="fas fa-arrow-right"></i></a>
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
                        <p class="stat-description">All-time records</p>
                    </div>
                    <div class="stat-footer">
                        <a href="readings.php">View data <i class="fas fa-arrow-right"></i></a>
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
                        <a href="readings.php?filter=today">Details <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>
            </div>

            <!-- Vital Signs Overview with Images -->
            <div class="vitals-overview">
                <div class="section-header">
                    <h2><i class="fas fa-activity"></i> Latest Vital Signs Overview</h2>
                </div>
                <div class="vitals-grid">
                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/body-temperature.png" alt="Temperature" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-thermometer-half" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Temperature</span>
                            <span class="vital-value"><?php echo number_format($vitalsToday['temperature'] ?? 36.5, 1); ?>°C</span>
                            <span class="vital-status <?php echo categorizeTemperature($vitalsToday['temperature'] ?? 36.5)['class']; ?>">
                                <?php echo categorizeTemperature($vitalsToday['temperature'] ?? 36.5)['category']; ?>
                            </span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/heart-rate.png" alt="Heart Rate" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-heartbeat" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Heart Rate</span>
                            <span class="vital-value"><?php echo number_format($vitalsToday['heart_rate'] ?? 75, 0); ?> bpm</span>
                            <span class="vital-status <?php echo categorizeHeartRate($vitalsToday['heart_rate'] ?? 75)['class']; ?>">
                                <?php echo categorizeHeartRate($vitalsToday['heart_rate'] ?? 75)['category']; ?>
                            </span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/oxygen-saturation.png" alt="SpO2" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-lungs" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">SpO2</span>
                            <span class="vital-value"><?php echo number_format($vitalsToday['spo2'] ?? 98, 0); ?>%</span>
                            <span class="vital-status <?php echo categorizeSpO2($vitalsToday['spo2'] ?? 98)['class']; ?>">
                                <?php echo categorizeSpO2($vitalsToday['spo2'] ?? 98)['category']; ?>
                            </span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/blood-pressure.png" alt="Blood Pressure" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-stethoscope" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Blood Pressure</span>
                            <span class="vital-value"><?php echo number_format($vitalsToday['systolic'] ?? 120, 0); ?>/<?php echo number_format($vitalsToday['diastolic'] ?? 80, 0); ?></span>
                            <span class="vital-status <?php echo categorizeBP($vitalsToday['systolic'] ?? 120, $vitalsToday['diastolic'] ?? 80)['class']; ?>">
                                <?php echo categorizeBP($vitalsToday['systolic'] ?? 120, $vitalsToday['diastolic'] ?? 80)['category']; ?>
                            </span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/body-mass-index.png" alt="BMI" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-weight" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">BMI</span>
                            <span class="vital-value"><?php echo number_format($vitalsToday['bmi'] ?? 23.5, 1); ?></span>
                            <span class="vital-status <?php echo categorizeBMI($vitalsToday['bmi'] ?? 23.5)['class']; ?>">
                                <?php echo categorizeBMI($vitalsToday['bmi'] ?? 23.5)['category']; ?>
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Charts Section -->
            <div class="charts-container">
                <div class="chart-full">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-chart-area"></i> Today's Hourly Activity</h2>
                                <p>Real-time readings distribution throughout the day</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="hourlyChart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-chart-line"></i> Weekly Trend</h2>
                                <p>Last 7 days performance</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="weeklyChart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2>
                                    <span class="chart-icon">
                                        <img src="../images/body-mass-index.png" alt="BMI" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-flex';">
                                        <i class="fas fa-weight" style="display: none;"></i>
                                    </span>
                                    BMI Distribution
                                </h2>
                                <p>Patient weight categories</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="bmiChart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2>
                                    <span class="chart-icon">
                                        <img src="../images/blood-pressure.png" alt="Blood Pressure" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-flex';">
                                        <i class="fas fa-heartbeat" style="display: none;"></i>
                                    </span>
                                    Blood Pressure
                                </h2>
                                <p>BP categories</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="bpChart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-small">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2>
                                    <span class="chart-icon">
                                        <img src="../images/body-temperature.png" alt="Temperature" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-flex';">
                                        <i class="fas fa-thermometer-half" style="display: none;"></i>
                                    </span>
                                    Temperature
                                </h2>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="tempChart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-small">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2>
                                    <span class="chart-icon">
                                        <img src="../images/heart-rate.png" alt="Heart Rate" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-flex';">
                                        <i class="fas fa-heart" style="display: none;"></i>
                                    </span>
                                    Heart Rate
                                </h2>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="hrChart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-small">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2>
                                    <span class="chart-icon">
                                        <img src="../images/oxygen-saturation.png" alt="SpO2" onerror="this.style.display='none'; this.nextElementSibling.style.display='inline-flex';">
                                        <i class="fas fa-lungs" style="display: none;"></i>
                                    </span>
                                    SpO2 Levels
                                </h2>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="spo2Chart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-small">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-chart-pie"></i> Monthly</h2>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="monthlyChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Critical Alerts -->
            <?php if(count($criticalAlerts) > 0): ?>
            <div class="alerts-section">
                <div class="section-header">
                    <h2><i class="fas fa-exclamation-circle"></i> Critical Alerts</h2>
                    <a href="alerts.php" class="btn-view-all">View All Alerts <i class="fas fa-arrow-right"></i></a>
                </div>
                <div class="alerts-grid">
                    <?php foreach($criticalAlerts as $alert): ?>
                    <div class="alert-card">
                        <div class="alert-severity critical">
                            <i class="fas fa-exclamation-triangle"></i>
                        </div>
                        <div class="alert-content">
                            <div class="alert-patient">
                                <i class="fas fa-user"></i>
                                <strong><?php echo htmlspecialchars($alert['patient_name']); ?></strong>
                            </div>
                            <div class="alert-vitals">
                                <?php
                                $alerts = [];
                                if($alert['temperature'] > 38.0 || $alert['temperature'] < 36.0) 
                                    $alerts[] = "<span class='vital-tag'><img src='../images/body-temperature.png' alt='Temp' onerror=\"this.style.display='none'\"> {$alert['temperature']}°C</span>";
                                if($alert['heart_rate'] > 100 || $alert['heart_rate'] < 60) 
                                    $alerts[] = "<span class='vital-tag'><img src='../images/heart-rate.png' alt='HR' onerror=\"this.style.display='none'\"> {$alert['heart_rate']} bpm</span>";
                                if($alert['spo2'] < 95) 
                                    $alerts[] = "<span class='vital-tag'><img src='../images/oxygen-saturation.png' alt='SpO2' onerror=\"this.style.display='none'\"> {$alert['spo2']}%</span>";
                                if($alert['systolic'] > 140 || $alert['systolic'] < 90 || $alert['diastolic'] > 90 || $alert['diastolic'] < 60) 
                                    $alerts[] = "<span class='vital-tag'><img src='../images/blood-pressure.png' alt='BP' onerror=\"this.style.display='none'\"> {$alert['systolic']}/{$alert['diastolic']}</span>";
                                echo implode('', $alerts);
                                ?>
                            </div>
                            <div class="alert-meta">
                                <span><i class="fas fa-user-md"></i> <?php echo htmlspecialchars(explode('@', $alert['worker_email'])[0]); ?></span>
                                <span><i class="fas fa-clock"></i> <?php echo date('M d, H:i', strtotime($alert['timestamp'])); ?></span>
                            </div>
                        </div>
                        <div class="alert-action">
                            <button class="btn-alert-action" 
                                    data-patient='<?php echo json_encode($alert); ?>'
                                    onclick="showPatientModal(this)">
                                View Details
                            </button>
                        </div>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
            <?php endif; ?>

            <!-- Recent Readings Table -->
            <div class="table-section">
                <div class="section-header">
                    <h2><i class="fas fa-history"></i> Recent Health Readings</h2>
                    <a href="readings.php" class="btn-view-all">View All Readings <i class="fas fa-arrow-right"></i></a>
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
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($recentReadings as $reading): ?>
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
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>

    <script>
        const weeklyData = <?php echo json_encode($weeklyReadings); ?>;
        const monthlyData = <?php echo json_encode($monthlyReadings); ?>;
        const hourlyData = <?php echo json_encode($hourlyReadings); ?>;
        const bmiDistribution = <?php echo json_encode($bmiDistribution); ?>;
        const bpDistribution = <?php echo json_encode($bpDistribution); ?>;
        const tempDistribution = <?php echo json_encode($tempDistribution); ?>;
        const hrDistribution = <?php echo json_encode($hrDistribution); ?>;
        const spo2Distribution = <?php echo json_encode($spo2Distribution); ?>;
        
        // Patient data for modal
        const criticalAlertsData = <?php echo json_encode($criticalAlerts); ?>;
    </script>
    <script src="../js/admin_script.js"></script>
    <script src="../js/patients_notifications.js"></script>

    <!-- Modal for Patient Details -->
    <div class="modal-overlay" id="patientModal">
        <div class="modal-container">
            <div class="modal-header">
                <h2><i class="fas fa-user-injured"></i> Patient Details</h2>
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
                    <!-- Vitals will be populated by JavaScript -->
                </div>
            </div>
            <div class="modal-footer">
                <button class="modal-btn modal-btn-secondary" onclick="closeModal()">Close</button>
            </div>
        </div>
    </div>
</body>
</html>