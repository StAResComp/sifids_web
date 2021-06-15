<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Request {
    private $controller = '';
    private $view = 'json'; // default to JSON view
    
    private $controllers = array('users' => 'User', 
                                 'vessels' => 'Vessel',
                                 'unique_devices' => 'UniqueDevice',
                                 'devices' => 'Device',
                                 'projects' => 'Project',
                                 'fishery_offices' => 'FisheryOffice',
                                 'species' => 'Species',
                                 'gears' => 'Gears',
                                 'device_powers' => 'DevicePower',
                                 'protocols' => 'Protocol',
                                 'device_models' => 'DeviceModel',
                                 'user_types' => 'UserType',
                                 'vessel_owners' => 'VesselOwner',
                                 'device_protocols' => 'DeviceProtocol',
                                 'page' => 'Page',
                                 'trips' => 'Trip');
    private $views = array('json' => 'JSONView',
                           'html' => 'HTMLView');
    
    private $method = 'GET';
    private $path = array();
    private $params = array();
    private $body = null;
    
    // collect all inputs
    public function __construct() { //{{{
        // method
        if (isset($_SERVER['REQUEST_METHOD'])) {
            $this->method = strtoupper($_SERVER['REQUEST_METHOD']);
        }
        
        // get path information
        $path = isset($_SERVER['PATH_INFO']) ? $_SERVER['PATH_INFO'] : '';
        
        // remove trailing / if present
        $l = strlen($path) - 1;
        if ('/' == substr($path, $l)) {
            $path = substr($path, 0, $l);
        }
        
        // split path elements
        $pathElements = explode('/', $path);
        
        foreach ($pathElements as $i => $pe) {
            // not got to controller item yet
            if (!isset($this->controllers[$pe])) {
                continue;
            }
            
            // controller is current item and path any remaining items
            $this->controller = $pe;
            $this->path = array_slice($pathElements, $i + 1);
            break;
        }
        
        // no controller, so return HTML page instead
        if (!$this->controller) {
            $this->view = 'html';
            $this->controller = 'page';
        }

        // query string parameters
        $this->params = $_GET;
        
        // method may have supplied JSON input
        if ('POST' == $this->method || 'PUT' == $this->method) {
            if ($input = file_get_contents('php://input')) {
                $this->body = json_decode($input);
            }
        }
    }
    //}}}
    
    // get name of controller class
    public function getController() : string { //{{{
        return "\\SIFIDS_ADMIN\\" . $this->controllers[$this->controller];
    }
    //}}}
    
    // get name of view class
    public function getView() : string { //{{{
        return "\\SIFIDS_ADMIN\\" . $this->views[$this->view];
    }
    //}}}

    // get path array
    public function getPath() : array { //{{{
        return $this->path;
    }
    //}}}
    
    // get params array
    public function getParams() : array { //{{{
        return $this->params;
    }
    //}}}
    
    // get body data
    public function getBody() : \StdClass { //{{{
        return $this->body ? $this->body : new \StdClass();
    }
    //}}}
    
    // get method
    public function getMethod() : string { //{{{
        return $this->method;
    }
    //}}}
}

?>