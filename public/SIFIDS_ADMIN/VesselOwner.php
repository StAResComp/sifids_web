<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class VesselOwner extends Controller {
    protected $fields = array('owner_id', 'owner_name', 'owner_address');
    
    // GET method
    protected function get() { //{{{
        $path = $this->request->getPath();
        switch (count($path)) {
            // have ID of vessel
         case 1:
            $this->results = $this->db->apiGetVesselOwner((int) $path[0]);
            break;
            
            // no vessel ID, so all vessel owners
         default:
            $this->results = $this->db->apiGetVesselOwners();
            break;
        }
    }
    //}}}
    
    // PUT method
    protected function put() { //{{{
        $results =
          $this->db->apiUpdateVesselOwner($this->id,
                                          $this->body->owner_name,
                                          $this->body->owner_address);
        $this->verifyPut($results, 'apiGetVesselOwners');
    }
    //}}}

    // POST method
    protected function post() { //{{{
        $results =
          $this->db->apiAddVesselOwner($this->body->owner_name,
                                       $this->body->owner_address);
        $this->verifyPost($results, 'apiGetVesselOwners');
    }
    //}}}

    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteVesselOwner($this->id);
        $this->verifyDelete($results, 'apiGetVesselOwners');
    }
    //}}}
}

?>