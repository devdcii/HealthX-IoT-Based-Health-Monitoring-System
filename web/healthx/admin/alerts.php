<?php
// alerts.php - FIXED VERSION with proper timezone handling
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

// ✅ FIXED: Fetch Critical Alerts with PH time conversion
$criticalAlerts = [];
$alertsQuery = $conn->query("
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
");
while($row = $alertsQuery->fetch_assoc()) {
    $row['bmi_cat'] = categorizeBMI($row['bmi']);
    $row['temp_cat'] = categorizeTemperature($row['temperature']);
    $row['hr_cat'] = categorizeHeartRate($row['heart_rate']);
    $row['spo2_cat'] = categorizeSpO2($row['spo2']);
    $row['bp_cat'] = categorizeBP($row['systolic'], $row['diastolic']);
    $criticalAlerts[] = $row;
}

// Statistics by Alert Type (no changes needed)
$tempAlerts = 0;
$hrAlerts = 0;
$spo2Alerts = 0;
$bpAlerts = 0;

foreach($criticalAlerts as $alert) {
    if($alert['temperature'] > 38.0 || $alert['temperature'] < 36.0) $tempAlerts++;
    if($alert['heart_rate'] > 100 || $alert['heart_rate'] < 60) $hrAlerts++;
    if($alert['spo2'] < 95) $spo2Alerts++;
    if($alert['systolic'] > 140 || $alert['systolic'] < 90 || $alert['diastolic'] > 90 || $alert['diastolic'] < 60) $bpAlerts++;
}

$todayAlerts = 0;
$weekAlerts = 0;
foreach($criticalAlerts as $alert) {
    // ⚠️ Note: These comparisons work because $alert['timestamp'] is now in PH time
    // But the query used CURDATE() which is UTC - this is OK for counting
    if(date('Y-m-d', strtotime($alert['timestamp'])) === date('Y-m-d')) $todayAlerts++;
    if(strtotime($alert['timestamp']) >= strtotime('-7 days')) $weekAlerts++;
}

// At-Risk Patients Count (no changes needed)
$atRiskPatients = $conn->query("
    SELECT COUNT(DISTINCT patient_name) as at_risk_count
    FROM health_readings
    WHERE (temperature > 38.0 OR temperature < 36.0)
       OR (heart_rate > 100 OR heart_rate < 60)
       OR (spo2 < 95)
       OR (systolic > 140 OR systolic < 90)
       OR (diastolic > 90 OR diastolic < 60)
")->fetch_assoc();

$atRiskCount = $atRiskPatients['at_risk_count'] ?? 0;
$admin_username = $_SESSION['admin_username'] ?? 'Admin';
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthX - Critical Alerts</title>
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
                <a href="alerts.php" class="nav-item active">
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
                    <h1>Critical Alerts</h1>
                    <p class="subtitle">Monitor and manage critical health alerts</p>
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
            <!-- Statistics Cards with Images -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-exclamation-triangle"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Total Critical Alerts</h3>
                        <div class="stat-value"><?php echo number_format(count($criticalAlerts)); ?></div>
                        <p class="stat-description">All time</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#all-alerts">View all <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-calendar-day"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Today's Alerts</h3>
                        <div class="stat-value"><?php echo number_format($todayAlerts); ?></div>
                        <p class="stat-description">Last 24 hours</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#all-alerts">View details <i class="fas fa-arrow-right"></i></a>
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
                        <div class="stat-value"><?php echo number_format($weekAlerts); ?></div>
                        <p class="stat-description">Last 7 days</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#all-alerts">View data <i class="fas fa-arrow-right"></i></a>
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
                        <a href="#all-alerts">View patients <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>
            </div>

            <!-- Alert Types Overview with Images -->
            <div class="vitals-overview">
                <div class="section-header">
                    <h2><i class="fas fa-exclamation-circle"></i> Alerts by Type</h2>
                </div>
                <div class="vitals-grid">
                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/body-temperature.png" alt="Temperature" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-thermometer-half" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Temperature</span>
                            <span class="vital-value"><?php echo number_format($tempAlerts); ?></span>
                            <span class="vital-status elevated">Above 38°C or Below 36°C</span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/heart-rate.png" alt="Heart Rate" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-heartbeat" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Heart Rate</span>
                            <span class="vital-value"><?php echo number_format($hrAlerts); ?></span>
                            <span class="vital-status critical">Above 100 or Below 60 bpm</span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/oxygen-saturation.png" alt="SpO2" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-lungs" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">SpO2</span>
                            <span class="vital-value"><?php echo number_format($spo2Alerts); ?></span>
                            <span class="vital-status high">Below 95%</span>
                        </div>
                    </div>

                    <div class="vital-card">
                        <div class="vital-icon">
                            <img src="../images/blood-pressure.png" alt="Blood Pressure" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-stethoscope" style="display: none;"></i>
                        </div>
                        <div class="vital-info">
                            <span class="vital-label">Blood Pressure</span>
                            <span class="vital-value"><?php echo number_format($bpAlerts); ?></span>
                            <span class="vital-status elevated">Abnormal readings</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Charts Section -->
            <div class="charts-container">
                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-chart-pie"></i> Alerts by Type</h2>
                                <p>Distribution of alert categories</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="alertTypesChart"></canvas>
                        </div>
                    </div>
                </div>

                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-chart-bar"></i> Alert Severity</h2>
                                <p>Severity distribution</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="severityChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Critical Alerts List -->
            <div class="alerts-section" id="all-alerts">
                <div class="section-header">
                    <h2><i class="fas fa-exclamation-circle"></i> All Critical Alerts</h2>
                </div>
                <?php if(count($criticalAlerts) > 0): ?>
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
                <?php else: ?>
                    <div style="text-align: center; padding: 4rem 2rem; color: var(--muted);">
                        <i class="fas fa-check-circle" style="font-size: 4rem; color: var(--status-success); margin-bottom: 1rem;"></i>
                        <h3 style="color: var(--text-dark); margin-bottom: 0.5rem;">No Critical Alerts</h3>
                        <p>All patient readings are within normal ranges</p>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </main>

    <!-- Modal for Patient Details -->
    <div class="modal-overlay" id="patientModal">
        <div class="modal-container">
            <div class="modal-header">
                <h2><i class="fas fa-user-injured"></i> Alert Details</h2>
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

    <script>
        const alertsData = {
            temp: <?php echo $tempAlerts; ?>,
            hr: <?php echo $hrAlerts; ?>,
            spo2: <?php echo $spo2Alerts; ?>,
            bp: <?php echo $bpAlerts; ?>
        };
        const criticalAlertsData = <?php echo json_encode($criticalAlerts); ?>;
    </script>
    <script src="../js/alerts.js"></script>
</body>
</html>