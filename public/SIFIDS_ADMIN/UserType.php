<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class UserType extends Controller {
    
    // GET method
    protected function get() { //{{{
        $path = $this->request->getPath();
        switch (count($path)) {
            // have ID of user type
         case 1:
            $this->results = $this->db->apiGetUserType((int) $path[0]);
            break;
            
            // no user type ID, so all user type options
         default:
            $this->results = $this->db->apiGetUserTypes();
            break;
        }
    }
    //}}}
}

?>