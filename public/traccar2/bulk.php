<?php

declare(strict_types=1);

namespace TRACCAR2;

require_once '../autoload.php';
require_once 'functions.php';

// attributes of device to record in database
//$attributes = array('power', 'distance', 'totalDistance');
$attributes = [];

// allowed major/minor numbers
//$allowedMajorMinor = ['020b010a'];
$allowedMajorMinor = ['020b010a', 'ed650055', 'd72e0055', 'f3630055'];

try {
    $db = DB::getInstance(true);

    // get available attributes
    if (!$results = $db->getAttributes()) {
        throw new \Exception('Problem getting attributes');
    }
    
    foreach ($results as $row) {
        $attributes[] = $row->attribute_name;
    }

    while (($stdin = fgets(STDIN)) != false) {
        if ($data = json_decode($stdin)) {
            addData($data);
        }
        else {
            //throw new \Exception('data not JSON');
        }
    }
}
catch (\Throwable $e) {
    die($e->getMessage() . "\n");
}

?>