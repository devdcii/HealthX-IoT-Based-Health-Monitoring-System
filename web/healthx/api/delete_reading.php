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

if (!$reading_id) {
    echo json_encode(['success' => false, 'message' => 'Reading ID is required']);
    exit;
}

$stmt = $conn->prepare("DELETE FROM health_readings WHERE id = ?");
$stmt->bind_param("i", $reading_id);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode(['success' => true, 'message' => 'Reading deleted successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Reading not found or already deleted']);
}

$stmt->close();
$conn->close();
?>