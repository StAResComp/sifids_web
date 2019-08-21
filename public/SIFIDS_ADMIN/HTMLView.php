<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class HTMLView {
    private $data = null;
    
    public function __construct(Controller $controller) { //{{{
        $this->data = $controller->getResults();
    }
    //}}}
    
    public function __toString() : string { //{{{
        header('Content-Type: text/html; charset=utf8');
        
        return $this->data[0];
    }
    //}}}
}

?>