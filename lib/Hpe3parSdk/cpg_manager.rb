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

module Hpe3parSdk
  class CPGManager
    def initialize(http)
      @http = http
    end

    def get_cpgs
      cpg_list=[]
      cpg_members = @http.get('/cpgs')[1]['members']
      cpg_members.each do |cpgmember|
        cpg_list.push(CPG.new(cpgmember))
      end
      cpg_list
    end

    def get_cpg(name)
      if name.nil? || name.strip.empty?
        raise 'CPG name cannot be nil or empty'
      else
        CPG.new(@http.get("/cpgs/#{name}")[1])
      end
    end

    def create_cpg(name, optional = nil)
      info = { 'name' => name }

      info = Util.merge_hash(info, optional) if optional
      cpgs_url = '/cpgs'
      response = @http.post(cpgs_url, body: info)
      response[1]
    end

    def modify_cpg(name, cpg_mods)
      @http.put("/cpgs/#{name}", body: cpg_mods)[1]
    end

    def get_cpg_available_space(name)
      info = { 'cpg' => name }

      response = @http.post('/spacereporter', body: info)
      LDLayoutCapacity.new(response[1])
    end

    def delete_cpg(name)
      response = @http.delete("/cpgs/#{name}")
      response[1]
    end

    def cpg_exists?(name)
      begin
        get_cpg(name)
        return true
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false
      end
    end  

  end
end
