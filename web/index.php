<?php

use sn\core\App;

define('APP_PATH', realpath(__DIR__ . '/../'));
include(APP_PATH . '/vendor/autoload.php');

App::run();
