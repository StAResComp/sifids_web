<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Controller {
    protected $request = null;
    protected $db = null;
    protected $results = null;
    protected $path = null;
    protected $pathLen = 0;
    protected $id = null;
    protected $body = null;
    
    public function __construct(Request $request) { //{{{
        $this->request = $request;
        $this->db = DB::getInstance();
        $this->results = array();
        
        $this->path = $request->getPath();
        $this->pathLen = count($this->path);
        if ($this->pathLen) {
            $this->id = (int) $this->path[0];
        }
        
        // now do action to populate results
        $this->action();
    }
    //}}}
    
    public function getResults() : array { //{{{
        return $this->results;
    }
    //}}}
    
    // get callback param for wrapping JSONP
    public function getCallback() : string { //{{{
        $params = $this->request->getParams();
        
        return isset($params['callback']) ? $params['callback'] : '';
    }
    //}}}
    
    // handle request based on method
    protected function action() { //{{{
        switch ($this->request->getMethod()) {
         case 'GET':
            if (0 === $this->id) {
                $this->getNew();
            }
            else {
                $this->get();
            }
            break;
            
         case 'POST':
            $this->needBody();
            $this->post();
            break;
            
         case 'PUT':
            $this->needBody();
            $this->put();
            break;
            
         case 'DELETE':
            $this->delete();
            break;
        }
    }
    //}}}
    
    // make sure that POST action was successful
    protected function verifyPost(array $results, string $proc, array $args=array()) { //{{{
        if (!isset($results[0]->inserted) || !$results[0]->inserted) {
            throw new \Exception('Nothing added');
        }
        
        $this->results = call_user_func_array(array($this->db, $proc), $args);
    }
    //}}}
    
    // make sure that PUT action was successful
    protected function verifyPut(array $results, string $proc, array $args=array()) { //{{{
        if (!isset($results[0]->updated) || !$results[0]->updated) {
            throw new \Exception('Nothing updated');
        }
        
        $this->results = call_user_func_array(array($this->db, $proc), $args);
    }
    //}}}

    // make sure that DELETE action was successful
    protected function verifyDelete(array $results, string $proc, array $args=array()) { //{{{
        if (!isset($results[0]->deleted) || !$results[0]->deleted) {
            throw new \Exception('Nothing deleted');
        }
        
        $this->results = call_user_func_array(array($this->db, $proc), $args);
    }
    //}}}

    // make sure request body exists
    protected function needBody() { //{{{
        $body = $this->request->getBody();
        if (!$body) {
            throw new \Exception('Missing JSON body');
        }
        
        $this->body = $body;
    }
    //}}}
    
    // turn array into format accepted by Postgres stored procedures
    protected function array2SQL(string $field) : string { //{{{
        return isset($this->body->$field) && is_array($this->body->$field) ?
          sprintf('{%s}', implode(',', $this->body->$field)) : '{}';
    }
    //}}}
    
    // add empty result to array of results
    private function getNew() { //{{{
        if (isset($this->fields)) {
            $r = new \StdClass();
            
            foreach ($this->fields as $f) {
                $r->$f = '';
            }
            
            array_unshift($this->results, $r);
        }
    }
    //}}}
}

?>