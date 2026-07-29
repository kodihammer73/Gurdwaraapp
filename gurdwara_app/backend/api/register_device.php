<?php
// api/register_device.php
// Endpoint for Flutter app to register FCM device tokens
// Place this file at: https://www.gurdwarasahibmelaka.com/api/register_device.php

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// Database configuration
$db_file = __DIR__ . '/../data/devices.db';

// Ensure data directory exists
$data_dir = dirname($db_file);
if (!is_dir($data_dir)) {
    mkdir($data_dir, 0755, true);
}

// Get POST data
$input = $_POST;

// Also try to read JSON body
if (empty($input)) {
    $json = file_get_contents('php://input');
    $input = json_decode($json, true) ?? [];
}

$token = trim($input['token'] ?? '');
$platform = trim($input['platform'] ?? 'android');
$app_version = trim($input['app_version'] ?? '1.0.0');

if (empty($token)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Token is required']);
    exit;
}

try {
    // Ensure data directory exists with proper permissions
    $data_dir = dirname($db_file);
    if (!is_dir($data_dir)) {
        if (!mkdir($data_dir, 0755, true)) {
            throw new Exception('Failed to create data directory: ' . $data_dir);
        }
    }
    
    // Check if SQLite3 extension is available
    if (!class_exists('SQLite3')) {
        throw new Exception('SQLite3 PHP extension is not installed. Run: sudo apt install php-sqlite3');
    }
    
    $db = new SQLite3($db_file);
    $db->enableExceptions(true);
    
    // Create table if not exists
    $db->exec("
        CREATE TABLE IF NOT EXISTS device_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            token TEXT UNIQUE NOT NULL,
            platform TEXT DEFAULT 'android',
            app_version TEXT DEFAULT '1.0.0',
            last_active DATETIME DEFAULT CURRENT_TIMESTAMP,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ");
    
    // Upsert token
    $stmt = $db->prepare("
        INSERT INTO device_tokens (token, platform, app_version, last_active)
        VALUES (:token, :platform, :app_version, datetime('now'))
        ON CONFLICT(token) DO UPDATE SET
            last_active = datetime('now'),
            platform = :platform,
            app_version = :app_version
    ");
    
    $stmt->bindValue(':token', $token, SQLITE3_TEXT);
    $stmt->bindValue(':platform', $platform, SQLITE3_TEXT);
    $stmt->bindValue(':app_version', $app_version, SQLITE3_TEXT);
    $stmt->execute();
    
    // Clean up old tokens (older than 6 months)
    $db->exec("DELETE FROM device_tokens WHERE last_active < datetime('now', '-6 months')");
    
    $count = $db->querySingle("SELECT COUNT(*) FROM device_tokens");
    
    echo json_encode([
        'success' => true,
        'message' => 'Device registered successfully',
        'total_devices' => (int)$count
    ]);
    
    $db->close();
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
}