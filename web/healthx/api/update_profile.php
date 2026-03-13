<?php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Include database connection
require_once '../config/dbcon.php';

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

switch ($action) {
    case 'update_profile':
        handleUpdateProfile($input);
        break;
    
    case 'change_password':
        handleChangePassword($input);
        break;
    
    default:
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid action'
        ]);
}

function handleUpdateProfile($data) {
    global $conn;
    
    $userId = $data['user_id'] ?? 0;
    $name = trim($data['name'] ?? '');
    $email = trim($data['email'] ?? '');
    $oldEmail = trim($data['old_email'] ?? ''); // Old email to update health_readings
    $userType = $data['user_type'] ?? 'user';
    
    if (empty($name) || empty($email)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Name and email are required'
        ]);
        return;
    }
    
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid email format'
        ]);
        return;
    }
    
    // Start transaction to ensure all updates happen together
    $conn->begin_transaction();
    
    try {
        if ($userType === 'healthworker') {
            // Check if email exists for other health workers
            $stmt = $conn->prepare("SELECT id FROM admin WHERE username = ? AND id != ?");
            $stmt->bind_param("si", $email, $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $stmt->close();
                $conn->rollback();
                http_response_code(409);
                echo json_encode([
                    'success' => false,
                    'message' => 'Email already in use by another health worker'
                ]);
                return;
            }
            $stmt->close();
            
            // Update health worker profile in admin table
            $stmt = $conn->prepare("UPDATE admin SET username = ? WHERE id = ?");
            $stmt->bind_param("si", $email, $userId);
            
            if (!$stmt->execute()) {
                throw new Exception('Failed to update admin profile');
            }
            $stmt->close();
            
            // Update all health_readings where this health worker recorded data
            if (!empty($oldEmail)) {
                $stmt = $conn->prepare("UPDATE health_readings SET worker_email = ? WHERE worker_email = ?");
                $stmt->bind_param("ss", $email, $oldEmail);
                $stmt->execute();
                $stmt->close();
            }
            
            // Commit transaction
            $conn->commit();
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'name' => $email,
                'email' => $email
            ]);
            
        } else {
            // Check if email exists for other users
            $stmt = $conn->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
            $stmt->bind_param("si", $email, $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $stmt->close();
                $conn->rollback();
                http_response_code(409);
                echo json_encode([
                    'success' => false,
                    'message' => 'Email already in use'
                ]);
                return;
            }
            $stmt->close();
            
            // Update user profile in users table
            $stmt = $conn->prepare("UPDATE users SET name = ?, email = ? WHERE id = ?");
            $stmt->bind_param("ssi", $name, $email, $userId);
            
            if (!$stmt->execute()) {
                throw new Exception('Failed to update user profile');
            }
            $stmt->close();
            
            // Update all health_readings where this patient has records
            // This ensures all previous records will still be linked to the patient
            if (!empty($oldEmail)) {
                $stmt = $conn->prepare("UPDATE health_readings SET user_email = ?, patient_name = ? WHERE user_email = ?");
                $stmt->bind_param("sss", $email, $name, $oldEmail);
                $stmt->execute();
                $stmt->close();
            }
            
            // Commit transaction
            $conn->commit();
            
            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'name' => $name,
                'email' => $email
            ]);
        }
    } catch (Exception $e) {
        // Rollback transaction if any error occurs
        $conn->rollback();
        
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to update profile: ' . $e->getMessage()
        ]);
    }
}

function handleChangePassword($data) {
    global $conn;
    
    $userId = $data['user_id'] ?? 0;
    $currentPassword = $data['current_password'] ?? '';
    $newPassword = $data['new_password'] ?? '';
    $userType = $data['user_type'] ?? 'user';
    
    if (empty($currentPassword) || empty($newPassword)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Current and new password are required'
        ]);
        return;
    }
    
    if (strlen($newPassword) < 6) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'New password must be at least 6 characters'
        ]);
        return;
    }
    
    if ($userType === 'healthworker') {
        // Verify current password for health worker
        $stmt = $conn->prepare("SELECT password FROM admin WHERE id = ?");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'User not found'
            ]);
            $stmt->close();
            return;
        }
        
        $user = $result->fetch_assoc();
        $stmt->close();
        
        // Verify current password (support both hashed and plain text for backward compatibility)
        $passwordMatch = false;
        if (password_verify($currentPassword, $user['password'])) {
            $passwordMatch = true;
        } elseif ($currentPassword === $user['password']) {
            $passwordMatch = true;
        }
        
        if (!$passwordMatch) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Current password is incorrect'
            ]);
            return;
        }
        
        // Update password with proper hashing
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
        $stmt = $conn->prepare("UPDATE admin SET password = ? WHERE id = ?");
        $stmt->bind_param("si", $hashedPassword, $userId);
        
    } else {
        // Verify current password for regular user
        $stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'User not found'
            ]);
            $stmt->close();
            return;
        }
        
        $user = $result->fetch_assoc();
        $stmt->close();
        
        if (!password_verify($currentPassword, $user['password'])) {
            http_response_code(401);
            echo json_encode([
                'success' => false,
                'message' => 'Current password is incorrect'
            ]);
            return;
        }
        
        // Update password with proper hashing
        $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
        $stmt = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
        $stmt->bind_param("si", $hashedPassword, $userId);
    }
    
    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'Password changed successfully'
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to change password'
        ]);
    }
    
    $stmt->close();
}

$conn->close();
?>