#!/usr/bin/php
<?php

declare(strict_types=1);

namespace TRACCAR2;

require_once '../public/autoload.php';

// read CSV data piped from STDIN

// get device ID using IMEI
function getID(string $imei) : int { //{{{
		global $db;
		
		if (!$results = $db->getDeviceID($imei)) {
				throw new \Exception('Unknown device');
		}
		
		return (int) $results[0]->device_id;
}
//}}}

// turn row into JSON object
function makeJSON(array $row) : \stdClass { //{{{
    global $attributes, $ids;
    
    $json = new \stdClass();
    $json->position = new \stdClass();
    
    $json->position->deviceTime = $row[5];
    $json->position->uniqueId = $row[0];
    $json->position->attributes = json_decode($row[14]);
    $json->position->latitude = (float) $row[8];
    $json->position->longitude = (float) $row[9];
    $json->position->valid = 't' == $row[7] ? 1 : 0;
}
//}}}

// connect to DB with transaction
$db = DB::getInstance(true);

// array for remembering device IDs from IMEI numbers
$ids = [];

// get available attributes
if (!$results = $db->getAttributes()) {
    throw new \Exception('Problem getting attributes');
}

foreach ($results as $row) {
    $attributes[] = $row->attribute_name;
}

// open STDIN
$fh = fopen('php://stdin', 'r');

// loop over lines from STDIN
// IMEI, timestamp, speed, course
while (false !== ($row = fgetcsv($fh))) {
		try {
				// remember device IDs from IMEIs
				if (!isset($ids[$row[0]])) {
						$ids[$row[0]] = getID($row[0]);
				}
				
        $json = makeJSON($row);
        
        print json_encode($json);
        break;
		}
		catch (\Throwable $e) {
				printf("%s\n", $e->getMessage());
				continue;
		}
}

fclose($fh);

?>
