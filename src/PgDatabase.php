<?php

declare(strict_types=1);

namespace App;

use App\DatabaseInterface;
use PDO;
use PDOException;

final class PgDatabase implements DatabaseInterface {

    private ?PDO $_connection = null;

    public function setConnection(): static {
        $dsn = 'pgsql:';
        $dsn .= 'host=' . $_ENV['DB_HOST'];
        $dsn .= ';port=' . $_ENV['DB_PORT'];
        $dsn .= ';dbname=' . $_ENV['DB_NAME'];
        try {
            $this->_connection = new PDO($dsn, $_ENV['DB_USR'], $_ENV['DB_PASS']);
        } catch (PDOException $e) {
            echo PHP_EOL . 'woops failed to connect to Postgres' . PHP_EOL;
        }
        return $this;
    }

    public function getConnection(): ?PDO {
        return $this->_connection;
    }

}

