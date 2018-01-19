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

describe Hpe3parSdk::VlunManager do
  before(:all) do
    @volume_name = 'test_volume'
    @host_name = 'test_host'
    @vlun_id = 1
    @vluns = {}
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end

  it 'should get all VLUNs' do
    response = nil
    file = File.read('spec/json/vlun.json')
    body = JSON.parse(file)
    get_all_vluns_response = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).with('/vluns').and_return(get_all_vluns_response)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    vlun_obj.instance_variable_set('@http', http)
    expect(class_object_to_hash(vlun_obj.get_vluns)).to eq(class_object_to_hash(body['members']))
  end
  it 'should get first VLUN from the list of vluns for given volume' do
    response = nil
    file = File.read('spec/json/vlun.json')
    body = JSON.parse(file)
    get_all_vluns_response = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).and_return(get_all_vluns_response)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, true)
    vlun_obj.instance_variable_set('@http', http)
    expect(vlun_obj.get_vlun(@volume_name).hostname).to eq(body['members'][0]['hostname'])
  end
  it 'should get first VLUN from the list of vluns for given volume with vlun query supported as false' do
    response = nil
    file = File.read('spec/json/vlun.json')
    body = JSON.parse(file)
    get_all_vluns_response = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).and_return(get_all_vluns_response)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    vlun_obj.instance_variable_set('@http', http)
    expect(vlun_obj.get_vlun(@volume_name).hostname).to eq(body['members'][0]['hostname'])
  end

  it 'should get raise exception if VLUN does not exist for given volume' do
    response = nil
    file = File.read('spec/json/vlun.json')
    body = JSON.parse(file)
    get_all_vluns_response = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).and_return(get_all_vluns_response)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    allow(vlun_obj).to receive(:get_vluns).and_return(nil)
    vlun_obj.instance_variable_set('@http', http)
    expect { vlun_obj.get_vlun(@volume_name) }.to raise_error('Vlun doesnt exist')
  end

  it 'should get raise exception if VLUN body does not have members or lenth of the members is zero' do
    response = nil
    body = { 'members' => [] }
    get_all_vluns_response = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).and_return(get_all_vluns_response)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, true)
    vlun_obj.instance_variable_set('@http', http)
    expect { vlun_obj.get_vlun(@volume_name) }.to raise_error("No VLUNs for volumeName #{@volume_name} found")
  end

  it 'should get raise exception if VLUN does not exist for given volume' do
    response = nil
    file = File.read('spec/json/vlun.json')
    body = JSON.parse(file)
    get_all_vluns_response = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).and_return(get_all_vluns_response)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    allow(vlun_obj).to receive(:get_vluns).and_return(nil)
    vlun_obj.instance_variable_set('@http', http)
    expect { vlun_obj.get_vlun(@volume_name) }.to raise_error('Vlun doesnt exist')
  end

  it 'should raise an exception with volume name as nil' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    vlun_obj.instance_variable_set('@http', http)
    expect { vlun_obj.get_vlun(nil) }.to raise_error('Invalid volume name ')
  end

  it 'should raise an exception with empty volume name' do
    volume_name = ' '
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    vlun_obj.instance_variable_set('@http', http)
    expect { vlun_obj.get_vlun(volume_name) }.to raise_error("Invalid volume name #{volume_name}")
  end
  it 'should create VLUN with valid inputs' do
    headers = { 'location' => '/api/v1/vluns/test_volume,1,test_host' }
    response = [headers, nil]
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).and_return(response)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, true)
    vlun_obj.instance_variable_set('@http', http)
    expect(vlun_obj.create_vlun(@volume_name, @host_name, @vlun_id, nil, nil, nil, nil)).to eq('test_volume,1,test_host')
  end
  it 'should create VLUN with valid inputs' do
    headers = { 'location' => '/api/v1/vluns/test_volume,1,test_host' }
    port_pos = { 'node' => 2, 'slot' => 4, 'port' => 4 }
    no_vcn = true
    override_lower_priority = true
    response = [headers, nil]
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).and_return(response)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    vlun_obj.instance_variable_set('@http', http)
    expect(vlun_obj.create_vlun(@volume_name, @host_name, @vlun_id, port_pos, no_vcn, override_lower_priority, true)).to eq('test_volume,1,test_host')
  end
  it 'should delete VLUN with required inputs' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:delete).and_return(nil)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    vlun_obj.instance_variable_set('@http', http)
    expect(vlun_obj.delete_vlun(@volume_name, @vlun_id, nil, nil)).to eq(nil)
  end
  
  it 'should delete VLUN with all valid inputs and host as nil' do
    port = { 'node' => 2, 'slot' => 2, 'port' => 1 }
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:delete).and_return(nil)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    vlun_obj.instance_variable_set('@http', http)
    expect(vlun_obj.delete_vlun(@volume_name, @vlun_id, nil, port)).to eq(nil)
  end 

  it 'should delete VLUN with all valid inputs' do
    port = { 'node' => 2, 'slot' => 2, 'port' => 1 }
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:delete).and_return(nil)
    vlun_obj = Hpe3parSdk::VlunManager.new(http, false)
    vlun_obj.instance_variable_set('@http', http)
    expect(vlun_obj.delete_vlun(@volume_name, @vlun_id, @host_name, port)).to eq(nil)
  end
end
