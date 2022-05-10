<?php

declare(strict_types=1);

namespace TRACCAR2;

function slice(string $str, int $p) : array { //{{{
    return [substr($str, 0, $p), substr($str, $p)];
}
//}}}

// parse io385 data and add to database
function io385(string $data, string $deviceID, string $timestamp) { //{{{
    global $db;
    
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
            
            $db->addCoinData($deviceID,
                             $timestamp,
                             $uuid, $major, $minor,
                             $signal);
            
            break;
            
         case 'Eddystone':
            throw new \Exception('Cannot read Eddystone beacon data');
            break;
        }
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