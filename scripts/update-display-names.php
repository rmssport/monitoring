<?php
require '/opt/librenms/vendor/autoload.php';
$app = require_once '/opt/librenms/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$mapping = json_decode(file_get_contents('php://stdin'), true);
if (!is_array($mapping)) {
    echo json_encode(['error' => 'Invalid JSON input']);
    exit(1);
}

$updated = 0;
foreach ($mapping as $ip => $name) {
    $affected = DB::table('devices')
        ->where('hostname', $ip)
        ->where(function ($q) use ($name) {
            $q->whereNull('display')->orWhere('display', '!=', $name);
        })
        ->update(['display' => $name]);
    $updated += $affected;
}

echo json_encode(['updated' => $updated, 'total' => count($mapping)]);
