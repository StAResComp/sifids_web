// object to hold data from database
let dbData = {};

// events that need handlers
let events = [ // selector, event, handler
              ['.load', 'click', loadEntity]
             ];

// data to prefetch
let fetch = [
             {'id': 'users', 'url': ['users'], 'useData': {}},
             {'id': 'userTypes', 'url': ['user_types']},
             {'id': 'projects', 'url': ['projects']},
             {'id': 'vesselOwners', 'url': ['vessel_owners']},
             {'id': 'fisheryOffices', 'url': ['fishery_offices']},
             {'id': 'species', 'url': ['species']},
             {'id': 'gears', 'url': ['gears']},
             {'id': 'vessels', 'url': ['vessels'], 'useData': {}},
             {'id': 'deviceModels', 'url': ['device_models'], 'useData': {}},
             {'id': 'devicePowers', 'url': ['device_powers']},
             {'id': 'deviceProtocols', 'url': ['device_protocols']},
             {'id': 'uniqueDevices', 'url': ['unique_devices'], 'useData': {}},
             {'id': 'tripsTable', 'url': ['trips'], 'useData': {}}
            ];

// fields that should be arrays, e.g. multiple select fields
let arrayFields = ['user_project', 'user_vessel', 'user_fishery_office', 
                   'vessel_project'];

// update item d in dbData with new data from server
function update(data, d, useData) { //{{{
     // store/replace data
     dbData[d] = data;

     // update UI with new data
     if (templates.hasOwnProperty(d)) {
          console.log('updating ' + d);
          console.log(useData === undefined ? dbData[d] : useData);
          // use useData if passed, otherwise use data
          let el = $('#' + d);
          el.html('');
          el.json2html(useData === undefined ? dbData[d] : useData, 
                       templates[d]);
     }
}
//}}}

// object for calling API
let api = { //{{{
     // construct URL from array of args, or just return anything else
     'url': function(args) {
          if (Array.isArray(args)) {
               args = 'index.php/' + args.join('/');
          }
          
          return args;
     },
     
     // send asynchronous request
     'ajax': function(url, method, data, d, useData) {
          $.ajax({
               'url': url,
               'type': method,
               'data': JSON.stringify(data),
               'dataType': 'jsonp',
               'contentType': 'application/json'
          })
               // success, so use received data in transform
               .done(function(data) {
                    update(data, d, useData);
               })
                    // some error, so display it
                    .fail(function(xhr, status, errorMsg) {
                         error(errorMsg);
                    });
     },
     
     // handle GET requests to API
     'get': function(args, data, d, useData) {
          let url = this.url(args);
          this.ajax(url, 'GET', data, d, useData);
     },
     
     // handle DELETE requests to API
     'delete': function(args, data, d, useData) {
          let url = this.url(args);
          this.ajax(url, 'DELETE', data, d, useData);
     },

     // handle POST requests to API
     'post': function(args, data, d, useData) {
          let url = this.url(args);
          this.ajax(url, 'POST', data, d, useData);
     },

     // handle PUT requests to API
     'put': function(args, data, d, useData) {
          let url = this.url(args);
          this.ajax(url, 'PUT', data, d, useData);
     }
};
//}}}

// display error messages
function error(message) { //{{{
     $('#errors').html(message);
}
//}}}

// clicking on link in list loads stuff into form
function loadEntity(event) { //{{{
     let entity = $(this).data('entity');
     let id = $(this).data('id');
     
     switch (entity) {
     case 'user':
          api.get(['users', id], {}, 'userForm');
          if ('new' == id) {
               update(undefined, 'userProjectsForm');
               update(undefined, 'userVesselsForm');
               update(undefined, 'userFisheryOfficesForm');
          }
          else {
               api.get(['users', id, 'user_projects'], {}, 'userProjectsForm', {});
               api.get(['users', id, 'user_vessels'], {}, 'userVesselsForm', {});
               api.get(['users', id, 'user_fishery_offices'], {}, 'userFisheryOfficesForm', {});
          }
          break;
          
     case 'vessel':
          api.get(['vessels', id], {}, 'vesselForm');
          if ('new' == id) {
               update(undefined, 'vesselProjectsForm');
          }
          else {
               api.get(['vessels', id, 'vessel_projects'], {}, 'vesselProjectsForm', {});
          }
          break;
          
     case 'unique_device':
          api.get(['unique_devices', id], {}, 'uniqueDeviceForm');
          if ('new' == id) {
               update(undefined, 'deviceForm');
          }
          else {
               api.get(['unique_devices', id, 'devices'], {}, 'deviceForm', {});
          }
          break;
          
     case 'vessel_owner':
          api.get(['vessel_owners', id], {}, 'vesselOwnerForm');
          break;
          
     case 'device_protocol':
          api.get(['device_protocols', id], {}, 'deviceProtocolForm');
          break;
          
     case 'device_model':
          api.get(['device_models', id], {}, 'deviceModelForm');
          break;
          
     case 'project':
          api.get(['projects', id], {}, 'projectForm');
          break;
          
     case 'fishery_office':
          api.get(['fishery_offices', id], {}, 'fisheryOfficeForm');
          break;
     }
}
//}}}

// turn given form into JSON
function form2JSON(form) { //{{{
     let data = {};
     
     // turn form data into JSON object
     let arr = form.serializeArray();
     for (let i = 0, l = arr.length; i < l; ++ i) {
          if (arrayFields.includes(arr[i].name)) {
               if (!Array.isArray(data[arr[i].name])) {
                    data[arr[i].name] = [];
               }
               
               data[arr[i].name].push(arr[i].value);
          }
          else {
               data[arr[i].name] = arr[i].value;
          }
     }
     
     return data;
}
//}}}

// submitting form
function submitForm(method, form) { //{{{
     let url = [];
     let d = form.data('refresh');

     // turn form into JSON
     let data = form2JSON(form);
     
     let formID = form.attr('id');

     // get entity/ies for URL
     let entities = form.data('entity').split('/');
     url.push(entities[0]);

     // have (user/vessel etc.) ID, so will be PUTting rather than POSTing
     if (dbData[form.data('use_form')].length) {
          let id = dbData[form.data('use_form')][0][form.data('id_field')];
          
          if (id) {
               url.push(id);
               method = method == 'post' ? 'put' : method;
          }
     }
     
     // possible sub-entity
     if (entities.length > 1) {
          url.push(entities[1]);
     }
     
     // submit and transform returned data
     api[method](url, data, d, {});
     
     // when deleting, remove form/s
     if ('delete' == method) {
          let selector = "form[data-use_form='" + form.data('use_form') + "']";
          $(document).find(selector).each(function(i, f) {
               $(f).html('');
          });
     }
}
//}}}

// run when page loaded and ready
$(document).ready(function() { //{{{
     // disable default behavious for clicking API stuff
     $(document).on('click', 'a.api', function(e) {
          e.preventDefault();
     });
     // submit form (POST/PUT)
     $(document).on('click', 'form.api button.submit', function(e) {
          submitForm('post', $(e.target).closest('form'));
     });
     // submit form (DELETE)
     $(document).on('click', 'form.api button.delete', function(e) {
          submitForm('delete', $(e.target).closest('form'));
     });
     
     // event handlers
     for (let i = 0, l = events.length; i < l; ++ i) {
          $(document).on(events[i][1], events[i][0], events[i][2]);
     }

     // fetch data
     for (i = 0, l = fetch.length; i < l; ++ i) {
          let f = fetch[i];
          api.get(f.url, {}, f.id, {}, f.useData);
     }
});
//}}}
