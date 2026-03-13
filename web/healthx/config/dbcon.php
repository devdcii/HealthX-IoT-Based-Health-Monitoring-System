<?php
// Set PHP timezone to Philippine Time
date_default_timezone_set('Asia/Manila');

$servername = "localhost";
$username = "u205624883_healthhccx";
$password = "HealthXInnovation1;";
$dbname = "u205624883_healthhccx";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// ✅ CRITICAL: Set MySQL to UTC for storage
$conn->query("SET time_zone = '+00:00'");
?>