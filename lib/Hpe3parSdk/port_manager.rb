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

module Hpe3parSdk
  # Port Manager Rest API methods
  class PortManager
    def initialize(http)
      @http = http
      @ports_uri = '/ports'
    end

    def get_ports
      ports_list = []
      response = @http.get(@ports_uri)
      response[1]['members'].each do |port|
          ports_list.push(Port.new(port))
      end
      ports_list
    end

    def get_fc_ports(state)
      get_protocol_ports(PortProtocol::FC, state)
    end

    def get_iscsi_ports(state)
      get_protocol_ports(PortProtocol::ISCSI, state)
    end

    def get_ip_ports(state)
      get_protocol_ports(PortProtocol::IP, state)
    end

    def get_protocol_ports(protocol, state = nil)
      return_ports = []
      ports = get_ports
      if ports
        ports.each do |port|
          if port.protocol == protocol
            if state.nil?
              return_ports.push(port)
            elsif port.linkState == state
              return_ports.push(port)
            end
          end
        end
      end
      return_ports
    end
  end
end
