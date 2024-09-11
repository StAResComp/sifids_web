<?php

declare(strict_types=1);

namespace TRACCAR2;

// post JSON to new API
function newAPI(string $json) { //{{{
		// API endpoint to post JSON to
		$url = 'https://localhost/api/traccar_position/';
		
		// post JSON but don't check host/cert
		$opts = [CURLOPT_HTTPHEADER =>
						 ['Content-Type: application/json'],
						 CURLOPT_POST => true,
						 CURLOPT_RETURNTRANSFER => true,
						 CURLOPT_SSL_VERIFYPEER => false,
						 CURLOPT_SSL_VERIFYHOST => false,
						 CURLOPT_POSTFIELDS => $json];
		
		$curl = curl_init($url);
		curl_setopt_array($curl, $opts);
		$ret = curl_exec($curl);
		
		// throw exception if 201 isn't response code
		if (201 != (int) curl_getinfo($curl, CURLINFO_RESPONSE_CODE)) {
				throw new \Exception(curl_error($curl));
		}
}
//}}}

// connect to given database using ~/.pgpass
function dbConnect(string $host, string $db, string $user, int $port=5432) : \PDO { //{{{
    $pw = '';
    $pgpass = file('/home/sifids/.pgpass', FILE_IGNORE_NEW_LINES);
    foreach ($pgpass as $line) {
        $cells = explode(':', $line);
        if ($cells[0] != $host || $cells[1] != $port ||
            $cells[2] != $db || $cells[3] != $user) {
            continue;
        }
        
        $pw = $cells[4];
        break;
    }
    
    return new \PDO(sprintf('pgsql:host=%s;port=%d;dbname=%s',
                            $host, $port, $db), $user, $pw);
}
//}}}

function slice(string $str, int $p) : array { //{{{
    return [substr($str, 0, $p), substr($str, $p)];
}
//}}}

// parse io385 data and add to database
function io385(string $data, int $deviceID, string $timestamp) { //{{{
    global $db, $allowedMajorMinor;
    
    // strip of first 2 characters
    list($ignore, $data) = slice($data, 2);
    
    while ($data) {
        // read BLE
        list($ble, $data) = slice($data, 2);
        $ble = (int) base_convert($ble, 16, 10);
        
        $signalPresent = (bool) $ble & 1;
        $format = $ble & 32 == 32 ? 'iBeacon' : 'Eddystone';
        
        switch ($format) {
         case 'iBeacon':
            $signal = NULL;
            list($uuid, $data) = slice($data, 32);
            list($major, $data) = slice($data, 4);
            list($minor, $data) = slice($data, 4);
            
            if ($signalPresent) {
                list($signal, $data) = slice($data, 2);
                $signal = (int) base_convert($signal, 16, 10) - 256; // signed 2 complement
            }
            
            // check that major/minor are recognised
            if (in_array($major . $minor, $allowedMajorMinor)) {
                $db->addCoinData($deviceID,
                                 $timestamp,
                                 $uuid, $major, $minor,
                                 $signal);
            }
            
            break;
            
         case 'Eddystone':
            throw new \Exception('Cannot read Eddystone beacon data');
            break;
        }
    }
}
//}}}

// handle new format of io385 event
function event385(\stdClass $attrs, int $deviceID, string $timestamp) { //{{{
    global $db, $allowedMajorMinor;
    
    $fmts = ['uuid' => 'beacon%dUuid', 'major' => 'beacon%dMajor',
             'minor' => 'beacon%dMinor', 'signal' => 'beacon%dRssi'];

    // start beacons at 0
    $b = 0;
    
    while (true) {
        // move to next beacon
        ++ $b;
        
        $values = [];
        
        // check that all values for beacon are present
        foreach ($fmts as $f => $v) {
            $val = sprintf($v, $b);
            if (!isset($attrs-> {$val})) {
                break 2; // missing so finished
            }
            $values[$f] = $attrs->{$val};
            
            switch ($f) {
             case 'major':
             case 'minor':
                $values[$f] = base_convert((string) $values[$f], 10, 16);
                if (1 == strlen($values[$f]) % 2) {
                    $values[$f] = sprintf('0%s', $values[$f]);
                }
                break;
             default:
                break;
            }
        }
        
        // major/minor values not in white list
        if (!in_array($values['major'] . $values['minor'], 
                      $allowedMajorMinor)) {
            printf("%s%s not in %s\n", $values['major'], $values['minor'], 
                   implode(',', $allowedMajorMinor));
            continue;
        }
        
        // add to database
        $db->addCoinData($deviceID,
                         $timestamp,
                         $values['uuid'], $values['major'], $values['minor'],
                         $values['signal']);
    }
}
//}}}

// add data from JSON object to database
function addData(\stdClass $data) { //{{{
    global $attributes, $db;
    
    $deviceID = 0;
    $timestamp = '';
    
    // need the device time
    if (!isset($data->position->deviceTime)) {
        throw new \Exception('Need time from device');
    }

    // get device ID
    if (!$results = $db->getDeviceID($data->device->uniqueId)) {
        throw new \Exception(sprintf('Couldn\'t get device ID %s', 
                                     $data->device->uniqueId));
    }
    
    $deviceID = $results[0]->device_id;
    
    $timestamp = $data->position->deviceTime;
    
    // check for event io385 - bluetooth coin data
    if (isset($data->position->attributes->io385) &&
        strlen($data->position->attributes->io385) > 2) {
        io385($data->position->attributes->io385, $deviceID, $timestamp);
    }

    if (isset($data->position->attributes->event) &&
        385 == $data->position->attributes->event) {
        event385($data->position->attributes, $deviceID, $timestamp);
    }

    // add attributes
    foreach ($attributes as $name) {
        if (isset($data->position->attributes->$name)) {
            $db->addAttribute($name, 
                              (float) $data->position->attributes->$name,
                              $timestamp, $deviceID);
        }
    }
    
    // if no track point then finished
    if (!isset($data->position->latitude) ||
        !isset($data->position->longitude)) {
        //throw new \Exception('Need latitude and longitude');
        return;
    }
    
    // get trip ID, possibly creating new trip
    if (!$results = $db->getTripID($deviceID, $timestamp)) {
        throw new \Exception('Problem getting trip ID');
    }
    
    $tripID = $results[0]->trip_id;
    
    // is track point valid
    $isValid = 'true' == $data->position->valid ? 1 : 0;
    
    // add track point
    if (!$results = $db->addTraccarTrack($tripID,
                                         $data->position->latitude,
                                         $data->position->longitude,
                                         $timestamp,
                                         $isValid)) {
        throw new \Exception('Problem adding track point');
    }
}
//}}}

?>