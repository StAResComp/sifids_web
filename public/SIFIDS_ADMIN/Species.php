<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Species extends Controller {
    //protected $fields = array('fo_id', 'fo_town', 'fo_address', 'fo_email');
    
    // GET method
    protected function get() { //{{{
        $this->results = $this->db->apiGetSpecies();
    }
    //}}}
}

?>
