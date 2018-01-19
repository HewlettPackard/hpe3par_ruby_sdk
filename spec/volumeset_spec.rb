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

describe Hpe3parSdk::VolumeSetManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end

  it 'validate get all volumesets' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/volumesets.json')
    data_hash = JSON.parse(file)
    response = 'sample_response'
    reponse_and_body = response, data_hash
    volumesets_url = '/volumesets'
    allow(http).to receive(:get).with(volumesets_url)
      .and_return(reponse_and_body)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(class_object_to_hash(ci.get_volume_sets)).to eq(class_object_to_hash(reponse_and_body[1]['members']))
  end

  it 'validate get specific volumeset' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/volumeset.json')
    data_hash = JSON.parse(file)
    response = 'sample_response'
    reponse_and_body = response, data_hash
    volumeset_name = 'C20DUM1'
    volumeset_url = "/volumesets/#{volumeset_name}"
    allow(http).to receive(:get).with(volumeset_url)
      .and_return(reponse_and_body)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(class_object_to_hash(ci.get_volume_set(volumeset_name))).to eq(class_object_to_hash(Hpe3parSdk::VolumeSet.new(data_hash)))
  end

  it 'validate get volume set where volume set name is nil' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    expect { ci.get_volume_set(nil) }
        .to raise_error('Volume set name cannot be nil or empty')
  end

  it 'validate get volume set where volume set name is blank string' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    expect { ci.get_volume_set(' ') }
        .to raise_error('Volume set name cannot be nil or empty')
  end

  it 'validate find all volumesets with vvset filter supported as false' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    file = File.read('spec/json/volumesets.json')
    members = JSON.parse(file)['members']
    vv_sets = []
    members.each do |vv_set|
      vv_sets.push(Hpe3parSdk::VolumeSet.new(vv_set))
    end
    allow(ci).to receive(:get_volume_sets).and_return(vv_sets)
    ci.instance_variable_set('@http', http)
    vvsets = [{"id"=>1459, "name"=>"P_VVSET", "domain"=>"SRADEV", "setmembers"=>["P_VVSET.0", "P_VVSET.1", "P_VVSET.2", "P_VVSET.3", "P_VVSET.4", "gghh.0", "gghh.1"], "qosEnabled"=>false}]
    expect(class_object_to_hash(ci.find_all_volume_sets('P_VVSET.0'))).to eq(class_object_to_hash(members))
  end

  it 'validate find all volumesets with vvset filter supported as true' do
    volume_name = 'P_VVSET.0'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/volumesets.json')
    vv_sets = JSON.parse(file)
    output = nil, vv_sets
    query = %("setmembers EQ #{volume_name}")
    allow(http).to receive(:get).with("/volumesets?query=#{query}").and_return(output)
    ci = Hpe3parSdk::VolumeSetManager.new(http, true)
    ci.instance_variable_set('@http', http)
    expect(class_object_to_hash(ci.find_all_volume_sets(volume_name))).to eq(class_object_to_hash(vv_sets))
  end

  it 'validate create volumeset' do
    volume_set_name = 'myVolSet'
    domain = 'FARHAN'
    comment = 'My comment'
    volumes_list = %w(my_vol1 my_vol2)
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).and_return(nil)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.create_volume_set(volume_set_name, domain,
                                comment, volumes_list)).to eq(nil)
  end

  it 'validate delete volumeset' do
    volume_set_name = 'myVolSet'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    response = nil, nil
    allow(http).to receive(:delete).and_return(response)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.delete_volume_set(volume_set_name)).to eq(response[1])
  end

  it 'validate modify volumeset - rename volume' do
    volume_set_name = 'myVolSet'
    new_volume_set_name = 'myNewVolSet'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:40:31 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'],
                           'pragma' => ['no-cache'], 'location' => ['/api/v1/volumesets/FARH'], 'connection' => ['close'] }, nil]
    allow(http).to receive(:put).and_return(expected_response)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.modify_volume_set(volume_set_name, nil,
                                new_volume_set_name)). to eq(expected_response[1])
  end

  it 'validate modify volumeset - add comment' do
    volume_set_name = 'myVolSet'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:43:54 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                           'location' => ['/api/v1/volumesets/FARH'], 'connection' => ['close'] }, nil]
    allow(http).to receive(:put).and_return(expected_response)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.modify_volume_set(volume_set_name, nil, nil,
                                'my comment')). to eq(expected_response[1])
  end

  it 'validate modify volumeset - add volume' do
    volume_set_name = 'myVolSet'
    volume_name = 'myVol'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:43:54 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                           'location' => ['/api/v1/volumesets/FARH'], 'connection' => ['close'] }, nil]
    allow(http).to receive(:put).and_return(expected_response)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.modify_volume_set(volume_set_name, 1, nil, nil, nil,
                                [volume_name])). to eq(expected_response[1])
  end

  it 'validate modify volumeset - remove volume' do
    volume_set_name = 'myVolSet'
    volume_name = 'myVol'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:43:54 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                           'location' => ['/api/v1/volumesets/FARH'], 'connection' => ['close'] }, nil]
    allow(http).to receive(:put).and_return(expected_response)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.modify_volume_set(volume_set_name, 2, nil, nil, nil,
                                [volume_name])). to eq(expected_response[1])
  end

  it 'validate modify volumeset - enable flash cache' do
    volume_set_name = 'myVolSet'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:43:54 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                           'location' => ['/api/v1/volumesets/FARH'], 'connection' => ['close'] }, nil]
    allow(http).to receive(:put).and_return(expected_response)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.modify_volume_set(volume_set_name, nil, nil, nil, 1)). to eq(expected_response[1])
  end

  it 'validate modify volumeset - disable flash cache' do
    volume_set_name = 'myVolSet'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:43:54 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                           'location' => ['/api/v1/volumesets/FARH'], 'connection' => ['close'] }, nil]
    allow(http).to receive(:put).and_return(expected_response)
    ci = Hpe3parSdk::VolumeSetManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.modify_volume_set(volume_set_name, nil, nil, nil, 2)). to eq(expected_response[1])
  end

  it 'validate addVolumeToVolumeSet' do
    volume_set_name = 'myVolSet'
    setmembers = ['myVol']
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:43:54 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                           'location' => ['/api/v1/volumesets/FARH'], 'connection' => ['close'] }, nil]
    volume_set = Hpe3parSdk::VolumeSetManager.new(Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil))
    allow(volume_set).to receive(:modify_volume_set)
      .and_return(expected_response)
    volume_set.instance_variable_set('@volumeSet', volume_set)
    expect(volume_set.add_volumes_to_volume_set(
             volume_set_name, setmembers
    )). to eq(expected_response)
  end

  it 'validate removeVolumeFromVolumeSet' do
    volume_set_name = 'myVolSet'
    setmembers = ['myVol']
    expected_response = [{ 'date' => ['Thu, 27 Jul 2017 09:43:54 GMT'], 'server' => ['hp3par-wsapi'], 'cache-control' => ['no-cache'], 'pragma' => ['no-cache'],
                           'location' => ['/api/v1/volumesets/FARH'], 'connection' => ['close'] }, nil]
    volume_set = Hpe3parSdk::VolumeSetManager.new(Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil))
    allow(volume_set).to receive(:modify_volume_set).and_return(expected_response)
    volume_set.instance_variable_set('@volumeSet', volume_set)
    expect(volume_set.remove_volumes_from_volume_set(volume_set_name, setmembers)). to eq(expected_response)
  end
end
