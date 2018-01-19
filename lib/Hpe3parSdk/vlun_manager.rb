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

module Hpe3parSdk
  class VlunManager
    def initialize(http, vlun_query_supported = false)
      @http = http
      @vlun_query_supported = vlun_query_supported
    end

    def create_vlun(volume_name, host_name, lun, port_pos, no_vcn, override_lower_priority, auto)
      info = {}
      info['volumeName'] = volume_name
      info['lun'] = lun unless lun.nil?
      info['hostname'] = host_name if host_name
      info['portPos'] = port_pos if port_pos
      info['noVcn'] = no_vcn if no_vcn
      if override_lower_priority
        info['overrideLowerPriority'] = override_lower_priority
      end
      if auto
        info['autoLun'] = true
        info['maxAutoLun'] = 0
        info['lun'] = 0
      end
      response = @http.post('/vluns', body: info)
      if response[0]
        location = response[0]['location'].gsub!('/api/v1/vluns/', '')
        return location
      else
        return nil
      end
    end
    
    def vlun_exists?(volume_name, lunid, hostname, port)
       begin 
         vlun_id = ''
         if volume_name
           vlun_id = volume_name
         end
         if lunid
           vlun_id = vlun_id + ",#{lunid}"
         end
         if hostname
           vlun_id = vlun_id + ',' + hostname
         end
         if port
           if hostname.nil?
             vlun_id = vlun_id + ","
           end
           vlun_id = vlun_id + ',' + "#{port[:node].to_s}:#{port[:slot].to_s}:#{port[:cardPort].to_s}"
         end      
         if (volume_name.nil? or volume_name.empty?) or lunid.nil? and (hostname.nil? or port.nil?)
           raise HPE3PARException.new(nil, "Some or all parameters are missing : volume_name, lunid, hostname or port")
         end
        
         @http.get("/vluns/#{vlun_id}")
         return true
       rescue Hpe3parSdk::HTTPNotFound => ex
        return false
        end
     end
     
    def delete_vlun(volume_name, lun_id, host_name, port)
      vlun = "#{volume_name},#{lun_id}"
      vlun += ",#{host_name}" if host_name
      if port
        vlun += "," if host_name.nil?
        vlun += ",#{port[:node]}:#{port[:slot]}:#{port[:cardPort]}"
      end
      response, body = @http.delete("/vluns/#{vlun}")
    end

    def get_vluns
      response = @http.get('/vluns')
      vluns_list=[]
      response[1]['members'].each do |vlun_member|
        vluns_list.push(VLUN.new(vlun_member))
       end
      vluns_list
    end

    def get_vlun(volume_name)
      # This condition if true is untested
      if volume_name.nil? || volume_name.strip.empty?
        raise HPE3PARException.new(nil, "Invalid volume name #{volume_name}")
      end
      if @vlun_query_supported
        query = %("volumeName EQ #{volume_name}")
        response, body = @http.get("/vluns?query=#{query}")
        # Return the first VLUN found for the volume.
        if body.key?('members') && !body['members'].empty?
          return VLUN.new(body['members'][0])
        else
          raise HTTPNotFound.new(nil, "No VLUNs for volumeName #{volume_name} found", nil, 404)
        end
      else
        vluns = get_vluns
        if vluns
          vluns.each do |vlun|
            return vlun if vlun.volume_name == volume_name
          end
        end
        raise HTTPNotFound.new(nil, 'Vlun doesnt exist', nil, 404)
      end
    end
  end
end
