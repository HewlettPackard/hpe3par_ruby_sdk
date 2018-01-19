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

describe Hpe3parSdk::CPGManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end

  it 'validate get all CPGs' do
  http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
  file = File.read('spec/json/cpgs.json')
  data_hash = nil, JSON.parse(file)
  cpgs_url = '/cpgs'
  allow(http).to receive(:get).with(cpgs_url).and_return(data_hash)
  ci = Hpe3parSdk::CPGManager.new(http)
  ci.instance_variable_set('@http',http)
  expect(ci.get_cpgs.length).to eq(data_hash[1]['members'].length)
  expect(ci.get_cpgs[0].total_space_MiB).to eq(data_hash[1]['members'][0]['totalSpaceMiB'])
end

it 'validate get single CPG' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/cpg.json')
    data_hash = nil, JSON.parse(file)
    cpg_name = 'FC_r1'
    cpg_url = "/cpgs/#{cpg_name}"
    allow(http).to receive(:get).with(cpg_url).and_return(data_hash)
    ci = Hpe3parSdk::CPGManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.get_cpg(cpg_name).total_space_MiB).to eq(data_hash[1]['totalSpaceMiB'])
  end

  it 'validate get nil CPG' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    cpg_name = nil
    cpg_url = "/cpgs/#{cpg_name}"
    ci = Hpe3parSdk::CPGManager.new(http)
    expect { ci.get_cpg(cpg_name) }.to raise_error('CPG name cannot be nil or empty')
  end

  it 'validate get empty CPG' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    cpg_name = '    '
    cpg_url = "/cpgs/#{cpg_name}"
    ci = Hpe3parSdk::CPGManager.new(http)
    expect { ci.get_cpg(cpg_name) }.to raise_error('CPG name cannot be nil or empty')
  end

  it 'validate get cpg available space' do
    cpg_name = 'cpgName'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/cpg_spacereporter.json')
    expected_body = JSON.parse(file)
    output = nil, expected_body
    cpg_spacereporter_url = '/spacereporter'
    info = { 'cpg' => cpg_name }
    allow(http).to receive(:post).with(cpg_spacereporter_url, body: info).and_return(output)
    ci = Hpe3parSdk::CPGManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.get_cpg_available_space(cpg_name).rawfree_in_mib).to eq(expected_body['rawFreeMiB'])
  end

  it 'validate create cpg' do
    cpg_name = 'cpgName'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).and_return([nil, nil])
    ci = Hpe3parSdk::CPGManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.create_cpg(cpg_name, 'LDLayout' => { 'RAIDType' => 1 })).to eq(nil)
  end

  it 'validate delete CPG' do
    cpg_name = 'cpgName'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:delete).and_return([nil, nil])
    ci = Hpe3parSdk::CPGManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.delete_cpg(cpg_name)).to eq(nil)
  end

  it 'validate modify CPG' do
    cpg_name = 'myCPG'
    new_cpg_name = 'myNewCPG'
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    response = nil, nil
    allow(http).to receive(:put).and_return(response)
    ci = Hpe3parSdk::CPGManager.new(http)
    ci.instance_variable_set('@http', http)
    expect(ci.modify_cpg(cpg_name, 'newName' => new_cpg_name)). to eq(response[1])
  end
end
