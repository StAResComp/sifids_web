<?php

declare(strict_types=1);

//require_once 'baseConfig.php';

// add includes directory
//set_include_path(get_include_path() . PATH_SEPARATOR . IDB_INCLUDES_PATH);
//set_include_path(IDB_INCLUDES_PATH);

// look for Class.php in path above
//spl_autoload_extensions('.php');

// register autoloading for classes
spl_autoload_register(function(string $className) {
    require_once str_replace('\\', DIRECTORY_SEPARATOR, $className) . '.php';
});

?>