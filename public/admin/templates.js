// templates for json2html

const ADD_NEW = 'Add new';

let templates = {
     // blank select option
     'blankOption': {'<>': 'option', 'value': '', 'text': 'Choose one'},
     
     // list of users
     'users': {'<>': 'div', 'html': //{{{
               function() {
                    return entityDiv('user', 'usersList', 'user_id', 'user_name', dbData.users);
               }
     },
     //}}}
     
     // user form
     'userForm':
     [ //{{{
      {'<>': 'div', 'class': 'form-group', 'html':
           [
            {'<>': 'label', 'for': 'user_name', 'class': 'col-md-6 control-label', 'text': 'User name'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'user_name', 'placeholder': 'Name of user', 'name': 'user_name', 'value': '${user_name}'}
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html':
           [
            {'<>': 'label', 'for': 'user_email', 'class': 'col-md-6 control-label', 'text': 'User email'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'user_email', 'placeholder': 'Email of user', 'name': 'user_email', 'value': '${user_email}'}
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html':
           [
            {'<>': 'label', 'for': 'user_password', 'class': 'col-md-6 control-label', 'text': 'User password'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'user_name', 'placeholder': 'New password for user', 'name': 'user_password'}
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html':
           [
            {'<>': 'label', 'for': 'user_type_id', 'class': 'col-md-6 control-label', 'text': 'User type'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'select', 'class': 'form-control', 'id': 'user_type_id', 'name': 'user_type_id', 'html':
                            function() {
                                 return select(dbData.userTypes, dbData.userForm[0], 'user_type_id', 'user_type_name');
                            }
                       }
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html':
                [
                 {'<>': 'label', 'for': 'user_active', 'class': 'col-md-6 control-label', 'text': 'User active'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           function() {
                                return checkbox(dbData.userForm[0], 'user_active', 1);
                           }
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('user', 'userForm', 'user_id'); }}
     ],
     //}}}
     
     // user projects form
     'userProjectsForm': 
     [ //{{{
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'user_project', 'class': 'col-md-6 control-label', 'text': 'User projects'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'select', 'class': 'form-control', 'id': 'user_project', 'name': 'user_project', 'multiple': 'multiple', 'html':
                            function() {
                                 return selectMultiple(dbData.projects, dbData.userProjectsForm, 'project_id', 'project_name');
                            }
                       }
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('user project'); }}
     ],
     //}}}
     
     // user vessels form
     'userVesselsForm': 
     [ //{{{
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'user_vessel', 'class': 'col-md-6 control-label', 'text': 'User vessels'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'select', 'class': 'form-control', 'id': 'user_vessel', 'name': 'user_vessel', 'multiple': 'multiple', 'html':
                            function() {
                                 return selectMultiple(dbData.vessels, dbData.userVesselsForm, 'vessel_id', 'vessel_name');
                            }
                       }
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('user vessel'); }}
     ],
     //}}}

     // user fishery offices form
     'userFisheryOfficesForm': 
     [ //{{{
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'user_fishery_office', 'class': 'col-md-6 control-label', 'text': 'User fishery offices'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'select', 'class': 'form-control', 'id': 'user_fishery_office', 'name': 'user_fishery_office', 'multiple': 'multiple', 'html':
                            function() {
                                 return selectMultiple(dbData.fisheryOffices, dbData.userFisheryOfficesForm, 'fo_id', 'fo_town');
                            }
                       }
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('user fishery office'); }}
     ],
     //}}}

     // list of vessels
     'vessels': {'<>': 'div', 'html': //{{{
               function() {
                    return entityDiv('vessel', 'vesselsList', 'vessel_id', 'vessel_name', dbData.vessels);
               }
     },
     //}}}
     
     // vessel form
     'vesselForm': 
     [ //{{{
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'vessel_name', 'class': 'col-md-6 control-label', 'text': 'Vessel name'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'vessel_name', 'placeholder': 'Name of vessel (e.g. Boaty McBoatface)', 'name': 'vessel_name', 'value': '${vessel_name}'}
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'vessel_code', 'class': 'col-md-6 control-label', 'text': 'Vessel code'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'vessel_code', 'placeholder': 'Code for vessel (e.g. XYZ)', 'name': 'vessel_code', 'value': '${vessel_code}'}
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'vessel_pln', 'class': 'col-md-6 control-label', 'text': 'Vessel PLN'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'vessel_pln', 'placeholder': 'PLN for vessel (e.g. AB123)', 'name': 'vessel_pln', 'value': '${vessel_pln}'}
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'owner_id', 'class': 'col-md-6 control-label', 'text': 'Vessel owner'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'select', 'class': 'form-control', 'id': 'owner_id', 'name': 'owner_id', 'html':
                            function() {
                                 return select(dbData.vesselOwners, dbData.vesselForm[0], 'owner_id', 'owner_name');
                            }
                       }
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'fo_id', 'class': 'col-md-6 control-label', 'text': 'Fishery office'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'select', 'class': 'form-control', 'id': 'fo_id', 'name': 'fo_id', 'html':
                            function() {
                                 return select(dbData.fisheryOffices, dbData.vesselForm[0], 'fo_id', 'fo_town');
                            }
                       }
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html':
                [
                 {'<>': 'label', 'for': 'vessel_active', 'class': 'col-md-6 control-label', 'text': 'Vessel active'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           function() {
                                return checkbox(dbData.vesselForm[0], 'vessel_active', 1);
                           }
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('vessel', 'vesselForm', 'vessel_id'); }}
     ],
     //}}}

     // vessel projects form
     'vesselProjectsForm': 
     [ //{{{
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'vessel_project', 'class': 'col-md-6 control-label', 'text': 'Vessel projects'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'select', 'class': 'form-control', 'id': 'vessel_project', 'name': 'vessel_project', 'multiple': 'multiple', 'html':
                            function() {
                                 return selectMultiple(dbData.projects, dbData.vesselProjectsForm, 'project_id', 'project_name');
                            }
                       }
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('vessel project'); }}
     ],
     //}}}

     // devices list
     'devices': {'<>': 'div', 'html': //{{{
               function() {
                    return entityDiv('device', 'devicesList', 'device_id', 'device_name', dbData.devices);
               }
     },
     //}}}

     // device form
     'deviceForm': //{{{
     [
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'device_name', 'class': 'col-md-6 control-label', 'text': 'Device name'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'device_name', 'placeholder': 'Name of device (e.g. s204_solar_001)', 'name': 'device_name', 'value': '${device_name}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
           [
            {'<>': 'label', 'for': 'vessel_id', 'class': 'col-md-6 control-label', 'text': 'Vessel'},
            {'<>': 'div', 'class': 'col-md-9', 'html':
                      [
                       {'<>': 'select', 'class': 'form-control', 'id': 'vessel_id', 'name': 'vessel_id', 'html':
                            function() {
                                 return select(dbData.vessels, dbData.deviceForm[0], 'vessel_id', 'vessel_name');
                            }
                       }
                      ]
            }
           ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'device_string', 'class': 'col-md-6 control-label', 'text': 'Device string'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'device_string', 'placeholder': 'Device ID string (e.g. IMEI number)', 'name': 'device_string', 'value': '${device_string}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'serial_number', 'class': 'col-md-6 control-label', 'text': 'Serial number'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'serial_number', 'placeholder': 'Serial number of device', 'name': 'serial_number', 'value': '${serial_number}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'model_id', 'class': 'col-md-6 control-label', 'text': 'Model'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'select', 'class': 'form-control', 'id': 'model_id', 'name': 'model_id', 'html':
                                 function() {
                                      return select(dbData.deviceModels, dbData.deviceForm[0], 'model_id', 'model_name');
                                 }
                            }
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'telephone', 'class': 'col-md-6 control-label', 'text': 'Telephone number'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'telephone', 'placeholder': 'Telephone number of device', 'name': 'telephone', 'value': '${telephone}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'device_power_id', 'class': 'col-md-6 control-label', 'text': 'Device power'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'select', 'class': 'form-control', 'id': 'device_power_id', 'name': 'device_power_id', 'html':
                                 function() {
                                      return select(dbData.devicePowers, dbData.deviceForm[0], 'device_power_id', 'device_power_name');
                                 }
                            }
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html':
                [
                 {'<>': 'label', 'for': 'device_active', 'class': 'col-md-6 control-label', 'text': 'Device active'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           function() {
                                return checkbox(dbData.deviceForm[0], 'device_active', 1);
                           }
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'engineer_notes', 'class': 'col-md-6 control-label', 'text': 'Engineer notes'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'textarea', 'class': 'form-control', 'id': 'engineer_notes', 'placeholder': 'Notes made by engineer', 'name': 'engineer_notes', 'text': '${engineer_notes}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('device', 'deviceForm', 'device_id'); }}
     ],
     //}}}

     // vessel owners list
     'vesselOwners': {'<>': 'div', 'html': //{{{
               function() {
                    return entityDiv('vessel_owner', 'vesselOwnersList', 'owner_id', 'owner_name', dbData.vesselOwners);
               }
     },
     //}}}

     // vessel owners form
     'vesselOwnerForm': //{{{
     [
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'owner_name', 'class': 'col-md-6 control-label', 'text': 'Owner name'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'owner_name', 'placeholder': 'Name of vessel owner', 'name': 'owner_name', 'value': '${owner_name}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'owner_address', 'class': 'col-md-6 control-label', 'text': 'Owner address'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'owner_address', 'placeholder': 'Address of vessel owner', 'name': 'owner_address', 'value': '${owner_address}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('vessel owner', 'vesselOwnerForm', 'owner_id'); }}
     ],
     //}}}

     // device protocols list
     'deviceProtocols': {'<>': 'div', 'html': //{{{
               function() {
                    return entityDiv('device_protocol', 'deviceProtocols', 'protocol_id', 'protocol_name', dbData.deviceProtocols);
               }
     },
     //}}}
     
     // device protocols form
     'deviceProtocolForm': //{{{
     [
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'protocol_name', 'class': 'col-md-6 control-label', 'text': 'Protocol name'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'protocol_name', 'placeholder': 'Name of protocol', 'name': 'protocol_name', 'value': '${protocol_name}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'protocol_code', 'class': 'col-md-6 control-label', 'text': 'Protocol code'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'protocol_code', 'placeholder': 'Code for protocol', 'name': 'protocol_code', 'value': '${protocol_code}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('device protocol', 'deviceProtocolForm', 'protocol_id'); }}
     ],
     //}}}

     // device models list
     'deviceModels': {'<>': 'div', 'html': //{{{
               function() {
                    return entityDiv('device_model', 'deviceModels', 'model_id', 'model_name', dbData.deviceModels);
               }
     },
     //}}}

     // device model form
     'deviceModelForm': //{{{
     [
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'model_family', 'class': 'col-md-6 control-label', 'text': 'Model family'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'model_family', 'placeholder': 'Name of device family (e.g. Teltonika)', 'name': 'model_family', 'value': '${model_family}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'model_name', 'class': 'col-md-6 control-label', 'text': 'Name of model'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'model_name', 'placeholder': 'Name of model (e.g. FMB204)', 'name': 'model_name', 'value': '${model_name}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'protocol_id', 'class': 'col-md-6 control-label', 'text': 'Device protocol'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'select', 'class': 'form-control', 'id': 'device_power_id', 'name': 'protocol_id', 'html':
                                 function() {
                                      return select(dbData.deviceProtocols, dbData.deviceModelForm[0], 'protocol_id', 'protocol_name');
                                 }
                            }
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('device_model', 'deviceModelForm', 'model_id'); }}
     ],
     //}}}
     
     // projects
     'projects': {'<>': 'div', 'html': //{{{
               function() {
                    return entityDiv('project', 'projectsList', 'project_id', 'project_name', dbData.projects);
               }
     },
     //}}}
     
     'projectForm': //{{{
     [
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'model_family', 'class': 'col-md-6 control-label', 'text': 'Project name'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'project_name', 'placeholder': 'Name of project', 'name': 'project_name', 'value': '${project_name}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'model_name', 'class': 'col-md-6 control-label', 'text': 'Project code'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'project_code', 'placeholder': 'Code for project', 'name': 'project_code', 'value': '${project_code}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('project', 'projectForm', 'project_id'); }}
     ],
     //}}}

     // fisher offices
     'fisheryOffices': {'<>': 'div', 'html': //{{{
               function() {
                    return entityDiv('fishery_office', 'fisheryOfficesList', 'fo_id', 'fo_town', dbData.fisheryOffices);
               }
     },
     //}}}
     
     'fisheryOfficeForm': //{{{
     [
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'fo_town', 'class': 'col-md-6 control-label', 'text': 'Fishery office town'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'fo_town', 'placeholder': 'Fishery office town (e.g. Anstruther)', 'name': 'fo_town', 'value': '${fo_town}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'fo_address', 'class': 'col-md-6 control-label', 'text': 'Fishery office address'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'fo_address', 'placeholder': 'Fishery office address (e.g. 1 The Shore)', 'name': 'fo_address', 'value': '${fo_address}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': 
                [
                 {'<>': 'label', 'for': 'fo_email', 'class': 'col-md-6 control-label', 'text': 'Fishery office email'},
                 {'<>': 'div', 'class': 'col-md-9', 'html':
                           [
                            {'<>': 'input', 'type': 'text', 'class': 'form-control', 'id': 'fo_address', 'placeholder': 'Fishery office email (e.g. fo.XXX@gov.scot)', 'name': 'fo_email', 'value': '${fo_email}'}
                           ]
                 }
                ]
      },
      {'<>': 'div', 'class': 'form-group', 'html': function() { return submitDelete('fishery_office', 'fisheryOfficeForm', 'fo_id'); }}
     ]
     //}}}
};

