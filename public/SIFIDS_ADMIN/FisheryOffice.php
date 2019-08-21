<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class FisheryOffice extends Controller {
    protected $fields = array('fo_id', 'fo_town', 'fo_address', 'fo_email');
    
    // GET method
    protected function get() { //{{{
        $path = $this->request->getPath();
        switch (count($path)) {
            // have ID of fishery office
         case 1:
            $this->results = $this->db->apiGetFisheryOffice((int) $path[0]);
            break;
            
            // no fishery office ID, so all fishery offices
         default:
            $this->results = $this->db->apiGetFisheryOffices();
            break;
        }
    }
    //}}}

    // PUT method
    protected function put() { //{{{
        $results =
          $this->db->apiUpdateFisheryOffice($this->id,
                                            $this->body->fo_town,
                                            $this->body->fo_address,
                                            $this->body->fo_email);
        $this->verifyPut($results, 'apiGetFisheryOffices');
    }
    //}}}

    // POST method
    protected function post() { //{{{
        $results =
          $this->db->apiAddFisheryOffice($this->body->fo_town,
                                         $this->body->fo_address,
                                         $this->body->fo_email);
        $this->verifyPost($results, 'apiGetFisheryOffices');
    }
    //}}}

    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteFisheryOffice($this->id);
        $this->verifyDelete($results, 'apiGetFisheryOffices');
    }
    //}}}
}

?>