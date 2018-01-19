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

describe Hpe3parSdk::HostSetManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end

  it 'validate create hostset' do
    host_set_name = 'sample-host-set1'
    host_set_creation_body = nil, nil
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).with('/hostsets',
                                       body: { 'name' => host_set_name }).and_return(host_set_creation_body)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.create_host_set(host_set_name, nil, nil, nil)).to eq(nil)
  end

  it 'validate create hostset and return host-set-name' do
    host_set_name = 'sample-host-set1'
    response = { 'date' => ['Mon, 31 Jul 2017 05:37:34 GMT'], 'server' => ['hp3par-wsapi'],
                 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                 'location' => '/api/v1/hostsets/sample-host-set1', 'connection' => ['close'] }
    host_set_creation_body = [response, nil]
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).with('/hostsets', body: { 'name' => host_set_name }).and_return(host_set_creation_body)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.create_host_set(host_set_name, nil, nil, nil)).to eq(host_set_name)
  end

  it 'validate create hostset with optional parameters and return host-set-name' do
    host_set_name = 'sample-host-set1'
    domain = 'dummy.com'
    comment = 'This is a dummy comment'
    setmembers = ['sample-host']
    response = { 'date' => ['Mon, 31 Jul 2017 05:37:34 GMT'], 'server' => ['hp3par-wsapi'],
                 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                 'location' => '/api/v1/hostsets/sample-host-set1', 'connection' => ['close'] }
    host_set_creation_body = [response, nil]
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).with('/hostsets',
                                       body: { 'name' => host_set_name, 'domain' => domain, 'comment' => comment, 'setmembers' => setmembers })
      .and_return(host_set_creation_body)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.create_host_set(host_set_name, domain, comment, setmembers)).to eq(host_set_name)
  end

  it 'validate get all hostsets' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/hostsets.json')
    all_host_sets = JSON.parse(file)
    output = nil, all_host_sets
    allow(http).to receive(:get).with('/hostsets').and_return(output)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(class_object_to_hash(client.get_host_sets)).to eq(class_object_to_hash(all_host_sets['members']))
  end

  it 'validate find all hostsets of a host with hostset filter supported as true' do
    host_name = 'sample-host'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/hostsets.json')
    all_host_sets = JSON.parse(file)
    output = nil, all_host_sets
    query = %("setmembers EQ #{host_name}")
    allow(http).to receive(:get).with("/hostsets?query=#{query}").and_return(output)
    client = Hpe3parSdk::HostSetManager.new(http, true)
    client.instance_variable_set('@http', http)
    expect(class_object_to_hash(client.find_host_sets(host_name))).to eq(class_object_to_hash(all_host_sets['members']))
  end

  it 'validate find all hostsets with hostset filter supported as false' do
    host_name = 'sample-host'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    client = Hpe3parSdk::HostSetManager.new(http)
    file = File.read('spec/json/hostsets.json')
    members = JSON.parse(file)['members']
    host_sets = []
    members.each do |host_set|
      host_sets.push(Hpe3parSdk::HostSet.new(host_set))
    end
    allow(client).to receive(:get_host_sets).and_return(host_sets)
    client.instance_variable_set('@http', http)
    expect(class_object_to_hash(client.find_host_sets(host_name))).to eq(class_object_to_hash(members))
  end

  it 'validate get hostset by name which is empty or has just a space' do
    host_set_name = ' '
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    client = Hpe3parSdk::HostSetManager.new(http)
    expect { client.get_host_set(host_set_name) }.to raise_error(Hpe3parSdk::HPE3PARException)
  end

  it 'validate get hostset by name which is nil' do
    host_set_name = nil
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    client = Hpe3parSdk::HostSetManager.new(http)
    expect { client.get_host_set(host_set_name) }.to raise_error(Hpe3parSdk::HPE3PARException)
  end

  it 'validate get hostset by name' do
    host_set_name = 'sample-host-set1'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/hostset.json')
    single_host_set_response_body = JSON.parse(file)
    output = nil, single_host_set_response_body
    allow(http).to receive(:get).with("/hostsets/#{host_set_name}").and_return(output)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(class_object_to_hash(client.get_host_set(host_set_name))).to eq(class_object_to_hash(Hpe3parSdk::HostSet.new(single_host_set_response_body)))
  end

  it 'validate modify hostset' do
    host_set_name = 'sample-host-set1'
    action = nil
    newName = 'sampple-host-set'
    comment = 'This is my new comment for hostset'
    setmembers = nil
    mod_request = { 'comment' => comment, 'newName' => newName }
    expected_response = [nil, nil]
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:put).with("/hostsets/#{host_set_name}", body: mod_request).and_return(expected_response)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.modify_host_set(host_set_name, action, setmembers, newName, comment)).to eq(expected_response[1])
  end

  it 'validate add host to hostset' do
    host_set_name = 'sample-host-set1'
    host_name = ['sample-host']
    mod_request = { 'action' => Hpe3parSdk::SetCustomAction::MEM_ADD,
                    'setmembers' => host_name }
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:40:31 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'],
                           'pragma' => ['no-cache'], 'location' => ['/api/v1/hostsets/sample-host-set1'], 'connection' => ['close'] }, nil]
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:put).with("/hostsets/#{host_set_name}", body: mod_request).and_return(expected_response)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.add_hosts_to_host_set(host_set_name, host_name)).to eq(expected_response[1])
  end

  it 'validate remove host to hostset' do
    host_set_name = 'sample-host-set1'
    host_name = ['sample-host']
    mod_request = { 'action' => Hpe3parSdk::SetCustomAction::MEM_REMOVE, 'setmembers' => host_name }
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [nil, nil]
    allow(http).to receive(:put).with("/hostsets/#{host_set_name}", body: mod_request).and_return(expected_response)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.remove_hosts_from_host_set(host_set_name, host_name)).to eq(expected_response[1])
  end

  it 'validate delete hostset' do
    host_set_name = 'sample-host-set1'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:delete).with("/hostsets/#{host_set_name}").and_return(nil)
    client = Hpe3parSdk::HostSetManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.delete_host_set(host_set_name)).to eq(nil)
  end
end