// controls for submit/delete record
function submitDelete(entity, form, id) { //{{{
     let html = 
          [
           {'<>': 'button', 'type': 'button', 'class': 'submit btn btn-default', 'text': 'Save ' + entity + ' record'}
          ];
     
     if (form && dbData[form].length && dbData[form][0][id]) {
          html.push({'<>': 'button', 'type': 'button', 'class': 'delete btn btn-default', 'text': 'Delete ' + entity + ' record'});
     }
     
     return json2html.transform({}, html);
}
//}}}

// generate select options for single select
// list is source of all options
// form is the options currently selected
// id is the field to match
// display is field to use for display
function select(list, form, id, display) { //{{{
     // put together template objects
     let deselected = {'<>': 'option', 'value': '${' + id + '}', 'text': '${' + display + '}'};
     let selected = Object.assign({}, deselected, {'selected': 'selected'});
     
     let html = json2html.transform({}, templates.blankOption);
     
     list.forEach(function(d) {
          if (!d[id]) {
          }
          else if (d[id] == form[id]) {
               html += json2html.transform(d, selected);
          }
          else {
               html += json2html.transform(d, deselected);
          }
     });
     
     return html;
}
//}}}

function selectMultiple(list, form, id, display) { //{{{
     // put together template objects
     let deselected = {'<>': 'option', 'value': '${' + id + '}', 'text': '${' + display + '}'};
     let selected = Object.assign({}, deselected, {'selected': 'selected'});
     
     let html = '';
     
     list.forEach(function(d) {
          if (d[id]) {
               let found = false;
               form.some(function(u) {
                    found = d[id] == u[id];
                    return found;
               });
                             
               if (found) {
                    html += json2html.transform(d, selected);
               }
               else {
                    html += json2html.transform(d, deselected);
               }
          }
     });
     
     return html;
}
//}}}

