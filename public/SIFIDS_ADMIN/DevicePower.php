<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class DevicePower extends Controller {
    
    // GET method
    protected function get() { //{{{
        $path = $this->request->getPath();
        switch (count($path)) {
            // have ID of device power option
         case 1:
            $this->results = $this->db->apiGetDevicePower((int) $path[0]);
            break;
            
            // no device power ID, so all device power options
         default:
            $this->results = $this->db->apiGetDevicePowers();
            break;
        }
    }
    //}}}
}

?>