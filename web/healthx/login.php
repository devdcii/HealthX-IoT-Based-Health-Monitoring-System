<?php

// Harden session cookie parameters
$secure = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off';
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'domain' => $_SERVER['HTTP_HOST'],
    'secure' => $secure,
    'httponly' => true,
    'samesite' => 'Lax'
]);
session_start();

// If already logged in, redirect to dashboard
if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        echo json_encode([
            'success' => true,
            'message' => 'Already logged in',
            'redirect' => 'admin/dashboard.php'
        ]);
    } else {
        header('Location: admin/dashboard.php');
    }
    exit();
}

// Include database connection
require_once 'config/dbcon.php';

// Process POST request only
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    // Get and sanitize input
    $username = isset($_POST['username']) ? trim($_POST['username']) : '';
    $password = isset($_POST['password']) ? trim($_POST['password']) : '';
    
    // Validate input
    if (empty($username) || empty($password)) {
        echo json_encode([
            'success' => false,
            'message' => 'Please enter both username and password'
        ]);
        exit();
    }
    
    // Escape special characters to prevent SQL injection
    $username = mysqli_real_escape_string($conn, $username);
    
    // Query database for user
    $query = "SELECT * FROM admin WHERE username = '$username' LIMIT 1";
    $result = mysqli_query($conn, $query);
    
    // Check if query was successful
    if (!$result) {
        echo json_encode([
            'success' => false,
            'message' => 'Database error. Please try again later.'
        ]);
        exit();
    }
    
    // Check if user exists
    if (mysqli_num_rows($result) === 1) {
        $user = mysqli_fetch_assoc($result);
        
        // Verify password (supports both plain text and hashed passwords)
        $password_match = false;
        
        // Check if password is hashed (starts with $2y$)
        if (strpos($user['password'], '$2y$') === 0) {
            // Use password_verify for hashed passwords
            $password_match = password_verify($password, $user['password']);
        } else {
            // Direct comparison for plain text passwords
            $password_match = ($password === $user['password']);
        }
        
        if ($password_match) {
            // ✅ PASSWORD CORRECT - CREATE SESSION
            
            // Regenerate session ID to prevent session fixation
            session_regenerate_id(true);
            
            // Set session variables
            $_SESSION['admin_logged_in'] = true;
            $_SESSION['admin_id'] = $user['id'];
            $_SESSION['admin_username'] = $user['username'];
            $_SESSION['last_activity'] = time();
            $_SESSION['session_created'] = time();
            $_SESSION['user_ip'] = $_SERVER['REMOTE_ADDR'];
// Fingerprint to mitigate session hijacking
$_SESSION['fingerprint'] = hash('sha256', $_SERVER['REMOTE_ADDR'] . ($_SERVER['HTTP_USER_AGENT'] ?? ''));

            
            // Optional: Update last login time in database
            $update_query = "UPDATE admin SET created_at = NOW() WHERE id = " . $user['id'];
            mysqli_query($conn, $update_query);
            
            // Return success response
            echo json_encode([
                'success' => true,
                'message' => 'Login successful! Redirecting...',
                'redirect' => 'admin/dashboard.php'
            ]);
            
        } else {
            // ❌ WRONG PASSWORD
            echo json_encode([
                'success' => false,
                'message' => 'Invalid username or password'
            ]);
        }
        
    } else {
        // ❌ USER NOT FOUND
        echo json_encode([
            'success' => false,
            'message' => 'Invalid username or password'
        ]);
    }
    
} else {
    // Not a POST request - redirect to home
    header('Location: index.php');
    exit();
}
?>