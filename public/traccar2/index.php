<?php

declare(strict_types=1);

namespace TRACCAR2;

require_once '../autoload.php';
require_once 'functions.php';

// allowed major/minor numbers
$allowedMajorMinor = ['020b010a', 'ed650055', 'd72e0055', 'f3630055'];

// IMEIs to forward to new API
$imeis = ['354017112212382',
					'358480085730432',
					'354017112212317',
					'359632104292831',
					'359632104296600',
					'354017112212234',
					'354017112196833',
					'866907053435003'];

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

    file_put_contents('/tmp/traccar.json', 
                      print_r($_POST, true), 
                      FILE_APPEND);
    
    if (!$stdin) {
        throw new \Exception('No input given');
    }
    
    if (!$data = json_decode($stdin)) {
        throw new \Exception('Data not in JSON format');
    }
		
		// pass JSON to new API?
		if (in_array($data->device->uniqueId, $imeis)) {
				newAPI($stdin);
		}
		else {
    
/*    file_put_contents('/home/sifids/dump.json', 
                      json_encode($data, JSON_PRETTY_PRINT), 
                      FILE_APPEND);*/
    
				// convert input JSON string to object and add to database
				addData($data);
		}
}
catch (\Throwable $e) {
    error_log($e->getMessage() . "\n");
}

?>
