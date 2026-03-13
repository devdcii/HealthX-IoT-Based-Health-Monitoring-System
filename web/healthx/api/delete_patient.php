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
$patient_id = $data['patient_id'] ?? null;

if (!$patient_id) {
    echo json_encode(['success' => false, 'message' => 'Patient ID is required']);
    exit;
}

// Start transaction
$conn->begin_transaction();

try {
    // Get patient email (NO ROLE CHECK - your table doesn't have role column)
    $stmt = $conn->prepare("SELECT email FROM users WHERE id = ?");
    $stmt->bind_param("i", $patient_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        $conn->rollback();
        echo json_encode(['success' => false, 'message' => 'Patient not found']);
        exit;
    }
    
    $patient = $result->fetch_assoc();
    $patient_email = $patient['email'];
    $stmt->close();
    
    // Delete all readings for this patient
    $stmt = $conn->prepare("DELETE FROM health_readings WHERE user_email = ?");
    $stmt->bind_param("s", $patient_email);
    $stmt->execute();
    $stmt->close();
    
    // Delete the patient
    $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
    $stmt->bind_param("i", $patient_id);
    $stmt->execute();
    
    if ($stmt->affected_rows > 0) {
        $conn->commit();
        echo json_encode(['success' => true, 'message' => 'Patient deleted successfully']);
    } else {
        $conn->rollback();
        echo json_encode(['success' => false, 'message' => 'Failed to delete patient']);
    }
    
    $stmt->close();
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}

$conn->close();
?>