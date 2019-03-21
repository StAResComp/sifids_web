<?php

declare(strict_types=1);

namespace SIFIDS;

require_once '../autoload.php';

$db = null;

define('SIFIDS_FILE_ERROR', 1);
define('SIFIDS_DB_ERROR', 2);
define('SIFIDS_USER_ERROR', 3);
define('SIFIDS_OK', 10);

// track uploaded
function tracks(string $vesselName, string $tracks) { //{{{
    global $db;
    
    // write tracks to file
    $filename = tempnam('/tmp', 'sifids');
    if (!$fh = fopen($filename, 'w')) {
        throw new \Exception('Problem opening temp track file for writing', 
                             SIFIDS_FILE_ERROR);
    }
    
    if (false === fwrite($fh, $tracks)) {
        throw new \Exception('Problem writing to temp track file', 
                             SIFIDS_FILE_ERROR);
    }
    
    fclose($fh);
    
    $db = DB::getInstance(true, 'peru'); // with transaction, using 'peru' schema
    
    // use vessel name to get vessel ID
    if (!$results = $db->insertVessel($vesselName)) {
        throw new \Exception('Problem adding vessel', SIFIDS_DB_ERROR);
    }
    
    $vesselID = (int) $results[0][0];
    
    // record upload
    if (!$results = $db->insertUpload($vesselID)) {
        throw new \Exception('Problem adding upload', SIFIDS_DB_ERROR);
    }
    
    $uploadID = (int) $results[0][0];
    
    // read tracks as CSV file
    if (!$fh = fopen($filename, 'r')) {
        throw new \Exception('Probelm opening temp track file for reading', 
                             SIFIDS_FILE_ERROR);
    }
    
    // loop over lines in CSV
    while ($line = fgetcsv($fh)) {
        // check that line is long enough
        if (!isset($line[4])) {
            throw new \Exception('Need timestamp, fishing, lat, lon and accuracy in each line', 
                                 SIFIDS_USER_ERROR);
        }
        
        // insert point - don't care about success or not
        $db->insertTrack($uploadID, $line[0], $line[1], $line[2], $line[3], $line[4]);
    }
    
    // close and delete temp file
    fclose($fh);
    unlink($filename);
    
    throw new \Exception('Tracks added', SIFIDS_OK);
}
//}}}

// observation uploaded
function observation(array $fields) { ///{{{
    global $db;
    
    if (empty($fields['pln']) || empty($fields['species']) ||
        (empty($fields['count']) && empty($fields['weight']))) {
        throw new \Exception('Missing pln/species/count/weight for observation', 
                             SIFIDS_USER_ERROR);
    }
    
    $db = DB::getInstance(true, 'peru'); // with transaction
    
    // use vessel name to get vessel ID
    if (!$results = $db->insertVessel($fields['pln'])) {
        throw new \Exception('Problem adding vessel', SIFIDS_DB_ERROR);
    }
    
    $vesselID = (int) $results[0][0];
    
    // record upload
    if (!$results = $db->insertObservationUpload($vesselID)) {
        throw new \Exception('Problem adding upload', SIFIDS_DB_ERROR);
    }
    
    $uploadID = (int) $results[0][0];
    
    // get species ID
    $speciesID = null;
    
    if (!$results = $db->insertSpecies($fields['species'])) {
        throw new \Exception('Problem adding species', SIFIDS_DB_ERROR);
    }
        
    $speciesID = (int) $results[0][0];
    
    // insert observation
    if (!$results = $db->insertObservation($uploadID, $speciesID,
                                           $fields['count'], $fields['weight'])) {
        throw new \Exception('Problem adding observation', SIFIDS_DB_ERROR);
    }
    
    throw new \Exception('Observation added', SIFIDS_OK);
}
//}}}

