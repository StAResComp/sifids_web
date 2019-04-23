<?php

declare(strict_types=1);

namespace SIFIDS;

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
    
    // add device and get ID for it
    if (isset($data->device->name) &&
        isset($data->device->uniqueId) &&
        isset($data->position->protocol)) {
        if (!$results = $db->addDevice($data->device->name,
                                       $data->device->uniqueId,
                                       $data->position->protocol)) {
            throw new \Exception('Problem adding device');
        }
        
        $deviceID = (int) $results[0][0];
    }
    else {
        throw new \Exception('Need device name and unique ID');
    }
    
    // add attributes
    foreach ($attributes as $name) {
        if (isset($data->position->attributes->$name)) {
            $db->addAttribute($name, 
                              (float) $data->position->attributes->$name,
                              $timestamp, $deviceID);
        }
    }
    
    // add track point
    if ($results = $db->addTrack($deviceID,
                                 $data->position->latitude,
                                 $data->position->longitude,
                                 $timestamp)) {
        $tripID = $results[0][0];
        
        printf("%d\t%d\t%f\t%f\t%s\n",
               $tripID, $deviceID,
               $data->position->latitude,
               $data->position->longitude,
               $timestamp);
    }
}
//}}}

?>