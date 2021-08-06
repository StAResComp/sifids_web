<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

require_once '../autoload.php';

$dumpActions = ['trips', 'trip_estimates', 'tracks', 'vessels'];
$dumpForm = 'dump.html';

if (isset($_GET['dump']) && in_array($_GET['dump'], $dumpActions)) {
    $dump = new Dump($_GET['dump']);
    
    // optional start/end dates
    if (isset($_GET['start_date'])) {
        $dump->setStartDate($_GET['start_date']);
    }
    
    if (isset($_GET['end_date'])) {
        $dump->setEndDate($_GET['end_date']);
    }
    
    try {
        // generate data and get filename for CSV attachment
        $filename = $dump->generateDump();
        
        // headers for CSV as attachment
        header('Content-type: text/csv');
        header(sprintf('Content-disposition: attachment; filename=%s.csv',
                       $filename));

        print $dump;
    }
    catch (\Exception $e) {
        print $e->getMessage();
    }

    exit;
}
else {
    readfile($dumpForm);
}

?>