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
require_relative 'models'

module Hpe3parSdk
  class VolumeSetManager
    def initialize(http, host_and_vv_set_filter_supported = false)
      @http = http
      @vv_set_filter_supported = host_and_vv_set_filter_supported
    end

    def find_all_volume_sets(name)
      vv_sets = []
      if @vv_set_filter_supported
        query = %("setmembers EQ #{name}")
        response = @http.get("/volumesets?query=#{query}")
        volume_sets = response[1]['members']
        volume_sets.each do |volume_set|
          vv_sets.push(VolumeSet.new(volume_set))
        end
      else
        volume_sets = get_volume_sets
        volume_sets.each do |volume_set|
          if !volume_set.setmembers.nil? && !volume_set.setmembers.empty? && volume_set.setmembers.include?(name)
            vv_sets.push(volume_set)
          end
        end
      end
      vv_sets
    end

    def get_volume_sets
      response = @http.get('/volumesets')
      volume_set_members = []
      response[1]['members'].each do |volume_set_member|
        volume_set_members.push(VolumeSet.new(volume_set_member))
      end
      volume_set_members
    end

    def get_volume_set(name)
      if name.nil? || name.strip.empty?
        raise 'Volume set name cannot be nil or empty'
      else
        response = @http.get('/volumesets/' + name)
        VolumeSet.new(response[1])
      end
    end

    def create_volume_set(name, domain = nil, comment = nil, setmembers = nil)
      info = { 'name' => name }

      info['domain'] = domain if domain

      info['comment'] = comment if comment

      if setmembers
        members = { 'setmembers' => setmembers }
        info = Util.merge_hash(info, members)
      end
      @http.post('/volumesets', body: info)
    end

    def delete_volume_set(name)
      @http.delete("/volumesets/#{name}")[1]
    end

    def modify_volume_set(name, action = nil, newName = nil, comment = nil, flash_cache_policy = nil, setmembers = nil)
      info = {}

      info['action'] = action if action

      info['newName'] = newName if newName

      info['comment'] = comment if comment

      info['flashCachePolicy'] = flash_cache_policy if flash_cache_policy

      if setmembers
        members = { 'setmembers' => setmembers }
        info = Util.merge_hash(info, members)
      end

      @http.put("/volumesets/#{name}", body: info)[1]
    end

    # QoS Priority Optimization methods
    def add_volumes_to_volume_set(set_name, setmembers)
      modify_volume_set(set_name, SetCustomAction::MEM_ADD, nil, nil, nil, setmembers)
    end

    def remove_volumes_from_volume_set(set_name, setmembers)
      modify_volume_set(set_name, SetCustomAction::MEM_REMOVE, nil, nil, nil, setmembers)
    end

    def create_snapshot_of_volume_set(name, copy_of_name, optional = nil)
      parameters = { 'name' => name }
      parameters = Util.merge_hash(parameters, optional) if optional

      info = { 'action' => 'createSnapshot', 'parameters' => parameters }

      response = @http.post("/volumesets/#{copy_of_name}", body: info)
      response[1]
    end

    def volume_set_exists?(name)
      begin
        get_volume_set(name)
        return true
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false
      end
    end
  end
end
