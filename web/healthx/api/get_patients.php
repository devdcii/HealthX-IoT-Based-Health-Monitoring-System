<?php
// api/get_patients.php - FIXED VERSION with proper timezone handling
require_once('../config/dbcon.php');
header('Content-Type: application/json');

// ✅ Convert timestamps to Philippine Time when fetching
$stmt = $conn->prepare("
    SELECT 
        id,
        name,
        email,
        CONVERT_TZ(created_at, '+00:00', '+08:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+08:00') as updated_at,
        notification_viewed
    FROM users 
    ORDER BY created_at DESC
");

$stmt->execute();
$result = $stmt->get_result();

$patients = [];
while ($row = $result->fetch_assoc()) {
    $patients[] = $row;
}

echo json_encode([
    'success' => true,
    'patients' => $patients
]);

$stmt->close();
$conn->close();
?>