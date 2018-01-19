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
  class QOSManager
    def initialize(http)
      @http = http
    end

    def query_qos_rules
      response = @http.get('/qos')
      qos_members = []
      response[1]['members'].each do |qos_member|
        qos_members.push(QoSRule.new(qos_member))
        end
      qos_members
    end

    def query_qos_rule(target_name, target_type)
      response = @http.get("/qos/#{target_type}:#{target_name}")
      QoSRule.new(response[1])
    end

   def qos_rule_exists?(target_name, target_type)
      begin
         query_qos_rule(target_name, target_type)
         return true
       rescue Hpe3parSdk::HTTPNotFound => ex
         return false
       end
     end

    def create_qos_rules(target_name, qos_rules, target_type)
      info = { 'name' => target_name,
               'type' => target_type }

      info = Util.merge_hash(info, qos_rules)

      response = @http.post('/qos', body: info)
      response[1]
    end

    def modify_qos_rules(target_name, qos_rules, target_type)
      response = @http.put("/qos/#{target_type}:#{target_name}", body: qos_rules)
      response
    end

    def delete_qos_rules(target_name, target_type)
      response = @http.delete("/qos/#{target_type}:#{target_name}")
      response[1]
    end
  end
end
