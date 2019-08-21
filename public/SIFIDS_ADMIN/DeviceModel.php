<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class DeviceModel extends Controller {
    protected $fields = array('model_id', 'model_family', 'model_name', 
                              'protocol_id');
    
    // GET method
    protected function get() { //{{{
        $path = $this->request->getPath();
        switch (count($path)) {
            // have ID of device model
         case 1:
            $this->results = $this->db->apiGetDeviceModel((int) $path[0]);
            break;
            
            // no device model ID, so all device models
         default:
            $this->results = $this->db->apiGetDeviceModels();
            break;
        }
    }
    //}}}

    // PUT method
    protected function put() { //{{{
        $results =
          $this->db->apiUpdateDeviceModel($this->id,
                                          $this->body->model_family,
                                          $this->body->model_name,
                                          $this->body->protocol_id);
        $this->verifyPut($results, 'apiGetDeviceModels');
    }
    //}}}

    // POST method
    protected function post() { //{{{
        $results =
          $this->db->apiAddDeviceModel($this->body->model_family,
                                       $this->body->model_name,
                                       $this->body->protocol_id);
        $this->verifyPost($results, 'apiGetDeviceModels');
    }
    //}}}

    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteDeviceModel($this->id);
        $this->verifyDelete($results, 'apiGetDeviceModels');
    }
    //}}}
}

?>