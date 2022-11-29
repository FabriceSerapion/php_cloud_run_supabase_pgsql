<?php

declare(strict_types=1);

namespace App;

use PDO;

interface DatabaseInterface {

    public function getConnection(): ?PDO;

    public function setConnection(): static;

}