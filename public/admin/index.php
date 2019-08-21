<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

require_once '../autoload.php';

$request = new Request();

$controllerClass = $request->getController();
$controller = new $controllerClass($request);

$viewClass = $request->getView();
$view = new $viewClass($controller);

print $view;

?>