<?php

declare(strict_types=1);

namespace SIFIDS;

require_once 'dbConfig.php';

class DB {
    private $conn = null;
    private static $instance = null;
    
    // private constructor - only called by getInstance
    private function __construct(string $schema='') { //{{{
        $dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s', 
                       SIFIDS_DB_HOST, SIFIDS_DB_PORT, SIFIDS_DB_DBNAME);
        if (!$this->conn = new \PDO($dsn, SIFIDS_DB_USER, SIFIDS_DB_PASS)) {
            throw new \Exception('Problem connecting to database');
        }
        
        // set schema if passed - will match relations in given schema before public
        if ($schema) {
            $sql = sprintf("SET SCHEMA '%s';", $schema);
            if (false === $this->conn->exec($sql)) {
                throw new \Exception('Problem setting schema');
            }
        }
    }
    //}}}
    
    // call this static method to get singleton
    public static function getInstance(bool $transaction=false, string $schema='') { //{{{
        if (null == self::$instance) {
            self::$instance = new DB($schema);
        }
        
        if ($transaction && !self::$instance->conn->inTransaction()) {
            self::$instance->conn->beginTransaction();
        }
        
        return self::$instance;
    }
    //}}}
    
    // call stored procedures
    public function __call(string $proc, array $args) : array { //{{{
        $results = array();

        // get length of ?, string for argument placeholders
        $c = count($args);
        $p = $c > 1 ? ($c * 2) - 1 : $c;
        
        // put together SQL, prepare statement and execute with args
        $sql = sprintf('SELECT * FROM %s(%s);', $proc, str_pad('', $p, '?,'));
        $stmt = $this->conn->prepare($sql);
        
        if (!$stmt->execute($args)) {
            throw new \Exception('Problem executing stored procedure');
        }
        
        // send back results
        if (false === ($results = $stmt->fetchAll())) {
            $results = array();
        }
        
        return $results;
    }
    //}}}

    // commit if in transaction, otherwise roll back and throw exception
    public function commit() { //{{{
        if ($this->conn->inTransaction()) {
            if (!$this->conn->commit()) {
                $this->conn->rollBack();
                
                throw new \Exception('Had to rollback transaction');
            }
        }
    }
    //}}}

    // roll back transaction
    public function rollback() { //{{{
        if ($this->conn->inTransaction()) {
            $this->conn->rollBack();
        }
    }
    //}}}

    // try to commit any transactions on destruction
    public function __destruct() { //{{{
        $this->commit();
    }
    //}}}
    
    public function getErrorInfo() : array { //{{{
        return $this->conn->errorInfo();
    }
    //}}}
}