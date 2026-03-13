<?php
session_start();

// Store username for logout message (optional)
$username = isset($_SESSION['admin_username']) ? $_SESSION['admin_username'] : 'User';

// Unset all session variables
$_SESSION = array();

// Delete the session cookie
if (isset($_COOKIE[session_name()])) {
    setcookie(
        session_name(), 
        '', 
        time() - 3600, 
        '/',
        '', 
        isset($_SERVER['HTTPS']), 
        true
    );
}

// Destroy the session
session_destroy();

// Clear any other cookies (optional)
if (isset($_COOKIE['remember_me'])) {
    setcookie('remember_me', '', time() - 3600, '/');
}

// Redirect to home page with logout message
header('Location: ../index.php?logout=success&user=' . urlencode($username));
exit();
?>