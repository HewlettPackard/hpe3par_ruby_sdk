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

describe Hpe3parSdk::HostManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end

  it 'validate get all hosts' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/hosts.json')
    all_hosts = JSON.parse(file)
    output = nil, all_hosts
    allow(http).to receive(:get).with('/hosts').and_return(output)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(class_object_to_hash(client.get_hosts)).to eq(class_object_to_hash(all_hosts['members']))
  end

  it 'validate get single host by name' do
    host_name = 'sample-host'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/host.json')
    single_host_response_body = JSON.parse(file)
    output = nil, single_host_response_body
    allow(http).to receive(:get).with('/hosts/' + host_name).and_return(output)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.get_host(host_name).name).to eq(Hpe3parSdk::Host.new(single_host_response_body).name)
    expect(class_object_to_hash(client.get_host(host_name).fcpaths)).to eq(class_object_to_hash(Hpe3parSdk::Host.new(single_host_response_body).fcpaths))
  end

  it 'validate create host with optional parameters' do
    host_name = 'sample-host'
    iscsi_names = ['dummy-iqn']
    fcwwns = ['1234D123E123A']
    optional = { 'persona' => 2 }
    response = nil
    body = nil
    host_creation_body = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).with('/hosts', body: { 'name' => host_name, 'persona' => 2, 'FCWWNs' => fcwwns, 'iSCSINames' => iscsi_names }).and_return(host_creation_body)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.create_host(host_name, iscsi_names, fcwwns, optional)).to eq(body)
  end

  it 'validate create host with only minimum mandatory parameter' do
    host_name = 'sample-host'
    response = nil
    body = nil
    host_creation_body = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).with('/hosts', body: { 'name' => host_name }).and_return(host_creation_body)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.create_host(host_name, nil, nil, nil)).to eq(body)
  end

  it 'validate modify host' do
    host_name = 'sample-host'
    mod_request = { 'persona' => 2 }
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [nil, nil]
    allow(http).to receive(:put).with("/hosts/#{host_name}", body: mod_request).and_return(expected_response)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.modify_host(host_name, mod_request)).to eq(expected_response[1])
  end

  it 'validate delete host' do
    host_name = 'sample-host'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [nil, nil]
    allow(http).to receive(:delete).with("/hosts/#{host_name}").and_return(expected_response)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.delete_host(host_name)).to eq(expected_response[1])
  end

  it 'validate get host by name which is empty or has just a space' do
    host_name = ' '
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    client = Hpe3parSdk::HostManager.new(http)
    expect { client.get_host(host_name) }.to raise_error(Hpe3parSdk::HPE3PARException)
  end

  it 'validate get host by name which is nil' do
    host_name = nil
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    client = Hpe3parSdk::HostManager.new(http)
    expect { client.get_host(host_name) }.to raise_error(Hpe3parSdk::HPE3PARException)
  end

  it 'validate querying a host from FC WWN host' do
    wwn = '1000D89D676F3859'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/query_host.json')
    query_host_body = JSON.parse(file)
    query_host_response = { 'date' => ['Fri, 21 Jul 2017 05:47:02 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'], 'content-type' => ['application/json'], 'connection' => ['close'] }
    query_host_output = query_host_response, query_host_body
    query_host = '/hosts?query="FCPaths[wwn==1000D89D676F3859]"'
    allow(http).to receive(:get).with(query_host).and_return(query_host_output)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.query_host_by_fc_path(wwn).name).to eq(Hpe3parSdk::Host.new(query_host_body['members'][0]).name)
  end

  it 'validate querying a host from FC WWN host where no host is found with specified fc wwn' do
    wwn = '1000D89D676F3859'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    query_host_body = { 'total' => 0, 'members' => [] }
    query_host_response = { 'date' => ['Fri, 21 Jul 2017 05:47:02 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'], 'content-type' => ['application/json'], 'connection' => ['close'] }
    query_host_output = query_host_response, query_host_body
    query_host = '/hosts?query="FCPaths[wwn==1000D89D676F3859]"'
    allow(http).to receive(:get).with(query_host).and_return(query_host_output)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.query_host_by_fc_path(wwn)).to eq(nil)
  end

  it 'validate querying a host from an iSCSI initiator host' do
    iqn = 'iqn.1998-01.com.vmware:host183-6813c8e3'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/query_host.json')
    query_host_body = JSON.parse(file)
    query_host_response = { 'date' => ['Fri, 21 Jul 2017 05:47:02 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'], 'content-type' => ['application/json'], 'connection' => ['close'] }
    query_host_output = query_host_response, query_host_body
    query_host = '/hosts?query="iSCSIPaths[name==iqn.1998-01.com.vmware:host183-6813c8e3]"'
    allow(http).to receive(:get).with(query_host).and_return(query_host_output)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.query_host_by_iscsi_path(iqn).name).to eq(Hpe3parSdk::Host.new(query_host_body['members'][0]).name)
  end

  it 'validate querying a host from an iSCSI initiator host where no host is found with specified iqn' do
    iqn = 'iqn.1998-01.com.vmware:host183-6813c8e3'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    query_host_body = { 'total' => 0, 'members' => [] }
    query_host_response = { 'date' => ['Fri, 21 Jul 2017 05:47:02 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'], 'content-type' => ['application/json'], 'connection' => ['close'] }
    query_host_output = query_host_response, query_host_body
    query_host = '/hosts?query="iSCSIPaths[name==iqn.1998-01.com.vmware:host183-6813c8e3]"'
    allow(http).to receive(:get).with(query_host).and_return(query_host_output)
    client = Hpe3parSdk::HostManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.query_host_by_iscsi_path(iqn)).to eq(nil)
  end

  it 'validate get all of the VLUNs on a specific host when vlun_query_supported is set to true' do
    host_name = 'sneha-host'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    query = '/vluns?query="hostname EQ sneha-host"'
    file = File.read('spec/json/host_vlun.json')
    body = JSON.parse(file)
    response_output = nil, body
    allow(http).to receive(:get).with(query).and_return(response_output)
    host_obj = Hpe3parSdk::HostManager.new(http, true)
    host_obj.instance_variable_set('@http', http)
    file = File.read('spec/json/host.json')
    get_host_output = JSON.parse(file)
    allow(host_obj).to receive(:get_host).and_return(get_host_output)
    expect(host_obj.get_host_vluns(host_name))
  end

  it 'validate get all of the VLUNs on a specific host when vlun_query_supported is set to false' do
    host_name = 'SAP_ESX202'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    query = '/vluns'
    file = File.read('spec/json/host_vlun.json')
    body = JSON.parse(file)
    response_output = nil, body
    allow(http).to receive(:get).with(query).and_return(response_output)
    host_obj = Hpe3parSdk::HostManager.new(http)
    host_obj.instance_variable_set('@http', http)
    vlun_obj = Hpe3parSdk::VlunManager.new(http)
    vlun_obj.instance_variable_set('@http', http)
    file = File.read('spec/json/host.json')
    get_host_output = JSON.parse(file)
    allow(host_obj).to receive(:get_host).and_return(get_host_output)
    get_vluns_file = File.read('spec/json/vlun.json')
    get_vluns_output = JSON.parse(get_vluns_file)
    allow(vlun_obj).to receive(:get_vluns).and_return(get_vluns_output)
    expect(host_obj.get_host_vluns(host_name))
  end

  it 'validate get all of the VLUNs on a specific host but no vlun is attached to host' do
    host_name = 'sneha-host'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    query = '/vluns?query="hostname EQ sneha-host"'
    file = File.read('spec/json/host_vlun.json')
    body = JSON.parse(file)
    body['members'] = []
    response_output = nil, body
    allow(http).to receive(:get).with(query).and_return(response_output)
    host_obj = Hpe3parSdk::HostManager.new(http, true)
    host_obj.instance_variable_set('@http', http)
    file = File.read('spec/json/host.json')
    get_host_output = JSON.parse(file)
    allow(host_obj).to receive(:get_host).and_return(get_host_output)
    expect(host_obj.get_host_vluns(host_name)).to eq([])
  end
end
