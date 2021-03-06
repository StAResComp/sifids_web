<?php

declare(strict_types=1);

namespace SIFIDS;

require_once 'autoload.php';

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
    
    $db = DB::getInstance(true); // with transaction
    
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
    
    if (empty($fields['timestamp']) || empty($fields['animal']) ||
        empty($fields['latitude']) || empty($fields['longitude'])) {
        throw new \Exception('Missing timestamp/animal/lat/lon for observation', 
                             SIFIDS_USER_ERROR);
    }
    
    // default values for fields
    $defaults = array('pln' => 'anon', 'species' => null, 'count' => 1, 
                      'notes' => '');
    
    foreach ($defaults as $k => $v) {
        $fields[$k] = !empty($fields[$k]) ? $fields[$k] : $v;
    }

    $db = DB::getInstance(true); // with transaction
    
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
    
    // get animal ID
    if (!$results = $db->insertAnimal($fields['animal'])) {
        throw new \Exception('Problem adding animal', SIFIDS_DB_ERROR);
    }
    
    $animalID = (int) $results[0][0];
    
    // get species ID
    $speciesID = null;
    
    if ($fields['species']) {
        if (!$results = $db->insertSpecies($fields['species'])) {
            throw new \Exception('Problem adding species', SIFIDS_DB_ERROR);
        }
        
        $speciesID = (int) $results[0][0];
    }
    
    // insert observation
    if (!$results = $db->insertObservation($uploadID, $fields['timestamp'], 
                                           $fields['latitude'], $fields['longitude'],
                                           $animalID, $speciesID,
                                           $fields['count'], $fields['notes'])) {
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
    
    $db = DB::getInstance(true); // with transaction
    
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

// fish1 form uploaded
function fish1Form(string $form) { //{{{
    global $db;
    
    // write form to file
    $filename = tempnam('/tmp', 'sifids');
    if (!$fh = fopen($filename, 'w')) {
        throw new \Exception('Problem opening temp Fish1 form file for writing', 
                             SIFIDS_FILE_ERROR);
    }
    
    if (false === fwrite($fh, $form)) {
        throw new \Exception('Problem writing to temp Fish 1 form file', 
                             SIFIDS_FILE_ERROR);
    }
    
    fclose($fh);
    
    // read form as CSV file
    if (!$fh = fopen($filename, 'r')) {
        throw new \Exception('Problem opening temp Fish 1 form file for reading', 
                             SIFIDS_FILE_ERROR);
    }
    
    // header data
    $headerFields = array('upload_id' => null,
                          'fishery_office' => null, 'email' => null, 
                          'port_of_departure' => null, 'port_of_landing' => null,
                          'pln' => null, 'vessel_name' => null, 
                          'owner_master' => null, 'address' => null, 
                          'total_pots_fishing' => null, 
                          'comment_and_buyers_information' => null);
    $headerKeys = array_keys($headerFields);
    $headerFmt = '/^# ([^:]+):\s*(.*)$/';
    
    $db = DB::getInstance(true);
    
    // start reading in lines in full
    while ($line = fgets($fh)) {
        $line = trim($line);
        $matches = array();
        
        // if blank line or match fails, then finished with header
        if (!$line || !preg_match($headerFmt, $line, $matches)) {
            if (!isset($headerFields['pln'])) {
                throw new \Exception('Need PLN for Fish 1 form', SIFIDS_USER_ERROR);
            }
            
            break;
        }
        
        $value = $matches[2];
        
        // generate field name and make sure it is valid
        $fieldName = str_replace(array(' ', '/'), '_', 
                                 strtolower($matches[1]));
        if (!in_array($fieldName, $headerKeys)) {
            throw new \Exception('Unrecognised header field - ' . $fieldName, 
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
        throw new \Exception('Need PLN for Fish 1 form', SIFIDS_USER_ERROR);
    }

    // record upload
    if (!$results = $db->insertUpload($headerFields['pln'])) {
        throw new \Exception('Problem adding upload', SIFIDS_DB_ERROR);
    }
    
    $headerFields['upload_id'] = (int) $results[0][0];
    
    // record header fields
    if (!$results != call_user_func_array(array($db, 'addFish1FormHeader'),
                                          $headerFields)) {
        throw new \Exception('Problem adding Fish 1 form header', 
                             SIFIDS_DB_ERROR);
    }

    // discard headings for row data
    $line = fgets($fh);
    $line = fgets($fh);
    
    // loop over lines in CSV
    while ($line = fgetcsv($fh)) {
        $rowData = array($headerFields['upload_id']);
        
        foreach ($line as $i => $col) {
            switch ($col) {
                // empty strings become null
             case '':
                $col = null;
                break;
                
                // true/false in DIS/BMS fields become ints (1/0)
             case 'true':
             case 'false':
                if (9 == $i || 10 == $i) {
                    $col = (int) ('true' == $col);
                }
                break;
            }
            
            $rowData[] = $col;
        }
        
        // add row to database
        if (!$results = call_user_func_array(array($db, 'addFish1FormRow'),
                                             $rowData)) {
            throw new \Exception('Problem adding Fish 1 form row data',
                                 SIFIDS_DB_ERROR);
        }
    }
    
    // close and delete temp file
    fclose($fh);
    unlink($filename);
    
    throw new \Exception('Fish 1 form added', SIFIDS_OK);
}
//}}}

try {
    // track upload
    if (isset($_POST['vessel_name']) && isset($_POST['tracks'])) {
        tracks($_POST['vessel_name'], $_POST['tracks']);
    }
    // fish1 form upload
    elseif (isset($_POST['fish_1_form'])) {
        fish1Form($_POST['fish_1_form']);
    }
    // JSON data upload
    elseif ($input = file_get_contents('php://input')) {
        $json = json_decode($input, true);
        // animal field suggests observation
        if (isset($json['animal'])) {
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
                           $db ? $db->errorInfo()[2] : '');
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