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

require 'rspec'
require 'json'
require 'spec_helper'

describe Hpe3parSdk::PortManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end

  it 'validate get all ports member data' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_ports.length).to eq(all_ports_members['members'].length)
  end

  it 'validate get all fc ports member data without state' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    file = File.read('spec/json/fc_ports.json')
    fc_ports_members = JSON.parse(file)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_fc_ports(nil)[0].protocol).to eq(fc_ports_members[0]['protocol'])
  end

  it 'validate get all fc ports member data with state 4 i.e. READY' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    file = File.read('spec/json/fc_ports_state.json')
    fc_ports_members = JSON.parse(file)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_fc_ports(4)[0].linkState).to eq(fc_ports_members[0]['linkState'])
  end

  it 'validate get all fc ports member data with state 1 which is not present' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_fc_ports(1)).to eq([])
  end

  it 'validate get all iscsi ports member data without state' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    file = File.read('spec/json/iscsi_ports.json')
    iscsi_ports_members = JSON.parse(file)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_iscsi_ports(nil)[0].protocol).to eq(iscsi_ports_members[0]['protocol'])
  end

  it 'validate get all iscsi ports member data with state 4 i.e. READY' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    file = File.read('spec/json/iscsi_ports.json')
    iscsi_ports_members = JSON.parse(file)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_iscsi_ports(4)[0].linkState).to eq(iscsi_ports_members[0]['linkState'])
  end

  it 'validate get all iscsi ports member data with state 1 which is not present' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_iscsi_ports(1)).to eq([])
  end

  it 'validate get all ip ports member data without state' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    file = File.read('spec/json/ip_ports.json')
    ip_ports_members = JSON.parse(file)
    allow(http).to receive(:get).with('/ports').and_return(output)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_ip_ports(nil)[0].protocol).to eq(ip_ports_members[0]['protocol'])
  end

  it 'validate get all ip ports member data with state 4 i.e. READY' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    file = File.read('spec/json/ip_ports.json')
    ip_ports_members = JSON.parse(file)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_ip_ports(4)[0].linkState).to eq(ip_ports_members[0]['linkState'])
  end

  it 'validate get all ip ports member data with state 1 which is not present' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/ports.json')
    all_ports_members = JSON.parse(file)
    output = nil, all_ports_members
    allow(http).to receive(:get).with('/ports').and_return(output)
    client = Hpe3parSdk::PortManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_ip_ports(1)).to eq([])
  end
end
