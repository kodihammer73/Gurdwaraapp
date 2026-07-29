<?php
// api/send_push.php
// Send push notifications using Firebase Cloud Messaging V1 API (HTTP v1)
// Uses a Firebase service account for OAuth2 authentication
// 
// Usage: https://www.gurdwarasahibmelaka.com/api/send_push.php?title=Event&body=Details
// Or POST with title and body parameters

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// === CONFIGURATION ===
// 1. Go to Firebase Console > Project Settings > Service Accounts
// 2. Click "Generate New Private Key" (downloads a JSON file)
// 3. Save the JSON file to: /var/www/html/api/firebase-service-account.json
define('FCM_SERVICE_ACCOUNT_FILE', __DIR__ . '/gsmelaka1925-firebase-adminsdk-fbsvc-acaee1b0b4.json');
define('DB_FILE', __DIR__ . '/../data/devices.db');
define('PROJECT_ID', 'gsmelaka1925');
// ======================

// Get parameters from GET or POST
$title = trim($_REQUEST['title'] ?? '');
$body = trim($_REQUEST['body'] ?? '');
$type = trim($_REQUEST['type'] ?? 'announcement');

if (empty($title)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Title is required']);
    exit;
}

if (empty($body)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Body is required']);
    exit;
}

// Check if service account file exists
if (!file_exists(FCM_SERVICE_ACCOUNT_FILE)) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Firebase service account file not found',
        'fix' => 'Download from Firebase Console > Project Settings > Service Accounts > Generate New Private Key',
        'path' => FCM_SERVICE_ACCOUNT_FILE
    ]);
    exit;
}

// Get all registered device tokens
$tokens = getDeviceTokens();

if (empty($tokens)) {
    echo json_encode([
        'success' => true,
        'message' => 'No registered devices to notify',
        'sent' => 0,
        'total' => 0
    ]);
    exit;
}

// Get OAuth2 access token from service account
$accessToken = getAccessToken();
if (!$accessToken) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Failed to get OAuth2 access token']);
    exit;
}

// Send to each token
$successCount = 0;
$failureCount = 0;
$errors = [];

foreach ($tokens as $token) {
    $result = sendFCMV1($accessToken, $token, $title, $body, $type);
    if ($result['success']) {
        $successCount++;
    } else {
        $failureCount++;
        $errors[] = [
            'token' => substr($token, 0, 20) . '...',
            'http_code' => $result['http_code'] ?? 'unknown',
            'error' => $result['response']['error']['message'] ?? $result['error'] ?? 'unknown'
        ];
    }
}

echo json_encode([
    'success' => true,
    'message' => "Notification sent to $successCount devices",
    'sent' => $successCount,
    'failed' => $failureCount,
    'total' => count($tokens),
    'errors' => $errors
]);

// =============================================
// FUNCTIONS
// =============================================

/**
 * Get all device tokens from database
 */
function getDeviceTokens() {
    if (!file_exists(DB_FILE)) {
        return [];
    }
    
    try {
        $db = new SQLite3(DB_FILE);
        $results = $db->query("SELECT token FROM device_tokens WHERE last_active > datetime('now', '-3 months')");
        
        $tokens = [];
        while ($row = $results->fetchArray(SQLITE3_ASSOC)) {
            if (!empty($row['token'])) {
                $tokens[] = $row['token'];
            }
        }
        
        $db->close();
        return $tokens;
    } catch (Exception $e) {
        error_log('Error reading device tokens: ' . $e->getMessage());
        return [];
    }
}

/**
 * Get OAuth2 access token using the Firebase service account (JWT)
 */
function getAccessToken() {
    $serviceAccount = json_decode(file_get_contents(FCM_SERVICE_ACCOUNT_FILE), true);
    if (!$serviceAccount || !isset($serviceAccount['client_email'])) {
        error_log('Invalid service account file');
        return null;
    }
    
    $clientEmail = $serviceAccount['client_email'];
    $privateKey = $serviceAccount['private_key'];
    
    // Create JWT
    $now = time();
    $header = [
        'alg' => 'RS256',
        'typ' => 'JWT'
    ];
    
    $payload = [
        'iss' => $clientEmail,
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'exp' => $now + 3600,
        'iat' => $now
    ];
    
    // Encode JWT
    $base64Header = rtrim(strtr(base64_encode(json_encode($header)), '+/', '-_'), '=');
    $base64Payload = rtrim(strtr(base64_encode(json_encode($payload)), '+/', '-_'), '=');
    
    $signature = '';
    openssl_sign("$base64Header.$base64Payload", $signature, $privateKey, 'sha256WithRSAEncryption');
    $base64Signature = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
    
    $jwt = "$base64Header.$base64Payload.$base64Signature";
    
    // Exchange JWT for access token
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode !== 200) {
        error_log('Failed to get access token: ' . $response);
        return null;
    }
    
    $result = json_decode($response, true);
    return $result['access_token'] ?? null;
}

/**
 * Send notification via FCM V1 HTTP API
 */
function sendFCMV1($accessToken, $deviceToken, $title, $body, $type = 'announcement') {
    $message = [
        'message' => [
            'token' => $deviceToken,
            'notification' => [
                'title' => $title,
                'body' => $body
            ],
            'android' => [
                'notification' => [
                    'channel_id' => 'event_channel',
                    'sound' => 'default'
                ]
            ],
            'apns' => [
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => 1
                    ]
                ]
            ],
            'data' => [
                'type' => $type,
                'title' => $title,
                'body' => $body,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK'
            ]
        ]
    ];
    
    $url = 'https://fcm.googleapis.com/v1/projects/' . PROJECT_ID . '/messages:send';
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($message));
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        error_log("FCM V1 curl error for token $deviceToken: $error");
        return ['success' => false, 'error' => $error];
    }
    
    $decoded = json_decode($response, true);
    error_log("FCM V1 response for token $deviceToken: HTTP $httpCode, Response: " . $response);
    
    return [
        'success' => $httpCode === 200,
        'http_code' => $httpCode,
        'response' => $decoded
    ];
}