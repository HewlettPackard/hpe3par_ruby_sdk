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
	
    def get_remote_copy_group_volumes(remoteCopyGroupName)
      response, body = @http.get('/remotecopygroups/#{remoteCopyGroupName}/volumes')
      body
    end
	
    def get_remote_copy_group_volume(remoteCopyGroupName, volumeName)
      response, body = @http.get('/remotecopygroups/#{remoteCopyGroupName}/volumes/#{volumeName}')
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
      end
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
          response, body = @http.put('/remotecopygroups/#{name}', body: info)
        end
      else
        option = nil
        if optional and optional.get('keepSnap') and removeFromTarget
          raise "keepSnap and removeFromTarget cannot be bpoth\
                  true while removing the volume from remote copy group"
        else if optional and optional.get('keepSnap')
          option = 'keepSnap'
        else if removeFromTarget
          option = 'removeSecondaryVolume'
        end
        delete_url = '/remotecopygroups/#{name}/volumes/#{volumeName}'
        if option
          delete_url += '?#{option}=true'
        end
        response, body = @http.delete(delete_url)
      end	
        body
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

    def admit_remote_copy_links( targetName, source_port, target_port_wwn_or_ip)
      source_target_port_pair = source_port + ':' + target_port_wwn_or_ip
      begin
        cmd = ['admitrcopylink', targetName, source_target_port_pair]
        command = cmd.join(" ")
        response = @ssh.run(command)
        if response != []
          raise Hpe3parSdk::HPE3PARException(message: response)
        end
      rescue Hpe3parSdk::HPE3PARException => ex
        raise Hpe3parSdk::HPE3PARException(ex.message)
      end
      response
    end

    def dismiss_remote_copy_links( targetName, source_port, target_port_wwn_or_ip)
      source_target_port_pair = source_port + ':' + target_port_wwn_or_ip
      begin
        cmd = ['dismissrcopylink', targetName, source_target_port_pair]
        command = cmd.join(" ")
        response = @ssh.run(command)
        if response != []
          raise Hpe3parSdk::HPE3PARException(message: response)
        end
      rescue Hpe3parSdk::HPE3PARException => ex
        raise Hpe3parSdk::HPE3PARException(ex.message)
      end
      response
    end

    def start_rcopy()
      begin
        cmd = ['startrcopy']
        response = @ssh.run(cmd)
        if response != []
          raise Hpe3parSdk::HPE3PARException(message: response)
        end
      rescue Hpe3parSdk::HPE3PARException => ex
        raise Hpe3parSdk::HPE3PARException(ex.message)
      end
      response
    end

    def rcopy_service_exists()
      cmd = ['showrcopy']
      response = @ssh.run(cmd)
      rcopyservice_status = false
      if response[2].include?('Started')
        rcopyservice_status = true
      end
      rcopyservice_status
    end

    def get_remote_copy_link(link_name)
      response, body = @http.get('/remotecopylinks/#{link_name}')
      body
    end

    def rcopy_link_exists(targetName, local_port, target_system_peer_port)
      rcopylink_exits = false
      link_name = targetName + '_' + local_port.replace(':', '_')
      begin
        response = get_remote_copy_link(link_name)
        if response and response['address'] == target_system_peer_port
          rcopylink_exits = true
        end
      rescue Hpe3parSdk::HTTPNotFound => ex
        pass
      end
      rcopylink_exits
    end

    def admit_remote_copy_target( targetName, mode, remote_copy_group_name,
                              source_target_volume_pairs_list=[])
      if source_target_volume_pairs_list == []
        cmd = ['admitrcopytarget', targetName, mode, remote_copy_group_name]
      else
        cmd = ['admitrcopytarget', targetName, mode, remote_copy_group_name]
        for volume_pair_tuple in source_target_volume_pairs_list
          source_target_pair = volume_pair_tuple[0] + ':' + volume_pair_tuple[1]
          cmd << source_target_pair
        end
      end
      begin
        command = cmd.join(" ")
        response = @ssh.run(command)
        if response != []
          raise Hpe3parSdk::HPE3PARException(message: response)
        end
      rescue Hpe3parSdk::HPE3PARException => ex
        raise Hpe3parSdk::HPE3PARException(ex.message)
      end
      response
    end

    def dismiss_remote_copy_target( targetName, remote_copy_group_name)
      option = '-f'
      cmd = ['dismissrcopytarget', option, targetName, remote_copy_group_name]
      begin
        command = cmd.join(" ")
        response = @ssh.run(command)
        if response != []
          raise Hpe3parSdk::HPE3PARException(message: response)
        end
      rescue Hpe3parSdk::HPE3PARException => ex
        raise Hpe3parSdk::HPE3PARException(ex.message)
      end
      response
    end

    def target_in_remote_copy_group_exists( target_name, remote_copy_group_name)
      begin
        contents = self.get_remote_copy_group(remote_copy_group_name)
        for item in contents['targets']
          if item['target'] == target_name
            return true           
          end
        end
      rescue Hpe3parSdk::HPE3PARException => ex
      end
      return false
    end

