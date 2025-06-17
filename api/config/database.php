<?php
// Database configuration
$dbHost = 'localhost';
$dbUser = 'root';      // Default XAMPP username
$dbPass = '';          // Default XAMPP password is empty
$dbName = 'your_database_name'; // Replace with your actual database name

// Create connection
$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);

// Check connection
if ($conn->connect_error) {
    die(json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $conn->connect_error
    ]));
}

// Set charset to utf8mb4 for full Unicode support
$conn->set_charset('utf8mb4');
?>