// consent data
function consent(array $fields) { //{{{
    global $db;
    
    // make sure that these fields all have 'true' in them
    $tFields = array('consent_read_understand', 'consent_questions_opportunity',
                     'consent_questions_answered', 'consent_can_withdraw',
                     'consent_confidential', 'consent_data_archiving',
                     'consent_risks', 'consent_take_part',
                     'consent_photography_capture', 'consent_photography_publication',
                     'consent_photography_future_studies', 'consent_fish_1');
    
    foreach ($tFields as $tf) {
        if (!isset($fields[$tf]) || 'true' != $fields[$tf]) {
            throw new \Exception('Consent field missing or not true',
                                 SIFIDS_USER_ERROR);
        }
    }
    
    // optional fields - set to empty if missing
    $oFields = array('consent_name', 'consent_email', 'consent_phone',
                     'pref_vessel_name', 'pref_owner_master_name');
    
    foreach ($oFields as $of) {
        if (!isset($fields[$of])) {
            $fields[$of] = '';
        }
    }
    
    // use vessel PLN to get vessel ID
    if (!isset($fields['pref_vessel_pln'])) {
        throw new \Exception('Missing PLN field', SIFIDS_USER_ERROR);
    }
    
    $db = DB::getInstance(true, 'peru'); // with transaction
    
    if (!$results = $db->insertVessel($fields['pref_vessel_pln'])) {
        throw new \Exception('Problem adding vessel', SIFIDS_DB_ERROR);
    }
    
    $vesselID = (int) $results[0][0];

    // insert consent information
    if (!$results = $db->insertConsent($vesselID, 
                                       $fields['consent_name'],
                                       $fields['consent_email'], 
                                       $fields['consent_phone'],
                                       $fields['pref_vessel_name'],
                                       $fields['pref_owner_master_name'])) {
        throw new \Exception('Problem adding consent information', 
                             SIFIDS_DB_ERROR);
    }
    
    throw new \Exception('Consent added', SIFIDS_OK);
}
//}}}

