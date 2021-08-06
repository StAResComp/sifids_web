<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Dump {
    private $action = NULL;
    private $startDate = NULL;
    private $endDate = NULL;
    private $db = NULL;
    private $fh = NULL;
    
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
    
    public function generateDump() { //{{{
        $filename = '';
        
        // get results from database
        $results = $this->{$this->action}($filename);
        
        // open memory file handle
        $this->fh = fopen('php://memory', 'r+');
        
        // write CSV data to file handle
        foreach ($results as $row) {
            fputcsv($this->fh, $row);
        }
        
        // finished
        rewind($this->fh);
        
        // headers for CSV as attachment
        header('Content-type: text/csv');
        header(sprintf('Content-disposition: attachment; filename=%s.csv',
                       $filename));
    }
    //}}}
    
    public function __toString() : string { //{{{
        // send back CSV as string
        return stream_get_contents($this->fh);
    }
    //}}}

    // return data on trips made within date range
    private function trips(string &$filename) : array { //{{{
        if (!$this->startDate || !$this->endDate) {
            throw new \Exception('Need start and end dates for trips data');
        }
        
        // set filename
        $filename = sprintf('trips_%s_%s',
                            $this->startDate, $this->endDate);
        
        return $this->db->dumpTrip($this->startDate, $this->endDate);
    }
    //}}}
}

?>