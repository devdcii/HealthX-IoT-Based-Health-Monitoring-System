<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/dbcon.php';

$data = json_decode(file_get_contents('php://input'), true);
$reading_id = $data['reading_id'] ?? null;
$bmi = $data['bmi'] ?? null;
$heart_rate = $data['heart_rate'] ?? null;
$spo2 = $data['spo2'] ?? null;
$temperature = $data['temperature'] ?? null;
$systolic = $data['systolic'] ?? null;
$diastolic = $data['diastolic'] ?? null;

if (!$reading_id) {
    echo json_encode(['success' => false, 'message' => 'Reading ID is required']);
    exit;
}

$stmt = $conn->prepare("UPDATE health_readings SET bmi = ?, heart_rate = ?, spo2 = ?, temperature = ?, systolic = ?, diastolic = ? WHERE id = ?");
$stmt->bind_param("diiidii", $bmi, $heart_rate, $spo2, $temperature, $systolic, $diastolic, $reading_id);
$stmt->execute();

if ($stmt->affected_rows > 0 || $conn->affected_rows === 0) {
    echo json_encode(['success' => true, 'message' => 'Reading updated successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Reading not found']);
}

$stmt->close();
$conn->close();
?>