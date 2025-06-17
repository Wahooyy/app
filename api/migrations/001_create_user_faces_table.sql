-- Create user_faces table
CREATE TABLE IF NOT EXISTS user_faces (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    face_image_path VARCHAR(255) NOT NULL,
    face_embedding JSON,
    registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES tbl_user(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add comment to the table
ALTER TABLE user_faces COMMENT 'Stores user face recognition data for authentication';

-- Add comments to columns
ALTER TABLE user_faces 
    MODIFY COLUMN face_embedding JSON COMMENT 'Face embedding vector for face recognition',
    MODIFY COLUMN registered_at DATETIME COMMENT 'When the face was registered',
    MODIFY COLUMN is_active BOOLEAN COMMENT 'Whether this face registration is active';

-- Create a trigger to update the registered_at timestamp when a new face is registered
DELIMITER //
CREATE TRIGGER before_user_face_insert
BEFORE INSERT ON user_faces
FOR EACH ROW
BEGIN
    SET NEW.registered_at = NOW();
END//
DELIMITER ;
