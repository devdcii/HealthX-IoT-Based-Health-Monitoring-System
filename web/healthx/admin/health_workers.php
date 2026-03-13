<?php
// health_workers.php - FIXED VERSION with proper timezone handling
require_once __DIR__ . '/admin_auth.php';
require_once('../config/dbcon.php');

// ✅ FIXED: Fetch All Health Workers with PH time conversion
$healthWorkers = [];
$workersQuery = $conn->query("
    SELECT 
        hr.worker_email as email,
        COUNT(hr.id) as readings_recorded,
        MIN(DATE_ADD(hr.created_at, INTERVAL 8 HOUR)) as first_reading,
        MAX(DATE_ADD(hr.timestamp, INTERVAL 8 HOUR)) as last_reading,
        COUNT(DISTINCT hr.user_email) as patients_served,
        COUNT(DISTINCT DATE(hr.timestamp)) as active_days
    FROM health_readings hr
    GROUP BY hr.worker_email
    ORDER BY readings_recorded DESC
");
while($row = $workersQuery->fetch_assoc()) {
    $healthWorkers[] = $row;
}

// Fetch Critical Alerts Handled per Worker (no changes needed - counts only)
$alertsPerWorker = [];
$alertsQuery = $conn->query("
    SELECT 
        hr.worker_email as email,
        COUNT(hr.id) as alerts_handled
    FROM health_readings hr
    WHERE (hr.temperature > 38.0 OR hr.temperature < 36.0)
       OR (hr.heart_rate > 100 OR hr.heart_rate < 60)
       OR (hr.spo2 < 95)
       OR (hr.systolic > 140 OR hr.systolic < 90)
       OR (hr.diastolic > 90 OR hr.diastolic < 60)
    GROUP BY hr.worker_email
    ORDER BY alerts_handled DESC
    LIMIT 10
");
if($alertsQuery) {
    while($row = $alertsQuery->fetch_assoc()) {
        $alertsPerWorker[] = $row;
    }
}

// Statistics (no changes needed)
$totalWorkers = count($healthWorkers);
$activeThisMonth = 0;
$totalReadingsRecorded = 0;

foreach($healthWorkers as $worker) {
    $totalReadingsRecorded += $worker['readings_recorded'];
    if($worker['last_reading'] && strtotime($worker['last_reading']) >= strtotime('-30 days')) {
        $activeThisMonth++;
    }
}

$totalPatientsServed = 0;
foreach($healthWorkers as $worker) {
    $totalPatientsServed += $worker['patients_served'];
}

$admin_username = $_SESSION['admin_username'] ?? 'Admin';
?>

<!-- Keep ALL your existing HTML code exactly as is - no changes needed -->

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HealthX - Health Workers</title>
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
                <a href="health_workers.php" class="nav-item active">
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
                    <h1>Health Workers</h1>
                    <p class="subtitle">Manage and monitor healthcare professionals</p>
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
            <!-- Statistics Cards -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <img src="../images/healthccx.png" alt="Health Workers" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <i class="fas fa-user-md" style="display: none;"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Total Health Workers</h3>
                        <div class="stat-value"><?php echo number_format($totalWorkers); ?></div>
                        <p class="stat-description">Registered workers</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#workers-table">View all <i class="fas fa-arrow-right"></i></a>
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
                        <a href="#workers-table">View details <i class="fas fa-arrow-right"></i></a>
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
                        <div class="stat-value"><?php echo number_format($totalReadingsRecorded); ?></div>
                        <p class="stat-description">Recorded by all workers</p>
                    </div>
                    <div class="stat-footer">
                        <a href="readings.php">View data <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>

                <!-- Patient Load Distribution stat card -->
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon">
                            <i class="fas fa-users"></i>
                        </div>
                    </div>
                    <div class="stat-body">
                        <h3>Patient Load Distribution</h3>
                        <div class="stat-value"><?php echo number_format($totalPatientsServed); ?></div>
                        <p class="stat-description">Unique patients served</p>
                    </div>
                    <div class="stat-footer">
                        <a href="#workers-table">Details <i class="fas fa-arrow-right"></i></a>
                    </div>
                </div>
            </div>

            <!-- Charts Section -->
            <div class="charts-container">
                <!-- Critical Alerts Handled -->
                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-exclamation-circle"></i> Critical Alerts Handled</h2>
                                <p>By worker</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="alertsHandledChart"></canvas>
                        </div>
                    </div>
                </div>

                <!-- Activity Status (kept) -->
                <div class="chart-medium">
                    <div class="chart-card">
                        <div class="chart-header">
                            <div>
                                <h2><i class="fas fa-chart-pie"></i> Activity Status</h2>
                                <p>Last 30 days</p>
                            </div>
                        </div>
                        <div class="chart-body">
                            <canvas id="activityChart"></canvas>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Health Workers Table -->
            <div class="table-section" id="workers-table">
                <div class="section-header">
                    <h2><i class="fas fa-user-md"></i> All Health Workers</h2>
                </div>
                <div class="table-container">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Worker</th>
                                <th>Email</th>
                                <th>Readings Recorded</th>
                                <th>Patients Served</th>
                                <th>Active Days</th>
                                <th>First Reading</th>
                                <th>Last Reading</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach($healthWorkers as $worker): ?>
                            <tr>
                                <td>
                                    <div class="patient-cell">
                                        <div class="patient-avatar"><?php echo strtoupper(substr(explode('@', $worker['email'])[0], 0, 1)); ?></div>
                                        <strong><?php echo htmlspecialchars(explode('@', $worker['email'])[0]); ?></strong>
                                    </div>
                                </td>
                                <td><?php echo htmlspecialchars($worker['email']); ?></td>
                                <td><strong><?php echo number_format($worker['readings_recorded']); ?></strong></td>
                                <td><?php echo number_format($worker['patients_served']); ?></td>
                                <td><?php echo number_format($worker['active_days']); ?> days</td>
                                <td><?php echo date('M d, Y', strtotime($worker['first_reading'])); ?></td>
                                <td><?php echo date('M d, Y', strtotime($worker['last_reading'])); ?></td>
                                <td>
                                    <?php 
                                    $isActive = strtotime($worker['last_reading']) >= strtotime('-30 days');
                                    ?>
                                    <span class="reading-category <?php echo $isActive ? 'normal' : 'low'; ?>">
                                        <?php echo $isActive ? 'Active' : 'Inactive'; ?>
                                    </span>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>

    <script>
        // Critical Alerts Handled per worker
        const alertsData = <?php echo json_encode($alertsPerWorker); ?>;

        // Activity Status doughnut
        const activeWorkers = <?php echo $activeThisMonth; ?>;
        const inactiveWorkers = <?php echo $totalWorkers - $activeThisMonth; ?>;
    </script>
    <script src="../js/health_workers.js"></script>
</body>
</html>