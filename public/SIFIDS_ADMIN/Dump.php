<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Dump {
    private $action = NULL;
    private $startDate = NULL;
    private $endDate = NULL;
    private $db = NULL;
    
    public function __construct(string $action) { //{{{
        $this->action = $action;
        
        $this->db = DB::getInstance();
        $this->db->setFetch(\PDO::FETCH_NUM);
    }
    
    public function setStartDate(string $d) { //{{{
        $this->startDate = $d;
    }
    //}}}

    public function setEndDate(string $d) { //{{{
        $this->endDate = $d;
    }
    //}}}
    
    public function __toString() : string { //{{{
        $filename = '';
        
        // get results from database
        $results = $this->{$this->action}($filename);
        
        // open memory file handle
        $fh = fopen('php://memory', 'r+');
        
        // write CSV data to file handle
        foreach ($results as $row) {
            fputcsv($fh, $row);
        }
        
        // finished
        rewind($fh);
        
        // headers for CSV as attachment
        header('Content-type: text/csv');
        header(sprintf('Content-disposition: attachment; filename=%s.csv',
                       $filename));
        
        // send back CSV as string
        return stream_get_contents($fh);
    }
    //}}}

    // return data on trips made within date range
    private function trips() : array { //{{{
        if (!$this->startDate || !$this->endDate) {
            throw new \Exception('Need start and end dates for trips data');
        }
        
        return $this->db->dumpTrips($this->startDate, $this->endDate);
    }
    //}}}
}

?>