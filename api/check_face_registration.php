<?php
//check_face_registration.php

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Initialize response array
$response = ['success' => false, 'has_face' => false, 'message' => ''];

try {
    // Include database connection
    require_once 'config/database.php';
    
    // Get user_id from request
    $userId = null;
    
    // Check for user_id in GET, POST, or JSON body
    if (isset($_GET['user_id'])) {
        $userId = intval($_GET['user_id']);
    } elseif (isset($_POST['user_id'])) {
        $userId = intval($_POST['user_id']);
    } elseif (($input = file_get_contents('php://input'))) {
        $inputData = json_decode($input, true);
        if (json_last_error() === JSON_ERROR_NONE && isset($inputData['user_id'])) {
            $userId = intval($inputData['user_id']);
        }
    }
    
    if (!$userId) {
        throw new Exception('User ID is required');
    }
    
    // Prepare and execute the query
    $stmt = $conn->prepare("SELECT COUNT(*) as face_count FROM user_faces WHERE user_id = ? AND is_active = 1");
    if (!$stmt) {
        throw new Exception('Failed to prepare statement');
    }
    
    $stmt->bind_param("i", $userId);
    if (!$stmt->execute()) {
        throw new Exception('Failed to execute query');
    }
    
    $result = $stmt->get_result();
    if (!$result) {
        throw new Exception('Failed to get result');
    }
    
    $row = $result->fetch_assoc();
    $stmt->close();
    
    $response = [
        'success' => true,
        'has_face' => ($row['face_count'] > 0),
        'user_id' => $userId
    ];
    
} catch (Exception $e) {
    http_response_code(400);
    $response = [
        'success' => false,
        'message' => $e->getMessage()
    ];
}

// Send JSON response
header('Content-Type: application/json');
echo json_encode($response);
?>
