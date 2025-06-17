<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'config/database.php';

$response = ['success' => false, 'message' => ''];

// Check if this is a multipart form data request
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['face_image'])) {
    $userId = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    $faceEmbedding = isset($_POST['face_embedding']) ? $_POST['face_embedding'] : '';
    
    if ($userId <= 0) {
        $response['message'] = 'Invalid user ID';
        echo json_encode($response);
        exit;
    }
    
    // Handle file upload
    $uploadDir = 'uploads/faces/';
    
    // Create directory if it doesn't exist
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }
    
    $file = $_FILES['face_image'];
    $fileName = uniqid('face_') . '_' . basename($file['name']);
    $targetPath = $uploadDir . $fileName;
    
    // Move uploaded file
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        try {
            // Start transaction
            $conn->begin_transaction();
            
            // Deactivate any existing face registrations for this user
            $deactivateStmt = $conn->prepare("UPDATE user_faces SET is_active = 0 WHERE user_id = ?");
            $deactivateStmt->bind_param("i", $userId);
            $deactivateStmt->execute();
            $deactivateStmt->close();
            
            // Insert new face registration
            $insertStmt = $conn->prepare("
                INSERT INTO user_faces (user_id, face_image_path, face_embedding, is_active)
                VALUES (?, ?, ?, 1)
            ");
            $insertStmt->bind_param("iss", $userId, $targetPath, $faceEmbedding);
            
            if ($insertStmt->execute()) {
                $response['success'] = true;
                $response['message'] = 'Face registered successfully';
                $conn->commit();
            } else {
                throw new Exception('Failed to insert face data');
            }
            
            $insertStmt->close();
        } catch (Exception $e) {
            $conn->rollback();
            $response['message'] = 'Database error: ' . $e->getMessage();
            
            // Clean up the uploaded file if database operation failed
            if (file_exists($targetPath)) {
                unlink($targetPath);
            }
        }
    } else {
        $response['message'] = 'Failed to upload face image';
    }
} else {
    $response['message'] = 'Invalid request';
}

echo json_encode($response);
?>
