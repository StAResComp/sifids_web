<?php

declare(strict_types=1);

namespace SIFIDS;

require_once '../autoload.php';
require_once 'functions.php';

// attributes of device to record in database
$attributes = array('power', 'distance', 'totalDistance');

try {
    $db = DB::getInstance(true, 'traccar');
    $stdin = stream_get_contents(STDIN);
    
    if (!$stdin) {
        throw new \Exception('No input');
    }
    
    if (!$data = json_decode($stdin)) {
        throw new \Exception('Data not in JSON format');
    }
    
    //print json_encode($data, JSON_PRETTY_PRINT);
    // convert input JSON string to object and add to database
    addData($data);
}
catch (\Throwable $e) {
    die($e->getMessage() . "\n");
}

?>