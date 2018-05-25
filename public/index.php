<?php

declare(strict_types=1);

namespace SIFIDS;

require_once 'autoload.php';

$db = null;

try {
    // check form params
    if (!isset($_POST['vessel_name']) || !isset($_POST['tracks'])) {
        throw new \Exception('Missing form params');
    }
    
    // write tracks to file
    $filename = tempnam('/tmp', 'sifids');
    if (!$fh = fopen($filename, 'w')) {
        throw new \Exception('Problem opening temp track file for writing');
    }
    
    if (false === fwrite($fh, $_POST['tracks'])) {
        throw new \Exception('Problem writing to temp track file');
    }
    
    fclose($fh);
    
    $db = DB::getInstance(true); // with transaction
    
    // use vessel name to get vessel ID
    if (!$results = $db->insertVessel($_POST['vessel_name'])) {
        throw new \Exception('Problem adding vessel');
    }
    
    $vesselID = (int) $results[0][0];
    
    // record upload
    if (!$results = $db->insertUpload($vesselID)) {
        throw new \Exception('Problem adding upload');
    }
    
    $uploadID = (int) $results[0][0];
    
    // read tracks as CSV file
    if (!$fh = fopen($filename, 'r')) {
        throw new \Exception('Probelm opening temp track file for reading');
    }
    
    // loop over lines in CSV
    while ($line = fgetcsv($fh)) {
        // check that line is long enough
        if (!isset($line[3])) {
            throw new \Exception('Need timestamp, fishing, lat, lon in each line');
        }
        
        // insert point
        if (!$db->insertTrack($uploadID, 
                              $line[0], $line[1], $line[2], $line[3])) {
            //throw new \Exception('Problem adding point to track');
        }
    }
    
    // close and delete temp file
    fclose($fh);
    unlink($filename);
} catch (\Exception $e) {
    header('HTTP/1.0 400 Bad Request', true, 400);
    print $e->getMessage();
    
    if ($db) {
        print_r($db->getErrorInfo());
    }
}

?>