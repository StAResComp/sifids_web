<?php

declare(strict_types=1);

namespace SIFIDS_ADMIN;

class User extends Controller {
    protected $fields = array('user_id', 'user_name', 'user_email', 'user_password', 'user_type_id', 'user_active');
    
    // GET method
    protected function get() { //{{{
        switch ($this->pathLen) {
            // have ID of user
         case 1:
            $this->results = $this->db->apiGetUser($this->id);
            break;
            
            // have ID of user plus attribute of user
         case 2:
            switch ($this->path[1]) {
             case 'user_projects':
                $this->results = $this->db->apiGetUserProjects($this->id);
                break;

             case 'user_vessels':
                $this->results = $this->db->apiGetUserVessels($this->id);
                break;
                
             case 'user_fishery_offices':
                $this->results = $this->db->apiGetUserFisheryOffices($this->id);
                break;
            }
            break;
            
            // no user ID, so all users
         default:
            $this->results = $this->db->apiGetUsers();
            break;
        }
    }
    //}}}
    
    // PUT method - update existing user's details
    protected function put() { //{{{
        $results = array();
        $proc = '';
        $args = array();
        
        switch ($this->pathLen) {
            // have ID of user
         case 1:
            // have new password
            if (isset($this->body->user_password) && 
                '' != $this->body->user_password) {
                $results = 
                  $this->db->apiUpdateUser($this->id,
                                           $this->body->user_name,
                                           $this->body->user_email,
                                           $this->body->user_password,
                                           (int) $this->body->user_type_id ? $this->body->user_type_id : null,
                                           (int) $this->body->user_active);
            }
            else {
                $results = $this->db->apiUpdateUser($this->id,
                                                    $this->body->user_name,
                                                    $this->body->user_email,
                                                    (int) $this->body->user_type_id ? $this->body->user_type_id : null,
                                                    (int) $this->body->user_active);
            }
            
            $proc = 'apiGetUsers';
            break;
            
            // have ID of user plus attribute of user
         case 2:
            switch ($this->path[1]) {
             case 'user_projects':
                $results = 
                  $this->db->apiUpdateUserProjects($this->id, 
                                                   $this->array2SQL('user_project'));
                $proc = 'apiGetUserProjects';
                break;
                
             case 'user_vessels':
                $results = $this->db->apiUpdateUserVessels($this->id, 
                                                           $this->array2SQL('user_vessel'));
                $proc = 'apiGetUserVessels';
                break;
                
             case 'user_fishery_offices':
                $results = $this->db->apiUpdateUserFisheryOffices($this->id,
                                                                  $this->array2SQL('user_fishery_office'));
                $proc = 'apiGetUserFisheryOffices';
                break;
            }
            
            $args[] = $this->id;
            break;
        }
        
        $this->verifyPut($results, $proc, $args);
    }
    //}}}
    
    // POST method - create new user
    protected function post() { //{{{
        $results = $this->db->apiAddUser($this->body->user_name,
                                         $this->body->user_email,
                                         $this->body->user_password,
                                         (int) $this->body->user_type_id ? $this->body->user_type_id : null,
                                         (int) $this->body->user_active);
        $this->verifyPost($results, 'apiGetUsers');
    }
    //}}}
    
    // DELETE method
    protected function delete() { //{{{
        $results = $this->db->apiDeleteUser($this->id);
        $this->verifyDelete($results, 'apiGetUsers');
    }
    //}}}
}

?>