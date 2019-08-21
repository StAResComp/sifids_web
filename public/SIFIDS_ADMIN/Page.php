<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Page extends Controller {
    const FORM = __DIR__ . '/../admin/page.html';
    
    protected function get() { //{{{
        $this->results = (array) file_get_contents(self::FORM);
    }
    //}}}
}

?>