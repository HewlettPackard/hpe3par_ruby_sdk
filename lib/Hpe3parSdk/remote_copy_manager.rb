require_relative 'util'
require_relative 'constants'
require_relative 'exceptions'
require_relative 'ssh'
require_relative 'models'

module Hpe3parSdk
  class RemoteCopyManager
    def initialize(http, ssh)
      @http = http
      @ssh = ssh
    end

    def get_remote_copy_info()
      response, body = @http.get('/remotecopy')
      body
    end
	
    def get_remote_copy_groups()
      response, body = @http.get('/remotecopygroups', body: info)
      body
    end

    def get_remote_copy_group(name)
      response, body = @http.get('/remotecopygroups/#{name}')
      body
    end	
	
    def create_remote_copy_group(name, targets, optional = nil)
      info = { 'name' => name, 
               'targets' => targets 
             }
      info = Util.merge_hash(info, optional) if optional
      response, body = @http.post('/remotecopygroups', body: info)
      body
    end
	
    def remove_remote_copy_group(name, keep_snap = false)
      if keep_snap
          snap_query = true
      else
          snap_query = false 
      end
      response, body = @http.delete('/remotecopygroups/#{name}?keepSnap=#{snap_query}')
      body
    end
	
    def modify_remote_copy_group(name, optional = nil)
      info = {}
      info = Util.merge_hash(info, optional) if optional
      response, body = @http.put('/remotecopygroups/#{name}', body: info)
      body
    end	

    def add_volume_to_remote_copy_group(name, volumeName, targets, optional = nil, useHttpPost = false)
      if not useHttpPost
        info = { 'action' => 1, 
                 'volumeName' => volumeName,
                 'targets' => targets			   
               }
  
        info = Util.merge_hash(info, optional) if optional

        response, body = @http.put('/remotecopygroups/#{name}/volumes', body: info)
      else
        info = { 'volumeName' => volumeName,
                 'targets' => targets			   
               }
  
        info = Util.merge_hash(info, optional) if optional

        response, body = @http.post('/remotecopygroups/#{name}/volumes', body: info)
      body
    end	
	
    def remove_volume_from_remote_copy_group(name, volumeName, optional = nil, removeFromTarget = false, useHttpDelete = false)
      if not useHttpDelete
	    if removeFromTarget
	      if optional
		    keep_snap = optional.fetch('keepSnap', false)
		  else
		    keep_snap = false
		  end

	      if keep_snap
		    cmd = ['dismissrcopyvv', '-f', '-keepsnap', '-removevv', volumeName, name]
		    command = cmd.join(" ")
		  else
		    cmd = ['dismissrcopyvv', '-f', '-removevv', volumeName, name]
		    command = cmd.join(" ")
		  end
          @ssh.run(command)		   		
	    else
	      info = { 'action' => 2, 'volumeName': volumeName }
	      info = Util.merge_hash(info, optional) if optional
          @http.put('/remotecopygroups/#{name}', body: info)
	    end
      else
        #Need to add else part
          
    end	
	
    def start_remote_copy_group(name, optional = nil)
      info = { 'action' => 3 }
      info = Util.merge_hash(info, optional) if optional
      response, body = @http.put('/remotecopygroups/#{name}', body: info)
      body
    end	
	
    def stop_remote_copy_group(name, optional = nil)
      info = { 'action' => 4 }
      info = Util.merge_hash(info, optional) if optional
      response, body = @http.put('/remotecopygroups/#{name}', body: info)
      body
    end	

    def synchronize_remote_copy_group(name, optional = nil)
      info = { 'action' => 5 }
      info = Util.merge_hash(info, optional) if optional
      volumes_url = '/remotecopygroups/#{name}'
      @http.put(volumes_url, body: info)
    end	
	
    def recover_remote_copy_group(name, action, optional = nil)
      info = { 'action' => action }
      info = Util.merge_hash(info, optional) if optional
      volumes_url = '/remotecopygroups/#{name}'
      response, body = @http.put(volumes_url, body: info)
      body
    end

