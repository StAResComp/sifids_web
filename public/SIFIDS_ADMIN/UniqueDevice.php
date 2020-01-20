<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class UniqueDevice extends Controller {
    protected $fields = array('unique_device_id',
                              'device_name', 'device_string', 'serial_number', 
                              'model_id', 'telephone');
    
    // GET method
    protected function get() { //{{{
        switch ($this->pathLen) {
            // have ID of device
         case 1:
            $this->results = $this->db->apiGetUniqueDevice($this->id);
            break;
            
            // have ID of unique device plus attribute of device
         case 2:
            switch ($this->path[1]) {
             case 'devices':
                $this->results = $this->db->apiGetDevice($this->id);
                break;
            }
            break;
            
            // no user ID, so all unique devices
         default:
            $this->results = $this->db->apiGetUniqueDevices();
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
         case 1:
            $results = 
              $this->db->apiUpdateUniqueDevice($this->id,
                                               $this->body->device_name,
                                               $this->body->device_string,
                                               $this->body->serial_number,
                                               (int) $this->body->model_id ? $this->body->model_id : null,
                                               $this->body->telephone);
            $proc = 'apiGetUniqueDevices';
            break;
            
         case 2:
            switch ($this->path[1]) {
             case 'devices':
                $results = 
                  $this->db->apiUpdateDevice((int) $this->body->vessel_id ? $this->body->vessel_id : null,
                                             $this->id,
                                             (int) $this->body->device_power_id ? $this->body->device_power_id : null,
                                             (int) $this->body->device_active,
                                             $this->body->engineer_notes);
                $proc = 'apiGetDevice';
                break;
            }
            
            $args[] = $this->id;
            break;
        }
        
        $this->verifyPut($results, $proc, $args);
    }
    //}}}
    
    // POST method
    protected function post() { //{{{
        $results = 
          $this->db->apiAddUniqueDevice($this->body->device_name,
                                        $this->body->device_string,
                                        $this->body->serial_number,
                                        (int) $this->body->model_id ? $this->body->model_id : null,
                                        $this->body->telephone);
        $this->verifyPost($results, 'apiGetUniqueDevices');
    }
    //}}}

    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteUniqueDevice($this->id);
        $this->verifyDelete($results, 'apiGetUniqueDevices');
    }
    //}}}
}

?>