#!/usr/bin/php
<?php

declare(strict_types=1);

namespace TRACCAR2;

require_once '../public/autoload.php';
require_once '../public/traccar2/functions.php';

// rows per transaction
define('ROWS', 1000);


// read CSV data piped from STDIN

// turn row into JSON object
function makeJSON(array $row) : \stdClass { //{{{
    global $attributes, $ids;
    
    $json = new \stdClass();
    $json->position = new \stdClass();
    $json->device = new \stdClass();
    
    $json->device->uniqueId = $row[0];
    $json->position->deviceTime = $row[1];
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

// remember timestamp
$ts = '';
$r = 0;

// open STDIN
$fh = fopen('php://stdin', 'r');

// loop over lines from STDIN
while (false !== ($row = fgetcsv($fh))) {
		try {
        // same timestamp as last row, so skip
        if ($row[1] == $ts) {
            continue;
        }
        
        $ts = $row[1]; // remember timestamp
        printf("%s %s\n", $row[0], $row[1]);
        
        $json = makeJSON($row);
        addData($json);
        
        // time to refresh transaction
        ++ $r;
        if ($r % ROWS == 0) {
            $db->commit();
            $db->begin();
        }
		}
		catch (\Throwable $e) {
				printf("%s\n", $e->getMessage());
				break;
		}
}

fclose($fh);

?>
