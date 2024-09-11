<?php

declare(strict_types=1);

namespace TRACCAR2;

require_once '../autoload.php';
require_once 'functions.php';

// map Traccar device IDs to our device IDs
$ids = ['63' => 59, '87' => 70, '97' => 63, '90' => 72, 
        '9' => 8, '19' => 43, '95' => 62, '92' => 73];

// which major/minor numbers are allowed
$allowedMajorMinor = ['020b010a'];

// SQL to get event 385 attributes for devices with timestamps
$sql = <<<EOT
  SELECT deviceid, fixtime, attributes 
    FROM tc_positions 
   WHERE deviceid in (63, 87, 97, 90, 9, 19, 95, 92) AND 
         fixtime > '2023-06-28' AND 
         attributes LIKE '%beacon1Uuid%' 
ORDER BY deviceid ASC, fixtime ASC
EOT;

try {
    // connect to our database
    $db = DB::getInstance(true);
    
    // connect to Traccar database
    $trac = dbConnect('juve.st-andrews.ac.uk', 'traccar_2023', 'traccar');
    
    $stmt = $trac->query($sql, \PDO::FETCH_NUM);
    
    // loop over rows
    foreach ($stmt as $line) {
        if (!isset($ids[$line[0]])) {
            printf("%d not in ids\n", $line[0]);
            continue;
        }
        
        $id = $ids[$line[0]];
        
        event385(json_decode($line[2]), $id, $line[1]);
        printf("Added %s for device %d\n", $line[1], $id);
    }
}
catch (\Throwable $e) {
    die($e->getMessage() . "\n");
}

?>