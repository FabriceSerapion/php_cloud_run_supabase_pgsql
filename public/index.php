<?php

$rootDir = dirname(__DIR__);

require $rootDir.'/vendor/autoload.php';
use App\PgDatabase;
use Dotenv\Dotenv;

$dotenv = Dotenv::createImmutable($rootDir);
$dotenv->load();

$dbConn = (new PgDatabase())->setConnection()->getConnection();

if ($dbConn instanceof PDO) {
    echo PHP_EOL . 'app works' . PHP_EOL;
}