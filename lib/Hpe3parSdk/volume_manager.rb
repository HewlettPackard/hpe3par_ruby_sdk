# (c) Copyright 2016-2017 Hewlett Packard Enterprise Development LP
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

require_relative 'util'
require_relative 'constants'
require_relative 'exceptions'
require_relative 'task_manager'
require_relative 'ssh'
require_relative 'volume_set_manager'
require_relative 'models'

module Hpe3parSdk
  class VolumeManager
    def initialize(http, ssh, app_type)
      @http = http
      @ssh = ssh
      @task = TaskManager.new(http)
      @volume_set = VolumeSetManager.new(http)
      @app_type = app_type
    end

    def get_volumes(volume_type)
      volumes = Array[]
      response = @http.get('/volumes')
      response[1]['members'].each do |member|
        volumes.push(VirtualVolume.new(member)) if member['copyType'] == volume_type
      end
      volumes
    end

    def get_volume(name)
      if name.nil? || name.strip.empty?
        raise 'Volume name cannot be nil or empty'
      else
        VirtualVolume.new(@http.get("/volumes/#{name}")[1])
      end
    end

    def get_volume_by_wwn(wwn)
      response = @http.get("/volumes?query=\"wwn EQ #{wwn}\"")
      if response[1].key?('members') && !response[1]['members'].empty?
        return VirtualVolume.new(response[1]['members'][0])
      else
        raise HTTPNotFound.new(nil, "Volume with WWN #{wwn} does not exist", nil, 404)
      end
    end

    def create_volume(name, cpg_name, size_mib, optional = nil)
      info = { 'name' => name, 
               'cpg' => cpg_name, 
               'sizeMiB' => size_mib, 
               #Adding information related to telemetry
               'objectKeyValues' => [ 
                 { 
                   'key' => 'type' , 
                   'value' => @app_type 
                 } 
               ] 
             }
      
      info = Util.merge_hash(info, optional) if optional
      volumes_url = '/volumes'
      @http.post(volumes_url, body: info)
    end

    def get_volume_snapshot_names(name)
      snapshots = []
      headers, body = @http.get("/volumes?query=\"copyOf EQ #{name}\"")
      for member in body['members']
        snapshots.push(member['name'])
      end
      snapshots
    end

    def get_volume_snapshots(name)
      response = @http.get("/volumes?query=\"copyOf EQ #{name}\"")
      volume_snapshots = []
      response[1]['members'].each do |snapshot|
        volume_snapshots.push(VirtualVolume.new(snapshot))
      end
      volume_snapshots
    end

    def delete_volume(name)
      begin
        remove_volume_metadata(name, 'type')
      rescue; end

      response = @http.delete("/volumes/#{name}")
      response[1]
    end

    def remove_volume_metadata(name, key)
      response = @http.delete(
            "/volumes/#{name}/objectKeyValues/#{key}"
            )
      body
    end

    def modify_volume(name, volume_mods)
      @http.put("/volumes/#{name}", body: volume_mods)
      if volume_mods.key? ('newName') && !volume_mods['newName'].nil?
        name = volume_mods['newName']
      end
      setVolumeMetaData(name, 'type', @app_type)     
    end

    def grow_volume(name, amount)
      info = { 'action' => VolumeCustomAction::GROW_VOLUME, 'sizeMiB' => amount }
      response = @http.put("/volumes/#{name}", body: info)
      response[1]
    end

    def create_physical_copy(src_name, dest_name, dest_cpg, optional = nil)
      parameters = { :destVolume => dest_name, :destCPG => dest_cpg }
      parameters = Util.merge_hash(parameters, optional) if optional

      
      if !parameters.key?(:online) || !((parameters[:online]))
        # 3Par won't allow destCPG to be set if it's not an online copy.
        parameters.delete(:destCPG)
      end
      
      info = { :action => 'createPhysicalCopy', :parameters => parameters }

      response = @http.post("/volumes/#{src_name}", body: info)
      response[1]
    end
    
    def stop_offline_physical_copy(volume_name)
      _sync_physical_copy(volume_name, VolumeCustomAction::STOP_PHYSICAL_COPY)
    end
    
    def is_online_physical_copy(name)
      task = _find_task(name, active=true)
      if task.nil?
        false
      else
        true
      end
    end
    
    def stop_online_physical_copy(name)
      task = _find_task(name, active=false)
      unless task.nil?
        task_id = task[0].split(",")[0]
        unless task_id.nil?
          cmd = ['canceltask', '-f', task_id]
          command = cmd.join(" ")
          result = @ssh.run(command)
          unless result.include? "is not active"        
            ready = false
            while ready == false
              sleep(1)
              task = _find_task(name, false)
              if task.nil?
                ready = true
              end
            end
          end
        end
      end
    end
    
    def _find_task(name, active=false) 
      cmd = ['showtask']
      if active
        cmd.push('-active')
      end
      cmd.push(name)
      command = cmd.join(" ")
      
      result = @ssh.run(command).split("\n")
      if result[0].gsub("\n",'') =='No tasks.'
        return nil
      end
      result
    end
    
    def resync_physical_copy(volume_name)
      _sync_physical_copy(volume_name, VolumeCustomAction::RESYNC_PHYSICAL_COPY)
    end
    
    def _sync_physical_copy(volume_name, action)
      info = { 'action' => action }
      response = @http.put("/volumes/#{volume_name}", body: info)
      response[1]
    end
      
    def get_online_physical_copy_status(name)
      status = nil
      tasks = @task.get_all_tasks
      tasks.each do |task|
        status = task['status'] if task['name'] == name &&
                                   task['type'] == TaskType::ONLINE_COPY
      end
      raise HPE3PARException.new(nil, 'Volume not an online physical copy') if status.nil?
      status
    end

    def tune_volume(name, tune_operation, optional = nil)
      info = { 'action' => VolumeCustomAction::TUNE_VOLUME,
               'tuneOperation' => tune_operation }
      info = Util.merge_hash(info, optional) if optional
      response = @http.put("/volumes/#{name}", body: info)
      response[1]
    end
    
  

    def create_snapshot(name, copy_of_name, optional = nil)
      parameters = { 'name' => name }
      parameters = Util.merge_hash(parameters, optional) if optional
      info = { 'action' => 'createSnapshot',
               'parameters' => parameters }

      response = @http.post("/volumes/#{copy_of_name}", body: info)
      response[1]
    end

    def restore_snapshot(name, optional = nil)
      info = { 'action' => VolumeCustomAction::PROMOTE_VIRTUAL_COPY }
      info = Util.merge_hash(info, optional) if optional

      response = @http.put("/volumes/#{name}", body: info)
      response[1]
    end
    
    def setVolumeMetaData(name, key, value)
      key_exists = false
      info = {
          'key' => key,
          'value' => value
      }
      
      begin
        response = @http.post("/volumes/#{name}/objectKeyValues", body: info)
      rescue  Hpe3parSdk::HTTPConflict => ex
        key_exists = true
      rescue
      end
      
      if key_exists
        info = {
            'value' => value
        }
        begin
          response = @http.put("/volumes/#{name}/objectKeyValues/#{key}", body: info)
        rescue; end
      end
    end
    
    def volume_exists?(name)
      begin
        get_volume(name)
        return true
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false
      end
    end

    def volume_set_exists?(name)
      begin
        get_volume_set(name)
        return true
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false
      end
    end
  
    def online_physical_copy_exists?(src_name, phy_copy_name)
      begin
        if volume_exists?(src_name) and volume_exists?(phy_copy_name) and !_find_task(phy_copy_name,true).nil?
          return true
        else
          return false 
        end
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false
      end
    end

    def offline_physical_copy_exists?(src_name, phy_copy_name)
      begin
        if volume_exists?(src_name) and volume_exists?(phy_copy_name) and !_find_task(src_name + "->" + phy_copy_name,true).nil?
           return true
        else
           return false 
        end
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false
      end
    end
  end
end
