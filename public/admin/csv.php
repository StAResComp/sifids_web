<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

require_once '../autoload.php';

$action = isset($_GET['action']) ? $_GET['action'] : '';

// connect to DB, and want array of arrays fetched
$db = DB::getInstance();
$db->setFetch(\PDO::FETCH_NUM);

$results = [];

// choose stored procedure to execute
switch ($action) {
 case 'vessels':
    $results = $db->apiVesselInfo();
    break;
    
 default:
    break;
}

// have array of results
if ($results && is_array($results)) {
    // header to download output as CSV
    header('Content-type: text/csv');
    header(sprintf('Content-disposition: attachment; filename=%s_%s.csv',
                   $action, date('Y-m-d')));
    
    // output results as CSV
    $fh = fopen('php://output', 'w');
    foreach ($results as $row) {
        fputcsv($fh, $row);
    }
}

?>