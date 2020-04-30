<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Vessel extends Controller {
    protected $fields = array('vessel_id', 'vessel_name', 'vessel_code', 
                              'vessel_pln', 'vessel_length', 'gear_id', 'animal_id',
                              'owner_id', 'fo_id', 'vessel_active');
    
    // GET method
    protected function get() { //{{{
        switch ($this->pathLen) {
            // have ID of vessel
         case 1:
            $this->results = $this->db->apiGetVessel($this->id);
            break;

            // have ID of vessel plus attribute of vessel
         case 2:
            switch ($this->path[1]) {
             case 'vessel_projects':
                $this->results = $this->db->apiGetVesselProjects($this->id);
                break;
            }
            break;
            
            // no vessel ID, so all vessels
         default:
            $this->results = $this->db->apiGetVessels();
            break;
        }
    }
    //}}}
    
    // PUT method
    protected function put() { //{{{
        $results = array();
        $proc = '';
        $args = array();
        
        switch ($this->pathLen) {
            // update vessel details
         case 1:
            $results = 
              $this->db->apiUpdateVessel($this->id,
                                         $this->body->vessel_name,
                                         $this->body->vessel_code,
                                         $this->body->vessel_pln,
                                         $this->body->vessel_length,
                                         (int) $this->body->gear_id ? $this->body->gear_id : null,
                                         (int) $this->body->animal_id ? $this->body->animal_id : null,
                                         (int) $this->body->owner_id ? $this->body->owner_id : null,
                                         (int) $this->body->fo_id ? $this->body->fo_id : null,
                                         (int) $this->body->vessel_active);
            $proc = 'apiGetVessels';
            break;
            
         case 2:
            switch ($this->path[1]) {
             case 'vessel_projects':
                $results = 
                  $this->db->apiUpdateVesselProjects($this->id, 
                                                     $this->array2SQL('vessel_project'));
                
                $proc = 'apiGetVesselProjects';
                $args[] = $this->id;
                break;
            }
            
            break;
        }
        
        $this->verifyPut($results, $proc, $args);
    }
    //}}}
    
    // POST method
    protected function post() { //{{{
        $results = 
          $this->db->apiAddVessel($this->body->vessel_name,
                                  $this->body->vessel_code,
                                  $this->body->vessel_pln,
                                  $this->body->vessel_length,
                                  (int) $this->body->gear_id ? $this->body->gear_id : null,
                                  (int) $this->body->animal_id ? $this->body->animal_id : null,
                                  (int) $this->body->owner_id ? $this->body->owner_id : null,
                                  (int) $this->body->fo_id ? $this->body->fo_id : null,
                                  (int) $this->body->vessel_active);
        $this->verifyPost($results, 'apiGetVessels');
    }
    //}}}
    
    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteVessel($this->id);
        $this->verifyDelete($results, 'apiGetVessels');
    }
    //}}}
}

?>