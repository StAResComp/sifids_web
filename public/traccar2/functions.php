<?php

declare(strict_types=1);

namespace TRACCAR2;

// add data from JSON object to database
function addData(\stdClass $data) { //{{{
    global $attributes, $db;
    
    $deviceID = 0;
    $timestamp = '';
    
    // need the device time
    if (!isset($data->position->deviceTime)) {
        throw new \Exception('Need time from device');
    }
    
    // need track point
    if (!isset($data->position->latitude) ||
        !isset($data->position->longitude)) {
        throw new \Exception('Need latitude and longitude');
    }
    
    $timestamp = $data->position->deviceTime;
    
    // get device ID
    if (!$results = $db->getDeviceID($data->device->uniqueId)) {
        throw new \Exception('Couldn\'t get device ID');
    }
    
    $deviceID = $results[0]->device_id;
    
    // add attributes
    foreach ($attributes as $name) {
        if (isset($data->position->attributes->$name)) {
            $db->addAttribute($name, 
                              (float) $data->position->attributes->$name,
                              $timestamp, $deviceID);
        }
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