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
require_relative 'exceptions'
require_relative 'models'

module Hpe3parSdk
  # Host Manager Rest API methods
  class HostManager
    def initialize(http, vlun_query_supported = false)
      @http = http
      @vlun_query_supported = vlun_query_supported
      @host_uri = '/hosts'
    end

    def get_hosts
      response = @http.get(@host_uri)
      host_members = []
      response[1]['members'].each do |host_member|
        host_members.push(Host.new(host_member)) if host_member.key?('name')
      end
      host_members
    end

    def get_host(name)
      if name.nil? || name.strip.empty?
        raise HPE3PARException.new(nil, 'Host name cannot be nil or empty')
      else
        response = @http.get("#{@host_uri}/#{name}")
        Host.new(response[1])
      end
    end

    def create_host(name, iscsi_names, fcwwns, optional)
      info = { 'name' => name }

      if !iscsi_names.nil? && !iscsi_names.empty?
        iscsi = { 'iSCSINames' => iscsi_names }
        info = Util.merge_hash(info, iscsi)
      end

      if !fcwwns.nil? && !fcwwns.empty?
        fc = { 'FCWWNs' => fcwwns }
        info = Util.merge_hash(info, fc)
      end

      if !optional.nil? && !optional.empty?
        info = Util.merge_hash(info, optional)
      end

      response = @http.post(@host_uri, body: info)
      response[1]
    end

    def modify_host(name, mod_request)
      response = @http.put("#{@host_uri}/#{name}", body: mod_request)
      response[1]
    end

    def delete_host(name)
      response = @http.delete("#{@host_uri}/#{name}")
      response[1]
    end

    def query_host_by_fc_path(wwn)
      wwn_query = ''
      if wwn
        tmp_query = []
        tmp_query.push("wwn==#{wwn}")
        wwn_query = "FCPaths[#{tmp_query.join(' OR ')}]"
      end

      query = ''
      query = wwn_query if !wwn_query.nil? && !wwn_query.empty?

      query = %("#{query}")

      response = @http.get("#{@host_uri}?query=#{query}")
      if response[1] && response[1].include?('total') && response[1]['total'] > 0
        return Host.new(response[1]['members'][0])
      else
        return nil
      end
    end

    def query_host_by_iscsi_path(iqn)
      iqn_query = ''
      if iqn
        tmp_query = []
        tmp_query.push("name==#{iqn}")
        iqn_query = "iSCSIPaths[#{tmp_query.join(' OR ')}]"
      end

      query = ''
      query = iqn_query if !iqn_query.nil? && !iqn_query.empty?

      query = %("#{query}")

      response = @http.get("#{@host_uri}?query=#{query}")
      if response[1] && response[1].include?('total') && response[1]['total'] > 0
        return Host.new(response[1]['members'][0])
      else
        return nil
      end
    end

    def get_host_vluns(host_name)
      # calling getHost to see if the host exists and raise not found
      # exception if it's not found.
      get_host(host_name)

      vluns = []
      # Check if the WSAPI supports VLUN querying. If it is supported
      # request only the VLUNs that are associated with the host.
      if @vlun_query_supported
        query = %("hostname EQ #{host_name}")
        response = @http.get("/vluns?query=#{query}")
        response[1]['members'].each do |vlun|
          vluns.push(VLUN.new(vlun))
        end
      else
        all_vluns = VlunManager.new(@http).get_vluns

        if all_vluns
          all_vluns.each do |vlun|
            vluns.push(vlun) if !vlun.hostname.nil? && (vlun.hostname == host_name)
          end
        end
      end
      vluns
    end

    def host_exists?(host_name)
      begin
        get_host(host_name)
        return true
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false
      end
    end

  end
end
