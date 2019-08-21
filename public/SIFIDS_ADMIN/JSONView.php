<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class JSONView {
    private $data = null;
    private $callback = '';
    
    public function __construct(Controller $controller) { //{{{
        $this->data = $controller->getResults();
        $this->callback = $controller->getCallback();
    }
    //}}}
    
    public function __toString() : string { //{{{
        header('Content-Type: application/json; charset=utf8');
        
        return sprintf('%s(%s);',
                       $this->callback,
                       json_encode($this->data));
    }
    //}}}
}

?>