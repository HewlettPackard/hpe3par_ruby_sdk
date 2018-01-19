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

describe Hpe3parSdk::VolumeManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end
  
  app_type = 'ruby-3parclient'
  ssh = nil

  it 'validate get all volumes' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/volumes.json')
    data_hash = JSON.parse(file)
    response = nil, data_hash
    volumes_url = '/volumes'
    allow(http).to receive(:get).with(volumes_url).and_return(response)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.get_volumes(Hpe3parSdk::VolumeCopyType::BASE_VOLUME).length).to eq(response[1]['members'].length)
    expect(ci.get_volumes(Hpe3parSdk::VolumeCopyType::BASE_VOLUME)[0].name).to eq(response[1]['members'][0]['name'])
  end

  it 'validate get all snapshots' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/snapshots.json')
    data_hash = JSON.parse(file)
    response = nil, data_hash
    volumes_url = '/volumes'
    allow(http).to receive(:get).with(volumes_url).and_return(response)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.get_volumes(Hpe3parSdk::VolumeCopyType::VIRTUAL_COPY).length).to eq(data_hash['members'].length)
    expect(ci.get_volumes(Hpe3parSdk::VolumeCopyType::VIRTUAL_COPY)[0].size_mib).to eq(data_hash['members'][0]['sizeMiB'])
  end

  it 'validate get volume' do
    volume_name = 'vvr_2'
    volume_url = "/volumes/#{volume_name}"
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/volume.json')
    data_hash = JSON.parse(file)
    response = nil, data_hash
    allow(http).to receive(:get).with(volume_url).and_return(response)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.get_volume(volume_name).name).to eq(data_hash['name'])
  end

  it 'validate get empty volume' do
    volume_name = '   '
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    expect { ci.get_volume(volume_name) }
      .to raise_error('Volume name cannot be nil or empty')
  end

  it 'validate get nil volume' do
    volume_name = nil
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    expect { ci.get_volume(volume_name) }
      .to raise_error('Volume name cannot be nil or empty')
  end

  it 'validate get volume by wwn' do
    volume_wwn = '60002AC00000000001000C5000001BAB'
    volumes_query_url = "/volumes?query=\"wwn EQ #{volume_wwn}\""
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/volumesByWwn.json')
    data_hash = JSON.parse(file)
    output = nil, data_hash
    allow(http).to receive(:get).with(volumes_query_url).and_return(output)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.get_volume_by_wwn(volume_wwn).name).to eq(data_hash['members'][0]['name'])
  end

  it 'get non existant volume by wwn' do
    volume_wwn = '60002AC00000000001000C5000001BAB'
    volumes_query_url = "/volumes?query=\"wwn EQ #{volume_wwn}\""
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    data_hash = { 'total' => 0, 'members' => [] }
    output = nil, data_hash
    allow(http).to receive(:get).with(volumes_query_url).and_return(output)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect { ci.get_volume_by_wwn(volume_wwn) }
      .to raise_error("Volume with WWN #{volume_wwn} does not exist")
  end

  it 'validate create volume' do
    volume_name = 'myVol'
    cpg_name = 'cpgName'
    size = 1024
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).and_return(nil)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.create_volume(volume_name, cpg_name, size,
                            'comment' => 'my_sample_comment')).to eq(nil)
  end

  it 'validate delete volume - no snapshot' do
    volume_name = 'myVol'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:delete).and_return([nil, nil])
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.delete_volume(volume_name)).to eq(nil)
  end

  it 'validate modify volume' do
    volume_name = 'myVol'
    new_volume_name = 'myNewVol'
    new_comment = 'new_comment'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:put).and_return(nil)
    get_response = '{"total":2,"members":[{"key":"app_type","value":"ruby-3parclient","creationTimeSec":1508916090,"creationTime8601":"2017-10-25T12:51:30+05:30"},{"key":"farhan","value":"gruby","creationTimeSec":1508915764,"creationTime8601":"2017-10-25T12:46:04+05:30"}]}'
    
    allow(http).to receive(:get).and_return(JSON.parse(get_response))
    allow(http).to receive(:post).and_return(nil)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.modify_volume(volume_name, {'newName' => new_volume_name})). to eq(nil)
  end

  it 'validate grow volume' do
    volume_name = 'myVol'
    size_to_increase = 1024
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:put).and_return([nil, nil])
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.grow_volume(volume_name, size_to_increase)). to eq(nil)
  end

  it 'validate copy volume' do
    volume_name = 'myVol'
    new_volume_name = 'myVol2'
    destination_cpg = 'newCPG'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).and_return([nil, nil])
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.create_physical_copy(volume_name, new_volume_name,
                          destination_cpg)). to eq(nil)
  end

  it 'validate copy volume - online' do
    volume_name = 'myVol'
    new_volume_name = 'myVol2'
    destination_cpg = 'newCPG'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).and_return([nil, nil])
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.create_physical_copy(volume_name, new_volume_name,
                          destination_cpg, 'online' => true)). to eq(nil)
  end

  it 'validate tune volume' do
    volume_name = 'myVol'
    tune_operation = 1
    optional = { 'userCPG' => 'myCPG' }
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    sample_body = 'TUNE'
    response = nil, sample_body
    allow(http).to receive(:put).and_return(response)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.tune_volume(volume_name, tune_operation, optional))
      . to eq(sample_body)
  end

  it 'validate get snapshot' do
    volume_name = 'myVol'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/volume_snapshot.json')
    data_hash = JSON.parse(file)
    response = nil, data_hash
    allow(http).to receive(:get).and_return(response)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.get_volume_snapshots(volume_name)[0].id).to eq(response[1]['members'][0]['id'])
    expect(ci.get_volume_snapshots(volume_name).length).to eq(response[1]['members'].length)
  end

  it 'validate create snapshot' do
    volume_name = 'myVol'
    snapshot_name = 'mySnap'
    optional = { 'comment' => 'Sample Comment' }
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    sample_body = 'CREATE'
    response = nil, sample_body
    allow(http).to receive(:post).and_return(response)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.create_snapshot(volume_name, snapshot_name,
                              optional)).to eq(sample_body)
  end

  it 'validate restore snapshot' do
    snapshot_name = 'mySnapshot'
    optional = { 'online' => false, 'priority' => 2 }
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    sample_body = 'RESTORE'
    response = nil, sample_body
    allow(http).to receive(:put).and_return(response)
    ci = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    ci.instance_variable_set('@http', http)
    expect(ci.restore_snapshot(snapshot_name, optional)).to eq(sample_body)
  end

  it 'validate get_online_physical_copy_status' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    volume_name = 'online_physical_copy_volume'
    file = File.read('spec/json/tasks.json')
    all_tasks = JSON.parse(file)['members']
    allow_any_instance_of(Hpe3parSdk::Client).to receive(:get_ws_api_version) { @api_hash }
    volume = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    task = Hpe3parSdk::TaskManager.new(http)
    volume.instance_variable_set('@task', task)
    allow(task).to receive(:get_all_tasks).and_return(all_tasks)
    expect(volume.get_online_physical_copy_status(volume_name)).to eq(Hpe3parSdk::TaskStatus::DONE)
  end

  it 'validate get_online_physical_copy_status - exception' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    volume_name = 'my_volume'
    file = File.read('spec/json/tasks.json')
    all_tasks = JSON.parse(file)['members']
    allow_any_instance_of(Hpe3parSdk::Client).to receive(:get_ws_api_version) { @api_hash }
    volume = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    task = Hpe3parSdk::TaskManager.new(http)
    volume.instance_variable_set('@task', task)
    allow(task).to receive(:get_all_tasks).and_return(all_tasks)
    expect { volume.get_online_physical_copy_status(volume_name) }.to raise_error('Volume not an online physical copy')
  end
  
  it 'validate stop offline physical copy' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    volume_name = 'my_volume'
    stop_physical_copy_resp = nil
    volume = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    allow(volume).to receive(:_sync_physical_copy).and_return(stop_physical_copy_resp)
    expect(volume.stop_offline_physical_copy(volume_name)).to eq(stop_physical_copy_resp)
  end
  
  it 'validate resync physical copy' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    volume_name = 'my_volume'
    resync_physical_copy_resp = nil
    volume = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    allow(volume).to receive(:_sync_physical_copy).and_return(resync_physical_copy_resp)
    expect(volume.resync_physical_copy(volume_name)).to eq(resync_physical_copy_resp)
  end
  
  it 'validate sync physical copy' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    volume_name = 'my_volume'
    expected_response = nil, nil
    allow(http).to receive(:put).and_return(expected_response)
  
    volume = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    volume.instance_variable_set('@http', http)
    expect(volume._sync_physical_copy(volume_name, 1)).to eq(nil)
  end
  
  it 'validate get_volume_snapshot_names' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    volume_name = 'my_volume'
    file = File.read('spec/json/volumes.json')
    volumes_response = nil, JSON.parse(file)
  
    snapshots = ['vvr_2', 'P14db_ESX243']
    allow(http).to receive(:get).and_return(volumes_response)
  
    volume = Hpe3parSdk::VolumeManager.new(http, ssh, app_type)
    volume.instance_variable_set('@http', http)
    expect(volume.get_volume_snapshot_names(volume_name)).to eq(snapshots)
  end
end
