<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Device extends Controller {
    protected $fields = array('device_id', 'vessel_id', 
                              'device_name', 'device_string', 'serial_number', 
                              'model_id', 'telephone', 'device_power_id', 
                              'device_active', 'engineer_notes');
    
    // GET method
    protected function get() { //{{{
        $path = $this->request->getPath();
        switch (count($path)) {
            // have ID of device
         case 1:
            $this->results = $this->db->apiGetDevice((int) $path[0]);
            break;
            
            // no user ID, so all users
         default:
            $this->results = $this->db->apiGetDevices();
            break;
        }
    }
    //}}}
    
    // PUT method
    protected function put() { //{{{
        $results = 
          $this->db->apiUpdateDevice($this->id,
                                     (int) $this->body->vessel_id ? $this->body->vessel_id : null,
                                     $this->body->device_name,
                                     $this->body->device_string,
                                     $this->body->serial_number,
                                     (int) $this->body->model_id ? $this->body->model_id : null,
                                     $this->body->telephone,
                                     (int) $this->body->device_power_id ? $this->body->device_power_id : null,
                                     (int) $this->body->device_active,
                                     $this->body->engineer_notes);
        $this->verifyPut($results, 'apiGetDevices');
    }
    //}}}
    
    // POST method
    protected function post() { //{{{
        $results = 
          $this->db->apiAddDevice((int) $this->body->vessel_id ? $this->body->vessel_id : null,
                                  $this->body->device_name,
                                  $this->body->device_string,
                                  $this->body->serial_number,
                                  (int) $this->body->model_id ? $this->body->model_id : null,
                                  $this->body->telephone,
                                  (int) $this->body->device_power_id ? $this->body->device_power_id : null,
                                  (int) $this->body->device_active,
                                  $this->body->engineer_notes);
        $this->verifyPost($results, 'apiGetDevices');
    }
    //}}}

    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteDevice($this->id);
        $this->verifyDelete($results, 'apiGetDevices');
    }
    //}}}
}

?>