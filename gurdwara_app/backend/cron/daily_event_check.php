<?php
// cron/daily_event_check.php
// This script checks events.txt for tomorrow's events and sends push notifications.
// Runs daily via cron at 11:00 AM.
//
// CRONTAB SETUP (run on Debian mini PC):
//   sudo crontab -e
//   Add this line:
//   0 11 * * * /usr/bin/php /var/www/html/api/cron/daily_event_check.php >> /var/log/gurdwara_push.log 2>&1

// === CONFIGURATION ===
define('EVENTS_TXT_PATH', __DIR__ . '/../../events.txt');
define('SEND_PUSH_URL', 'https://www.gurdwarasahibmelaka.com/api/send_push.php');
define('TIMEZONE', 'Asia/Kuala_Lumpur');
define('RUN_HOUR', 13); // Run at 1:00 PM
// ======================

date_default_timezone_set(TIMEZONE);

echo "[" . date('Y-m-d H:i:s') . "] Daily event check started\n";

// Read events.txt
if (!file_exists(EVENTS_TXT_PATH)) {
    echo "[" . date('Y-m-d H:i:s') . "] ERROR: events.txt not found at: " . EVENTS_TXT_PATH . "\n";
    exit(1);
}

$content = file_get_contents(EVENTS_TXT_PATH);
if (empty($content)) {
    echo "[" . date('Y-m-d H:i:s') . "] events.txt is empty\n";
    exit(0);
}

// Parse events (same format as the Flutter app uses)
// Format: Title|YYYY-MM-DD HH:MM|Details|ImagePath(optional)
$lines = explode("\n", $content);
$tomorrowEvents = [];
$tomorrow = date('Y-m-d', strtotime('+1 day'));
$today = date('Y-m-d');

echo "[" . date('Y-m-d H:i:s') . "] Today: $today\n";
echo "[" . date('Y-m-d H:i:s') . "] Looking for events on: $tomorrow\n";

foreach ($lines as $lineNum => $line) {
    $line = trim($line);
    if (empty($line)) continue;
    
    $parts = explode('|', $line);
    if (count($parts) < 3) continue;
    
    $title = trim($parts[0]);
    $dateStr = trim($parts[1]);
    $details = trim($parts[2]);
    
    if (empty($title) || empty($dateStr)) continue;
    
    // Parse the date
    $eventDate = date('Y-m-d', strtotime($dateStr));
    
    if ($eventDate === $tomorrow) {
        $tomorrowEvents[] = [
            'title' => $title,
            'details' => $details,
            'datetime' => $dateStr
        ];
        echo "[" . date('Y-m-d H:i:s') . "] Found tomorrow's event: $title ($dateStr)\n";
    }
}

if (empty($tomorrowEvents)) {
    echo "[" . date('Y-m-d H:i:s') . "] No events scheduled for tomorrow. Nothing to send.\n";
    exit(0);
}

// Send push notifications for each tomorrow event
$successCount = 0;
$failCount = 0;

foreach ($tomorrowEvents as $event) {
    $title = 'GURDWARA SAHIB MELAKA';
    $eventDate = date('d/m/Y', strtotime($event['datetime']));
    $body = $eventDate . ' - ' . $event['title'] . ' ' . $event['details'];
    
    echo "[" . date('Y-m-d H:i:s') . "] Sending push: \"$title: $body\"\n";
    
    // Call send_push.php via HTTP
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, SEND_PUSH_URL . '?' . http_build_query([
        'title' => $title,
        'body' => $body,
        'type' => 'event_reminder'
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 60);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // localhost, OK to disable
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error || $httpCode !== 200) {
        echo "[" . date('Y-m-d H:i:s') . "] FAILED: $error\n";
        $failCount++;
    } else {
        $result = json_decode($response, true);
        $sent = $result['sent'] ?? 0;
        echo "[" . date('Y-m-d H:i:s') . "] Sent to $sent devices: $response\n";
        $successCount++;
    }
    
    // Small delay between notifications
    usleep(500000); // 0.5 seconds
}

echo "[" . date('Y-m-d H:i:s') . "] Daily check complete. Success: $successCount, Failed: $failCount\n";