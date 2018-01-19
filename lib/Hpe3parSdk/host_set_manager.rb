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
require_relative 'models'

module Hpe3parSdk
  # Host Set Manager Rest API methods
  class HostSetManager
    def initialize(http, host_and_vv_set_filter_supported = false)
      @http = http
      @host_set_uri = '/hostsets'
      @host_set_filter_supported = host_and_vv_set_filter_supported
    end

    def get_host_sets
      response = @http.get(@host_set_uri)
      host_set_members = []
      response[1]['members'].each do |host_set_member|
        host_set_members.push(HostSet.new(host_set_member))
      end
      host_set_members
    end

    def get_host_set(name)
      if name.nil? || name.strip.empty?
        raise HPE3PARException.new(nil, 'HostSet name cannot be nil or empty')
      else
        response = @http.get("#{@host_set_uri}/#{name}")
        HostSet.new(response[1])
      end
    end

    def create_host_set(name, domain, comment, setmembers)
      info = { 'name' => name }

      info['domain'] = domain if domain

      info['comment'] = comment if comment

      if setmembers
        members = { 'setmembers' => setmembers }
        info = Util.merge_hash(info, members)
      end

      response = @http.post(@host_set_uri, body: info)
      if response[0] && response[0].include?('location')
        host_set_id = response[0]['location'].rpartition('/api/v1/hostsets/')[-1]
        return host_set_id
      else
        return nil
      end
    end

    def delete_host_set(name)
      @http.delete("#{@host_set_uri}/#{name}")
    end

    def modify_host_set(name, action, setmembers, newName = nil, comment = nil)
      info = {}

      info['action'] = action if action

      info['newName'] = newName if newName

      info['comment'] = comment if comment

      if setmembers
        members = { 'setmembers' => setmembers }
        info = Util.merge_hash(info, members)
      end

      response = @http.put("#{@host_set_uri}/#{name}", body: info)
      response[1]
    end

    def add_hosts_to_host_set(set_name, setmembers)
      modify_host_set(set_name, SetCustomAction::MEM_ADD, setmembers)
    end

    def remove_hosts_from_host_set(set_name, setmembers)
      modify_host_set(set_name, SetCustomAction::MEM_REMOVE, setmembers)
    end

    def find_host_sets(host_name)
      host_sets = []
      if @host_set_filter_supported
        query = %("setmembers EQ #{host_name}")
        response = @http.get("#{@host_set_uri}?query=#{query}")
        host_sets_list = response[1]['members']
        host_sets_list.each do |host_set|
          host_sets.push(HostSet.new(host_set))
        end
      else
        host_sets_list = get_host_sets
        host_sets_list.each do |host_set|
          if !host_set.setmembers.nil? && !host_set.setmembers.empty? && host_set.setmembers.include?(host_name)
            host_sets.push(host_set)
          end
        end
      end
      host_sets
    end

    def host_set_exists?(host_name)
      begin
        get_host_set(host_name)
        return true
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false
      end
    end

    def host_in_host_set_exists?(set_name, host_name)
    end   

  end
end
