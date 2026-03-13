<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/dbcon.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);
    
    // Validate required fields
    if (empty($data['worker_email']) || empty($data['user_email']) || empty($data['patient_name'])) {
        echo json_encode([
            'success' => false,
            'message' => 'Worker email, user email, and patient name are required'
        ]);
        exit();
    }
    
    // Extract data
    $worker_email = $conn->real_escape_string($data['worker_email']);
    $user_email = $conn->real_escape_string($data['user_email']);
    $patient_name = $conn->real_escape_string($data['patient_name']);
    $weight = floatval($data['weight']);
    $height = floatval($data['height']);
    $bmi = floatval($data['bmi']);
    $heart_rate = intval($data['heart_rate']);
    $spo2 = intval($data['spo2']);
    $temperature = floatval($data['temperature']);
    $systolic = intval($data['systolic']);
    $diastolic = intval($data['diastolic']);
    $timestamp = $conn->real_escape_string($data['timestamp']);
    
    // Insert reading
    $sql = "INSERT INTO health_readings 
            (worker_email, user_email, patient_name, weight, height, bmi, heart_rate, spo2, temperature, systolic, diastolic, timestamp) 
            VALUES 
            ('$worker_email', '$user_email', '$patient_name', $weight, $height, $bmi, $heart_rate, $spo2, $temperature, $systolic, $diastolic, '$timestamp')";
    
    if ($conn->query($sql) === TRUE) {
        echo json_encode([
            'success' => true,
            'message' => 'Reading saved successfully',
            'reading_id' => $conn->insert_id
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $conn->error
        ]);
    }
    
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method. Use POST.'
    ]);
}

$conn->close();
?>