<?php

declare(strict_types=1);

namespace TRACCAR2;

require_once '../autoload.php';
require_once 'functions.php';

// attributes of device to record in database
$attributes = array(); //'power', 'distance', 'totalDistance', 'sat', 'battery');

try {
    $db = DB::getInstance(true); // with transaction
    
    // get available attributes
    if (!$results = $db->getAttributes()) {
        throw new \Exception('Problem getting attributes');
    }
    
    foreach ($results as $row) {
        $attributes[] = $row->attribute_name;
    }
    
    // get JSON data from STDIN
    $fh = fopen('php://input', 'r');
    $stdin = stream_get_contents($fh);
    fclose($fh);
    
    if (!$stdin) {
        throw new \Exception('No input given');
    }
    
    if (!$data = json_decode($stdin)) {
        throw new \Exception('Data not in JSON format');
    }
    
    /*file_put_contents('/tmp/traccar.json', 
                      json_encode($data, JSON_PRETTY_PRINT), 
                      FILE_APPEND);*/
    
    // convert input JSON string to object and add to database
    addData($data);
}
catch (\Throwable $e) {
    error_log($e->getMessage() . "\n");
}

?>