function checkbox(form, id, value) { //{{{
     let unchecked = {'<>': 'input', 'type': 'checkbox', 'class': 'form-control', 'id': id, 'name': id, 'value': ''};
     let checked = Object.assign({}, unchecked, {'checked': 'checked'});
     
     let html = '';
     
     if (form[id] == value) {
          checked.value = value;
          html += json2html.transform({}, checked);
     }
     else {
          unchecked.value = value;
          html += json2html.transform({}, unchecked);
     }
     
     return html;
}
//}}}

// entityDiv('user', 'usersList', 'user_id', 'user_name')
function entityDiv(entity, listID, id, display, data) { //{{{
     let li = {'<>': 'li', 'html':
          [
           {'<>': 'a', 'href': '#', 'class': 'api load', 'data-entity': entity, 'data-id': '${' + id + '}', 'text': '${' + display + '}'}
          ]
     };
     
     let html = 
          [
           {'<>': 'p', 'html': 
                [
                 {'<>': 'a', 'href': '#', 'class': 'api load', 'data-entity': entity, 'data-id': 'new', 'text': ADD_NEW}
                ]
           },
           {'<>': 'ul', 'id': listID, 'html':
                     function() { return json2html.transform(data, li); }
           }
          ];
     
     return json2html.transform({}, html);
}
//}}}