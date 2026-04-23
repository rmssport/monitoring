<?php
require '/opt/librenms/vendor/autoload.php';
$app = require_once '/opt/librenms/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
$devices = DB::table('devices')->select('device_id','hostname','snmp_disable','os')->orderBy('hostname')->get();
foreach ($devices as $d) {
    echo $d->device_id . ' | ' . $d->hostname . ' | snmp_off=' . $d->snmp_disable . ' | ' . $d->os . "\n";
}
