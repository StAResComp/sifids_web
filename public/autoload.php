<?php

declare(strict_types=1);

set_include_path('/home/sifids/public_html/');

// look for Class.php in path above
//spl_autoload_extensions('.php');

// register autoloading for classes
spl_autoload_register(function(string $className) {
    require_once str_replace('\\', DIRECTORY_SEPARATOR, $className) . '.php';
});

?>