<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class Project extends Controller {
    protected $fields = array('project_id', 'project_code', 'project_name');
    
    // GET method
    protected function get() { //{{{
        $path = $this->request->getPath();
        switch (count($path)) {
            // have ID of project
         case 1:
            $this->results = $this->db->apiGetProject((int) $path[0]);
            break;
            
            // no project ID, so all projects
         default:
            $this->results = $this->db->apiGetProjects();
            break;
        }
    }
    //}}}

    // PUT method
    protected function put() { //{{{
        $results =
          $this->db->apiUpdateProject($this->id,
                                      $this->body->project_name,
                                      $this->body->project_code);
        $this->verifyPut($results, 'apiGetProjects');
    }
    //}}}

    // POST method
    protected function post() { //{{{
        $results =
          $this->db->apiAddProject($this->body->project_name,
                                   $this->body->project_code);
        $this->verifyPost($results, 'apiGetProjects');
    }
    //}}}

    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteProject($this->id);
        $this->verifyDelete($results, 'apiGetProject');
    }
    //}}}
}

?>