// form uploaded
function form(string $form) { //{{{
    global $db;
    
    // write form to file
    $filename = tempnam('/tmp', 'sifids');
    if (!$fh = fopen($filename, 'w')) {
        throw new \Exception('Problem opening temp form file for writing', 
                             SIFIDS_FILE_ERROR);
    }
    
    if (false === fwrite($fh, $form)) {
        throw new \Exception('Problem writing to temp form file', 
                             SIFIDS_FILE_ERROR);
    }
    
    fclose($fh);
    
    // read form as CSV file
    if (!$fh = fopen($filename, 'r')) {
        throw new \Exception('Problem opening temp form file for reading', 
                             SIFIDS_FILE_ERROR);
    }
    
    // header data
    $headerFields = array('upload_id' => null,
                          'port_of_departure' => null, 'port_of_landing' => null,
                          'pln' => null, 'vessel_name' => null, 
                          'owner_master' => null, 'address' => null);
    $translatedFields = array('Puerto de embarque' => 'port_of_departure',
                              'Puerto de desembarque' => 'port_of_landing',
                              'PLN' => 'pln',
                              'Nombre de la embarcación' => 'vessel_name',
                              'Nombre del patrón' => 'owner_master',
                              'Dirección' => 'address',
                              'Port of Departure' => 'port_of_departure',
                              'Port of Landing' => 'port_of_landing',
                              'Vessel Name' => 'vessel_name',
                              'Owner/Master' => 'owner_master',
                              'Address' => 'address');
    $headerKeys = array_keys($headerFields);
    $headerFmt = '/^# ([^:]+):\s*(.*)$/';
    
    $db = DB::getInstance(true, 'peru');
    
    // start reading in lines in full
    while ($line = fgets($fh)) {
        $line = trim($line);
        $matches = array();
        
        // if blank line or match fails, then finished with header
        if (!$line || !preg_match($headerFmt, $line, $matches)) {
            break;
        }
        
        // skip lines with no value - will use null default
        if (!$matches[2]) {
            continue;
        }
        
        $value = $matches[2];
        
        // translate field name and make sure it is valid
        $fieldName = isset($translatedFields[$matches[1]]) ? 
          $translatedFields[$matches[1]] : null;
        
        if (!in_array($fieldName, $headerKeys)) {
            throw new \Exception('Unrecognised header field - ' . $matches[1], 
                                 SIFIDS_USER_ERROR);
        }
        
        // repeated field, keep first value
        if ('' != $headerFields[$fieldName]) {
            continue;
        }
        
        // use PLN to get vessel ID
        if ('pln' == $fieldName) {
            if (!$results = $db->insertVessel($value)) {
                throw new \Exception('Problem adding vessel', SIFIDS_DB_ERROR);
            }
            
            $value = (int) $results[0][0];
        }
        
        $headerFields[$fieldName] = $value;
    }

    // make sure that PLN (now vessel ID) was present
    if (!$headerFields['pln']) {
        throw new \Exception('Need PLN for form', SIFIDS_USER_ERROR);
    }

    // record upload
    if (!$results = $db->insertUpload($headerFields['pln'])) {
        throw new \Exception('Problem adding upload', SIFIDS_DB_ERROR);
    }
    
    $headerFields['upload_id'] = (int) $results[0][0];
    
    // record header fields
    if (!$results = call_user_func_array(array($db, 'addFormHeader'),
                                         $headerFields)) {
        throw new \Exception('Problem adding form header', 
                             SIFIDS_DB_ERROR);
    }

    // headings for row data
    $rowFields = fgetcsv($fh);
    
    // fields for row
    $rowCols = array(0, 1, 2, 15, 16, 3, 17);
    $fishCols = array(4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
    $potaCol = 15;
    
    // check to see if app includes column for Pota
    if (in_array('Pota', $rowFields)) {
        $fishCols[] = $potaCol;
        
        // increment row columns which come after column for Pota
        foreach ($rowCols as $r => $v) {
            if ($rowCols[$r] >= $potaCol) {
                $rowCols[$r] ++;
            }
        }
    }
    
    // loop over lines in CSV
    while ($line = fgetcsv($fh)) {
        $rowData = array($headerFields['upload_id']);
        
        foreach ($rowCols as $i) {
            $rowData[] = 
              isset($line[$i]) && '' != $line[$i] && 'Not Given' != $line[$i] ?
              $line[$i] : null;
        }
        
        // add row to database
        if (!$results = call_user_func_array(array($db, 'addFormRow'),
                                             $rowData)) {
            throw new \Exception('Problem adding form row data',
                                 SIFIDS_DB_ERROR);
        }
        
        $rowID = $results[0][0];

        // loop over species columns in line
        foreach ($fishCols as $i) {
            if (!isset($line[$i]) || !$line[$i]) {
                continue;
            }
            
            // get species ID
            if (!$results = $db->insertSpecies($rowFields[$i])) {
                throw new \Exception('Problem adding species', SIFIDS_DB_ERROR);
            }
            
            $fishData = array($rowID, $results[0][0], $line[$i]);
            
            if (!$results = call_user_func_array(array($db, 'addFormRowFish'),
                                                 $fishData)) {
                throw new \Exception('Problem adding fish row data', 
                                     SIFIDS_DB_ERROR);
            }
        }
    }
    
    // close and delete temp file
    fclose($fh);
    unlink($filename);
    
    throw new \Exception('Form added', SIFIDS_OK);
}
//}}}

try {
    // track upload
    if (isset($_POST['vessel_name']) && isset($_POST['tracks'])) {
        tracks($_POST['vessel_name'], $_POST['tracks']);
    }
    // fish1 form upload
    elseif (isset($_POST['fish_1_form'])) {
        form($_POST['fish_1_form']);
    }
    // JSON data upload
    elseif ($input = file_get_contents('php://input')) {
        $json = json_decode($input, true);
        // species field suggests observation
        if (isset($json['species'])) {
            observation($json);
        }
        // consent_read_understand field suggests consent
        elseif (isset($json['consent_read_understand'])) {
            consent($json);
        }
        else {
            throw new \Exception('Unrecognised data', SIFIDS_USER_ERROR);
        }
    }
    // error
    else {
        throw new \Exception('Missing form params', SIFIDS_USER_ERROR);
    }
} catch (\Exception $e) {
    // some error, so send 400 status
    if (SIFIDS_OK != $e->getCode()) {
        header('HTTP/1.0 400 Bad Request', true, 400);
    }

    $message = $e->getMessage();
    
    switch ($e->getCode()) {
     case SIFIDS_OK:
        break;
        
     case SIFIDS_FILE_ERROR:
        $message = sprintf('File error: %s', $message);
        break;
        
     case SIFIDS_DB_ERROR:
        $message = sprintf('Database error: %s (%s)', $message,
                           /*$db ? $db->errorInfo()[2] :*/ '');
        break;
        
     case SIFIDS_USER_ERROR:
        $message = sprintf('User error: %s', $message);
        break;
        
     default:
        break;
    }
    
    header('Content-type: application/javascript; charset=utf-8');
    print json_encode(array('message' => $message));
}

?>