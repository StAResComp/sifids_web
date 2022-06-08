#!/usr/bin/php
<?php

declare(strict_types=1);

namespace TRACCAR2;

require_once '../public/autoload.php';
require_once '../public/traccar2/functions.php';

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
    
    $json->position->deviceTime = $row[1];
    $json->position->uniqueId = $row[0];
    $json->position->attributes = json_decode(str_replace('|', ',', $row[2]));
    $json->position->latitude = (float) $row[3];
    $json->position->longitude = (float) $row[4];
    $json->position->valid = 't' == $row[5] ? 1 : 0;
    
    return $json;
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
while (false !== ($row = fgetcsv($fh))) {
		try {
				// remember device IDs from IMEIs
				if (!isset($ids[$row[0]])) {
						$ids[$row[0]] = getID($row[0]);
				}
				
        printf("%s %s\n", $row[0], $row[1]);
        
        $json = makeJSON($row);
        addData($json);
		}
		catch (\Throwable $e) {
				printf("%s\n", $e->getMessage());
				continue;
		}
}

fclose($fh);

?>
