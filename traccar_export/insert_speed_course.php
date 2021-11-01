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

// connect to DB with transaction
$db = DB::getInstance(true);

// array for remembering device IDs from IMEI numbers
$ids = [];

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
				
				// add speed and course
				$db->addAttribute('speed', $row[2], $row[1], $ids[$row[0]]);
				$db->addAttribute('course', $row[3], $row[1], $ids[$row[0]]);
		}
		catch (\Throwable $e) {
				printf("%s\n", $e->getMessage());
				continue;
		}
}

fclose($fh);

?>
