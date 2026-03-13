<?php
// api/get_readings.php - FIXED VERSION
require_once('../config/dbcon.php');
header('Content-Type: application/json');

// ✅ Get 'email' parameter (matching Dart code)
$email = $_GET['email'] ?? '';

// Debug logging (remove in production)
error_log("=== GET READINGS REQUEST ===");
error_log("Email received: " . $email);
error_log("All GET params: " . print_r($_GET, true));

if (empty($email)) {
    echo json_encode([
        'success' => false, 
        'message' => 'Email parameter is required',
        'readings' => [],
        'debug' => [
            'received_params' => $_GET,
            'email_empty' => true
        ]
    ]);
    exit;
}

try {
    // ✅ USE CONVERT_TZ to convert from UTC (storage) to Philippine Time (display)
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
            CONVERT_TZ(timestamp, '+00:00', '+08:00') as timestamp,
            CONVERT_TZ(created_at, '+00:00', '+08:00') as created_at
        FROM health_readings 
        WHERE user_email = ? 
        ORDER BY timestamp DESC
    ");

    if (!$stmt) {
        error_log("SQL prepare failed: " . $conn->error);
        echo json_encode([
            'success' => false,
            'message' => 'Database prepare error',
            'readings' => []
        ]);
        exit;
    }

    $stmt->bind_param("s", $email);
    
    if (!$stmt->execute()) {
        error_log("SQL execute failed: " . $stmt->error);
        echo json_encode([
            'success' => false,
            'message' => 'Database execute error',
            'readings' => []
        ]);
        exit;
    }

    $result = $stmt->get_result();
    $readings = [];
    
    while ($row = $result->fetch_assoc()) {
        $readings[] = $row;
    }

    // Debug logging
    error_log("Found " . count($readings) . " readings for email: " . $email);
    
    if (count($readings) > 0) {
        error_log("First reading ID: " . $readings[0]['id']);
        error_log("First reading timestamp: " . $readings[0]['timestamp']);
    }

    echo json_encode([
        'success' => true,
        'readings' => $readings,
        'debug' => [
            'email_searched' => $email,
            'count' => count($readings),
            'query_executed' => true
        ]
    ]);

    $stmt->close();
    
} catch (Exception $e) {
    error_log("Exception in get_readings.php: " . $e->getMessage());
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage(),
        'readings' => []
    ]);
}

$conn->close();
?>