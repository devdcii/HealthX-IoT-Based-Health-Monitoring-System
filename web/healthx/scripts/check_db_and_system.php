<?php
require_once __DIR__ . '/../config/dbcon.php';
header('Content-Type: text/plain');

echo "HealthX DB & System Diagnostic Report\n";
echo "Date: " . date('c') . "\n\n";

// 1) Counts
$registered = $conn->query("SELECT COUNT(*) as c FROM users")->fetch_assoc()['c'];
$activeFromReadings = $conn->query("SELECT COUNT(DISTINCT user_email) as c FROM health_readings")->fetch_assoc()['c'];
$readingsTotal = $conn->query("SELECT COUNT(*) as c FROM health_readings")->fetch_assoc()['c'];

echo "Counts:\n";
echo "- Registered users (users): $registered\n";
echo "- Active patients (distinct user_email in health_readings): $activeFromReadings\n";
echo "- Total readings: $readingsTotal\n\n";

// 2) Collations for user email columns
function columnInfo($table, $col) {
    global $conn;
    $res = $conn->query("SHOW FULL COLUMNS FROM `$table` LIKE '$col'");
    if($res && $res->num_rows) return $res->fetch_assoc();
    return null;
}
$uEmail = columnInfo('users', 'email');
$hrEmail = columnInfo('health_readings', 'user_email');

echo "Column collations:\n";
echo "- users.email: " . ($uEmail['Collation'] ?? 'MISSING') . "\n";
echo "- health_readings.user_email: " . ($hrEmail['Collation'] ?? 'MISSING') . "\n\n";

// 3) Orphan readings (readings with user_email not found in users)
$orphan = $conn->query("SELECT COUNT(*) as c FROM health_readings hr LEFT JOIN users u ON hr.user_email COLLATE utf8mb4_unicode_ci = u.email WHERE u.email IS NULL")->fetch_assoc()['c'];
echo "Orphan readings (user_email not found in users): $orphan\n";
if($orphan > 0) {
    echo "Sample orphan emails:\n";
    $res = $conn->query("SELECT DISTINCT hr.user_email FROM health_readings hr LEFT JOIN users u ON hr.user_email = u.email WHERE u.email IS NULL LIMIT 10");
    while($r = $res->fetch_assoc()) echo " - " . $r['user_email'] . "\n";
}

echo "\n";

// 4) Check notification_viewed existence
$colNotif = columnInfo('users','notification_viewed');
echo "Notification column on users: " . ($colNotif ? 'present' : 'missing') . "\n";

// 5) Verify patients.php query result count equals users count
$patientsListCount = $conn->query("SELECT COUNT(*) as c FROM users")->fetch_assoc()['c'];
echo "Patients query vs users table check:\n";
echo "- Patients list query count: $patientsListCount\n";

// 6) Find other code locations that may be counting active patients differently
$search = [];
// We'll just output a hint to search manually in codebase for COUNT(DISTINCT user_email)
echo "\nManual checks to consider:\n";
echo "- Search for 'COUNT(DISTINCT user_email' in codebase to find places using active-only counts.\n";

echo "\nEnd of report.\n";

$conn->close();
