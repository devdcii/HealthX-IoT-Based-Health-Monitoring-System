<?php
// admin_auth.php - centralized admin authentication guard
// Starts session if not started, enforces login, session timeout and fingerprinting
if (session_status() === PHP_SESSION_NONE) {
    // Harden session cookie parameters
    $secure = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off';
    session_set_cookie_params([
        'lifetime' => 0,
        'path' => '/',
        'domain' => $_SERVER['HTTP_HOST'] ?? '',
        'secure' => $secure,
        'httponly' => true,
        'samesite' => 'Lax'
    ]);
    session_start();
}

// Session inactivity timeout (seconds)
$timeout = 30 * 60; // 30 minutes

// Expire session if inactive
if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity']) > $timeout) {
    // Clear session and redirect to login with expired flag
    $_SESSION = [];
    if (isset($_COOKIE[session_name()])) {
        setcookie(session_name(), '', time() - 3600, '/');
    }
    session_destroy();
    header('Location: ../login.php?session_expired=1');
    exit;
}

// Update last activity timestamp
$_SESSION['last_activity'] = time();

// Simple fingerprint to mitigate session hijacking (uses IP + User Agent)
$fingerprint = hash('sha256', ($_SERVER['REMOTE_ADDR'] ?? '') . ($_SERVER['HTTP_USER_AGENT'] ?? ''));
if (!isset($_SESSION['fingerprint'])) {
    $_SESSION['fingerprint'] = $fingerprint;
} elseif ($_SESSION['fingerprint'] !== $fingerprint) {
    // Potential hijack - destroy session and redirect
    $_SESSION = [];
    if (isset($_COOKIE[session_name()])) {
        setcookie(session_name(), '', time() - 3600, '/');
    }
    session_destroy();
    header('Location: ../login.php?session_invalid=1');
    exit;
}

// Final login check
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    header('Location: ../login.php');
    exit;
}
