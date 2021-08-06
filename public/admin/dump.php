<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

require_once '../autoload.php';

$dumpActions = ['trips', 'tracks', 'vessels'];
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
        $dump->generateDump();
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