<?php

declare(strict_types=1);

namespace TRACCAR;

require_once '../autoload.php';
require_once 'functions.php';

// attributes of device to record in database
$attributes = array('power', 'distance', 'totalDistance');

try {
    $db = DB::getInstance(true, 'traccar');

    while (($stdin = fgets(STDIN)) != false) {
        if ($data = json_decode($stdin)) {
            addData($data);
        }
    }
}
catch (\Throwable $e) {
    die($e->getMessage() . "\n");
}

?>