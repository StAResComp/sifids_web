<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

// days since last trip
class Trip extends Controller {
    protected $fields = array();
    
    // GET method
    protected function get() { //{{{
        $this->results = $this->db->apiDaysSinceTrip();
    }
    //}}}
}

?>
