<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class DeviceProtocol extends Controller {
    protected $fields = array('protocol_id', 'protocol_name', 'protocol_code');
    
    // GET method
    protected function get() { //{{{
        $path = $this->request->getPath();
        switch (count($path)) {
            // have ID of device power option
         case 1:
            $this->results = $this->db->apiGetDeviceProtocol((int) $path[0]);
            break;
            
            // no device power ID, so all device power options
         default:
            $this->results = $this->db->apiGetDeviceProtocols();
            break;
        }
    }
    //}}}

    // PUT method
    protected function put() { //{{{
        $results =
          $this->db->apiUpdateProtocol($this->id,
                                       $this->body->protocol_name,
                                       $this->body->protocol_code);
        $this->verifyPut($results, 'apiGetProtocols');
    }
    //}}}

    // POST method
    protected function post() { //{{{
        $results =
          $this->db->apiAddProtocol($this->body->protocol_name,
                                    $this->body->protocol_code);
        $this->verifyPost($results, 'apiGetProtocols');
    }
    //}}}

    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteProtocol($this->id);
        $this->verifyDelete($results, 'apiGetProtocols');
    }
    //}}}
}

?>