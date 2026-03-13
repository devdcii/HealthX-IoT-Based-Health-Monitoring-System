<?php
// contact_inquiry.php - Handle contact form submissions
header('Content-Type: application/json');

// Set timezone to Philippines (UTC+8)
date_default_timezone_set('Asia/Manila');

// Include database connection
require_once 'config/dbcon.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get form data
    $full_name = trim($_POST['full_name'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $subject = trim($_POST['subject'] ?? '');
    $message = trim($_POST['message'] ?? '');
    
    // Validate inputs
    if (empty($full_name) || empty($email) || empty($subject) || empty($message)) {
        echo json_encode([
            'success' => false,
            'message' => 'All fields are required.'
        ]);
        exit;
    }
    
    // Validate email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode([
            'success' => false,
            'message' => 'Please enter a valid email address.'
        ]);
        exit;
    }
    
    // Validate length
    if (strlen($full_name) > 100 || strlen($subject) > 200 || strlen($message) > 1000) {
        echo json_encode([
            'success' => false,
            'message' => 'Input exceeds maximum allowed length.'
        ]);
        exit;
    }
    
    // Sanitize inputs (for display purposes - prepared statements handle SQL injection)
    $full_name = htmlspecialchars($full_name, ENT_QUOTES, 'UTF-8');
    $email = htmlspecialchars($email, ENT_QUOTES, 'UTF-8');
    $subject = htmlspecialchars($subject, ENT_QUOTES, 'UTF-8');
    $message = htmlspecialchars($message, ENT_QUOTES, 'UTF-8');
    
    // Prepare statement to prevent SQL injection
    $stmt = $conn->prepare("
        INSERT INTO contact_inquiries 
        (full_name, email, subject, message, status, created_at, updated_at) 
        VALUES (?, ?, ?, ?, 'new', NOW(), NOW())
    ");
    
    if ($stmt === false) {
        error_log("Prepare failed: " . $conn->error);
        echo json_encode([
            'success' => false,
            'message' => 'An error occurred. Please try again later.'
        ]);
        exit;
    }
    
    $stmt->bind_param("ssss", $full_name, $email, $subject, $message);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Thank you for contacting us! We will respond to your inquiry shortly.'
        ]);
    } else {
        error_log("Contact Inquiry Error: " . $stmt->error);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to save inquiry. Please try again.'
        ]);
    }
    
    $stmt->close();
    $conn->close();
    
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method.'
    ]);
}
?>